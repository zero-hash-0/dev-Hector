import SwiftUI
import WidgetKit

// MARK: - Dashboard ViewModel
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var todayTasks:       [OpusTask] = [] { didSet { save() } }
    @Published var laterTasks:       [OpusTask] = [] { didSet { save() } }
    @Published var completedHistory: [HistoryEntry] = [] { didSet { saveHistory() } }
    @Published var momentum: Int = 0 { didSet { UserDefaults.standard.set(momentum, forKey: "momentum"); syncShared() } }
    @Published var streak:   Int = 0 { didSet { UserDefaults.standard.set(streak,   forKey: "streak");   syncShared() } }
    @Published var showLater:       Bool         = false
    @Published var showAddTask:     Bool         = false
    @Published var newTaskTitle:    String       = ""
    @Published var newTaskCategory: TaskCategory = .work
    @Published var newTaskSchedule: TaskSchedule = .today
    @Published var hasDueDate:      Bool         = false
    @Published var newTaskDueDate:  Date         = Date()
    @Published var newTaskRepeat:   TaskRepeat   = .none

    private let todayKey   = "todayTasks_v1"
    private let laterKey   = "laterTasks_v1"
    private let historyKey = "completedHistory_v1"
    private let lastDateKey = "lastActiveDate"

    init() {
        load()
        checkDailyReset()
    }

    var completedTasks: [OpusTask] { todayTasks.filter(\.isCompleted) }
    var pendingTasks:   [OpusTask] { todayTasks.filter { !$0.isCompleted } }

    func toggle(_ task: OpusTask) {
        guard let idx = todayTasks.firstIndex(where: { $0.id == task.id }) else { return }
        todayTasks[idx].isCompleted.toggle()
        let pct = Double(completedTasks.count) / Double(max(todayTasks.count, 1))
        momentum = min(100, max(0, Int(Double(streak) * 4 + pct * 25)))
        // Cancel due notification when task is completed
        if todayTasks[idx].isCompleted {
            NotificationManager.shared.cancelDueDateNotification(for: task.id)
        }
        // Fire all-done celebration when last task is completed
        if pendingTasks.isEmpty && !todayTasks.isEmpty {
            Task { await NotificationManager.shared.sendAllDoneNotification() }
        }
        // Keep morning reminder badge count fresh
        Task { await NotificationManager.shared.scheduleDailyMorningReminder(pendingCount: pendingTasks.count) }
    }

    func deleteTask(_ task: OpusTask) {
        NotificationManager.shared.cancelDueDateNotification(for: task.id)
        withAnimation(.spring(response: 0.4)) {
            todayTasks.removeAll { $0.id == task.id }
        }
        Task { await NotificationManager.shared.scheduleDailyMorningReminder(pendingCount: pendingTasks.count) }
    }

    func addTask() {
        guard InputValidator.isValidTaskTitle(newTaskTitle) else { return }
        let title = InputValidator.sanitizeTaskTitle(newTaskTitle)
        let dueDate: Date? = hasDueDate ? newTaskDueDate : nil
        let dueLabel: String? = {
            guard hasDueDate else {
                return newTaskSchedule == .today ? "today" : nil
            }
            let cal = Calendar.current
            if cal.isDateInToday(newTaskDueDate)    { return "today" }
            if cal.isDateInTomorrow(newTaskDueDate) { return "tomorrow" }
            let f = DateFormatter(); f.dateFormat = "MMM d"
            return f.string(from: newTaskDueDate)
        }()
        let task = OpusTask(
            title:      title,
            category:   newTaskCategory,
            schedule:   newTaskSchedule,
            dueDate:    dueDate,
            dueLabel:   dueLabel,
            taskRepeat: newTaskRepeat
        )
        if newTaskSchedule == .today { todayTasks.append(task) }
        else                         { laterTasks.append(task) }
        // Schedule due date notification if applicable
        Task { await NotificationManager.shared.scheduleDueDateNotification(for: task) }
        Task { await NotificationManager.shared.scheduleDailyMorningReminder(pendingCount: pendingTasks.count) }
        newTaskTitle    = ""
        newTaskCategory = .work
        newTaskSchedule = .today
        hasDueDate      = false
        newTaskDueDate  = Date()
        newTaskRepeat   = .none
        showAddTask     = false
    }

    func promoteToToday(_ task: OpusTask) {
        guard let idx = laterTasks.firstIndex(where: { $0.id == task.id }) else { return }
        var promoted = laterTasks[idx]
        promoted.schedule = .today
        promoted.dueLabel = "today"
        laterTasks.remove(at: idx)
        todayTasks.append(promoted)
        Task { await NotificationManager.shared.scheduleDailyMorningReminder(pendingCount: pendingTasks.count) }
    }

    // MARK: - Daily Reset
    private func checkDailyReset() {
        let today     = Calendar.current.startOfDay(for: Date())
        let lastStr   = UserDefaults.standard.string(forKey: lastDateKey) ?? ""
        let fmt       = ISO8601DateFormatter(); fmt.formatOptions = [.withFullDate]
        let todayStr  = fmt.string(from: today)

        if lastStr != todayStr {
            // Separate recurring from one-off completed tasks
            let completedNonRecurring = todayTasks.filter { $0.isCompleted && $0.taskRepeat == .none }
            let completedRecurring    = todayTasks.filter { $0.isCompleted && $0.taskRepeat != .none }

            // Archive only non-recurring completed tasks
            let archiveTasks = completedNonRecurring
            if !archiveTasks.isEmpty {
                let entry = HistoryEntry(date: lastStr.isEmpty ? todayStr : lastStr, tasks: archiveTasks)
                completedHistory.insert(entry, at: 0)
            }

            // Reset recurring tasks to pending for today
            let resetRecurring: [OpusTask] = completedRecurring.map { task in
                var t = task
                t.isCompleted = false
                // For weekly tasks, only carry forward if today is the same weekday
                if task.taskRepeat == .weekly {
                    // Carry forward always — keep it simple for now
                }
                return t
            }

            // Remove all completed non-recurring tasks; keep pending + reset recurring
            todayTasks.removeAll { $0.isCompleted && $0.taskRepeat == .none }
            // Re-insert reset recurring tasks (they were already in todayTasks, just reset)
            for t in resetRecurring {
                if let idx = todayTasks.firstIndex(where: { $0.id == t.id }) {
                    todayTasks[idx] = t
                }
            }

            // Update streak based on non-recurring completed tasks
            let allDoneCount = completedNonRecurring.count + completedRecurring.count
            if allDoneCount > 0 {
                streak += 1
            } else if !lastStr.isEmpty {
                streak = 0   // missed a day
            }
            UserDefaults.standard.set(todayStr, forKey: lastDateKey)
        }
    }

    // MARK: - Persistence
    // Write to BOTH standard and shared suite so the widget can read fresh data
    private static let sharedSuite = "group.com.opus.betaapp"
    private var shared: UserDefaults { UserDefaults(suiteName: Self.sharedSuite) ?? .standard }

    private func save() {
        let enc = JSONEncoder()
        if let d = try? enc.encode(todayTasks) {
            UserDefaults.standard.set(d, forKey: todayKey)
            shared.set(d, forKey: todayKey)           // widget reads this
        }
        if let d = try? enc.encode(laterTasks) {
            UserDefaults.standard.set(d, forKey: laterKey)
        }
        reloadWidget()
    }

    private func saveHistory() {
        let enc = JSONEncoder()
        let trimmed = Array(completedHistory.prefix(90))
        if let d = try? enc.encode(trimmed) { UserDefaults.standard.set(d, forKey: historyKey) }
    }

    private func load() {
        let dec = JSONDecoder()
        if let d = UserDefaults.standard.data(forKey: todayKey),
           let t = try? dec.decode([OpusTask].self, from: d) { todayTasks = t }
        if let d = UserDefaults.standard.data(forKey: laterKey),
           let t = try? dec.decode([OpusTask].self, from: d) { laterTasks = t }
        if let d = UserDefaults.standard.data(forKey: historyKey),
           let h = try? dec.decode([HistoryEntry].self, from: d) { completedHistory = h }
        momentum = UserDefaults.standard.integer(forKey: "momentum")
        streak   = UserDefaults.standard.integer(forKey: "streak")
        // Mirror streak/momentum to shared suite for widget
        shared.set(momentum, forKey: "momentum")
        shared.set(streak,   forKey: "streak")
        if let n = UserDefaults.standard.string(forKey: "userName") { shared.set(n, forKey: "userName") }
    }

    // Keep momentum/streak mirrored in shared suite
    private func syncShared() {
        shared.set(momentum, forKey: "momentum")
        shared.set(streak,   forKey: "streak")
        if let n = UserDefaults.standard.string(forKey: "userName") { shared.set(n, forKey: "userName") }
        reloadWidget()
    }

    private func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - History Entry
struct HistoryEntry: Identifiable, Codable {
    let id:    UUID
    let date:  String   // ISO8601 date string "2026-03-17"
    let tasks: [OpusTask]

    init(id: UUID = UUID(), date: String, tasks: [OpusTask]) {
        self.id    = id
        self.date  = date
        self.tasks = tasks
    }
}

// MARK: - Settings sub-sheet routing
enum SettingsSubSheet: String, Identifiable {
    case notifications, focusPrefs, statistics, privacy, about
    var id: String { rawValue }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @StateObject private var vm           = DashboardViewModel()
    @State private var selectedTab: AppTab = .today
    @State private var showSettings       = false
    @State private var activeSubSheet: SettingsSubSheet? = nil
    @State private var focusedTask: OpusTask? = nil
    @State private var filterCategory: TaskCategory? = nil
    @Namespace private var cardNS
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("focusWorkMinutes")  private var focusWorkMinutes  = 25
    @AppStorage("focusBreakMinutes") private var focusBreakMinutes = 5
    @AppStorage("focusSessionGoal")  private var focusSessionGoal  = 4
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Filtered pending tasks for the Today view
    private var displayedPending: [OpusTask] {
        guard let cat = filterCategory else { return vm.pendingTasks }
        return vm.pendingTasks.filter { $0.category == cat }
    }

    // MARK: - Greeting
    @AppStorage("userName") private var storedName = ""
    private var greeting: String {
        let h    = Calendar.current.component(.hour, from: Date())
        let name = storedName.trimmingCharacters(in: .whitespaces)
        let suffix = name.isEmpty ? "." : ", \(name)."
        switch h {
        case 0..<12:  return "Good morning\(suffix)"
        case 12..<17: return "Good afternoon\(suffix)"
        default:      return "Good evening\(suffix)"
        }
    }

    private var dateString: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {

                // ── Background ──
                backgroundLayer

                // ── Tab content ──
                Group {
                    switch selectedTab {
                    case .today:
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 24) {
                                headerSection
                                StatsCard(
                                    momentum: vm.momentum,
                                    streak: vm.streak,
                                    tasksCompleted: vm.completedTasks.count,
                                    tasksTotal: vm.todayTasks.count
                                )
                                .padding(.horizontal, 20)
                                taskListSection
                                laterSection
                                Spacer().frame(height: geo.safeAreaInsets.bottom + 140)
                            }
                            .padding(.top, geo.safeAreaInsets.top + 16)
                        }
                    case .projects:
                        ProjectsView(geo: geo)
                    case .focus:
                        FocusView(tasks: vm.todayTasks, geo: geo)
                    case .profile:
                        ProfileView(
                            streak: vm.streak,
                            momentum: vm.momentum,
                            completedCount: vm.completedTasks.count + vm.completedHistory.reduce(0) { $0 + $1.tasks.count },
                            history: vm.completedHistory,
                            geo: geo
                        )
                    }
                }
                .animation(reduceMotion ? .none : .easeInOut(duration: 0.22), value: selectedTab)

                // ── Bottom Navigation ──
                BottomNavigationBar(selectedTab: $selectedTab) {
                    withAnimation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.75)) {
                        switch selectedTab {
                        case .today, .focus: vm.showAddTask = true
                        default: break   // Projects/Profile handle their own add flow
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)

                // ── Task detail overlay ──
                if let task = focusedTask {
                    Color.black.opacity(0.65)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                focusedTask = nil
                            }
                        }
                        .zIndex(4)

                    taskDetailCard(task, geo: geo)
                        .matchedGeometryEffect(id: task.id, in: cardNS)
                        .zIndex(5)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.92).combined(with: .opacity),
                            removal:   .scale(scale: 0.92).combined(with: .opacity)
                        ))
                }
            }
            .ignoresSafeArea(edges: .all)
        }
        .sheet(isPresented: $vm.showAddTask) { addTaskSheet }
        .sheet(isPresented: $showSettings)   { settingsSheet }
        .sheet(item: $activeSubSheet) { sub in
            switch sub {
            case .notifications: notificationsSheet
            case .focusPrefs:    focusPrefsSheet
            case .statistics:    statisticsSheet
            case .privacy:       privacySheet
            case .about:         aboutSheet
            }
        }
        .fullScreenCover(isPresented: .constant(!hasOnboarded)) { OnboardingView() }
        .preferredColorScheme(.dark)
    }

    // MARK: - Background
    private var backgroundLayer: some View {
        ZStack {
            Color(hex: "#0D0D10")

            // Violet top-left
            RadialGradient(
                gradient: Gradient(colors: [Color(hex: "#6B3FA6").opacity(0.35), Color.clear]),
                center: .init(x: 0.15, y: 0.08),
                startRadius: 0, endRadius: 480
            )

            // Indigo mid-right
            RadialGradient(
                gradient: Gradient(colors: [Color(hex: "#3D2C8D").opacity(0.22), Color.clear]),
                center: .init(x: 0.92, y: 0.42),
                startRadius: 0, endRadius: 360
            )

            // Deep blue bottom-left
            RadialGradient(
                gradient: Gradient(colors: [Color(hex: "#1E3A5F").opacity(0.18), Color.clear]),
                center: .init(x: 0.08, y: 0.88),
                startRadius: 0, endRadius: 280
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateString)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.38))

                    Text(greeting)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white.opacity(0.55))
                        .frame(width: 42, height: 42)
                        .background {
                            ZStack {
                                Circle().fill(.ultraThinMaterial)
                                Circle().fill(Color.white.opacity(0.06))
                                Circle().stroke(Color.white.opacity(0.14), lineWidth: 1)
                            }
                        }
                }
                .accessibilityLabel("Settings")
            }

            // ── Floating streak pill ──
            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    Text("🔥")
                        .font(.system(size: 13))
                    Text("Day \(vm.streak)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#A78BFA"), Color(hex: "#8A4AF3")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                    Text("streak")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.50))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#8A4AF3").opacity(0.5), Color(hex: "#8A4AF3").opacity(0.1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color(hex: "#8A4AF3").opacity(0.25), radius: 12, x: 0, y: 4)

                Spacer()

                // Tasks remaining badge
                HStack(spacing: 5) {
                    Text("\(vm.pendingTasks.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text("tasks left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Task List Section
    private var taskListSection: some View {
        VStack(spacing: 0) {
            // Section header
            HStack(spacing: 10) {
                Text("Today")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.white)

                Text("\(vm.pendingTasks.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#8A4AF3"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#8A4AF3").opacity(0.15))
                    .clipShape(Capsule())

                Spacer()

                Text("remaining")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.28))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // ── Category filter chips ──
            if !vm.todayTasks.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // "All" chip
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.3)) { filterCategory = nil }
                        } label: {
                            Text("All")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(filterCategory == nil ? .white : .white.opacity(0.40))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    filterCategory == nil
                                        ? LinearGradient(colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                                         startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [Color.white.opacity(0.07), Color.white.opacity(0.07)],
                                                         startPoint: .leading, endPoint: .trailing),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.3), value: filterCategory)

                        // Category chips (only categories that have pending tasks)
                        ForEach(TaskCategory.allCases) { cat in
                            let count = vm.pendingTasks.filter { $0.category == cat }.count
                            if count > 0 {
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.spring(response: 0.3)) {
                                        filterCategory = filterCategory == cat ? nil : cat
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(cat.color)
                                            .frame(width: 6, height: 6)
                                        Text(cat.rawValue)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(filterCategory == cat ? cat.color : .white.opacity(0.40))
                                        Text("\(count)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(filterCategory == cat ? cat.color.opacity(0.7) : .white.opacity(0.25))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        filterCategory == cat
                                            ? cat.color.opacity(0.15)
                                            : Color.white.opacity(0.07),
                                        in: Capsule()
                                    )
                                    .overlay(
                                        Capsule().stroke(
                                            filterCategory == cat ? cat.color.opacity(0.45) : Color.clear,
                                            lineWidth: 1
                                        )
                                    )
                                }
                                .buttonStyle(.plain)
                                .animation(.spring(response: 0.3), value: filterCategory)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)
            }

            // Individual task cards (or empty state)
            if vm.pendingTasks.isEmpty && vm.completedTasks.isEmpty {
                emptyTodayState
            } else if displayedPending.isEmpty && filterCategory != nil {
                // Filter active but no matches
                VStack(spacing: 10) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundColor(.white.opacity(0.25))
                    Text("No \(filterCategory!.rawValue) tasks")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 8) {
                    ForEach(displayedPending) { task in
                        taskCard(task)
                            .matchedGeometryEffect(id: task.id, in: cardNS, isSource: focusedTask?.id != task.id)
                    }
                }
                .padding(.horizontal, 16)
            }

            // Done section
            if !vm.completedTasks.isEmpty {
                doneSection.padding(.top, 20)
            }
        }
    }

    // ── Empty state ──
    private var emptyTodayState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.badge.plus")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(
                    LinearGradient(colors: [Color(hex: "#A78BFA"), Color(hex: "#8A4AF3")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Text("Nothing on your plate")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Text("Tap the + button to add your first task")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.40))
                .multilineTextAlignment(.center)

            Button {
                withAnimation { vm.showAddTask = true }
            } label: {
                Label("Add Task", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                       startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
                    .shadow(color: Color(hex: "#8A4AF3").opacity(0.5), radius: 12, x: 0, y: 4)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "#1A1A1E"))
                .overlay(RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(hex: "#8A4AF3").opacity(0.2), lineWidth: 1))
        }
        .padding(.horizontal, 16)
    }

    // ── Individual task card ──
    @ViewBuilder
    private func taskCard(_ task: OpusTask) -> some View {
        TaskRow(task: task, onToggle: { vm.toggle(task) })
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#1A1A1E"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.30), radius: 8, x: 0, y: 4)
            }
            .contextMenu {
                Button { vm.toggle(task) } label: {
                    Label(task.isCompleted ? "Mark Incomplete" : "Mark Complete",
                          systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle.fill")
                }
                Divider()
                Button(role: .destructive) { vm.deleteTask(task) } label: {
                    Label("Delete", systemImage: "trash.fill")
                }
            }
            // simultaneousGesture lets the ScrollView scroll without delay;
            // a plain .onTapGesture would block scroll recognition on the first touch
            .simultaneousGesture(
                TapGesture().onEnded {
                    withAnimation(reduceMotion ? .none : .spring(response: 0.45, dampingFraction: 0.85)) {
                        focusedTask = task
                    }
                }
            )
    }

    // MARK: - Task Detail Card (matchedGeometryEffect destination)
    @ViewBuilder
    private func taskDetailCard(_ task: OpusTask, geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // Top row: category + close
            HStack {
                Text(task.category.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(task.category.color)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(task.category.color.opacity(0.15))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(task.category.color.opacity(0.3), lineWidth: 0.5))

                Spacer()

                Button {
                    withAnimation(reduceMotion ? .none : .spring(response: 0.45, dampingFraction: 0.85)) {
                        focusedTask = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.09))
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 20)

            // Title
            Text(task.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 12)

            // Due label
            if let due = task.dueLabel {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.35))
                    Text("Due: \(due)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.45))
                }
                .padding(.bottom, 24)
            }

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.bottom, 20)

            // Actions
            HStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.65)) {
                        vm.toggle(task)
                    }
                    withAnimation(reduceMotion ? .none : .spring(response: 0.45, dampingFraction: 0.85)) {
                        focusedTask = nil
                    }
                } label: {
                    Label(task.isCompleted ? "Mark Incomplete" : "Mark Complete",
                          systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    vm.deleteTask(task)
                    withAnimation(reduceMotion ? .none : .spring(response: 0.45, dampingFraction: 0.85)) {
                        focusedTask = nil
                    }
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                }
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 26)
                .fill(Color(hex: "#1A1A1E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.18), Color.white.opacity(0.04)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.6), radius: 40, x: 0, y: 20)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Done Section
    private var doneSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("Done")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(Color(hex: "#34D399").opacity(0.85))

                Text("\(vm.completedTasks.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#34D399"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#34D399").opacity(0.12))
                    .clipShape(Capsule())

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            VStack(spacing: 8) {
                ForEach(vm.completedTasks) { task in
                    TaskRow(task: task, onToggle: { vm.toggle(task) })
                        .padding(.horizontal, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "#141416"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                                )
                        }
                        .contextMenu {
                            Button { vm.toggle(task) } label: {
                                Label("Mark Incomplete", systemImage: "arrow.uturn.backward")
                            }
                            Divider()
                            Button(role: .destructive) { vm.deleteTask(task) } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Later Section
    private var laterSection: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.75)) {
                    vm.showLater.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Text("Later")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white.opacity(0.55))

                    Text("\(vm.laterTasks.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Capsule())

                    Spacer()

                    Image(systemName: vm.showLater ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.28))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, vm.showLater ? 12 : 0)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Later tasks, \(vm.laterTasks.count) items")

            if vm.showLater {
                VStack(spacing: 8) {
                    ForEach(vm.laterTasks) { task in
                        TaskRow(task: task, onToggle: {})
                            .padding(.horizontal, 16)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "#141416"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                                    )
                            }
                            .contextMenu {
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    withAnimation(.spring(response: 0.4)) { vm.promoteToToday(task) }
                                } label: {
                                    Label("Move to Today", systemImage: "sun.max.fill")
                                }
                                Divider()
                                Button(role: .destructive) { vm.deleteTask(task) } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Settings Sheet
    private var settingsSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D10").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── App identity ──
                        VStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color(hex: "#8A4AF3").opacity(0.5), radius: 20, x: 0, y: 8)
                                Text("✓")
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Text("Opus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            Text(storedName.isEmpty ? "Welcome" : "Hi, \(storedName.split(separator: " ").first.map(String.init) ?? storedName)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.45))
                            Text("Version 1.0 (Build 4)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.25))
                        }
                        .padding(.top, 12)

                        // ── Settings rows ──
                        VStack(spacing: 0) {
                            settingsRow(icon: "bell.fill", label: "Notifications", color: "#FF6B6B") {
                                activeSubSheet = .notifications
                            }
                            Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                            settingsRow(icon: "moon.fill", label: "Focus Preferences", color: "#6E6BF5") {
                                activeSubSheet = .focusPrefs
                            }
                            Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                            settingsRow(icon: "chart.bar.fill", label: "Statistics", color: "#34D399") {
                                activeSubSheet = .statistics
                            }
                            Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                            settingsRow(icon: "shield.fill", label: "Privacy", color: "#60A5FA") {
                                activeSubSheet = .privacy
                            }
                            Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                            settingsRow(icon: "info.circle.fill", label: "About Opus", color: "#A78BFA") {
                                activeSubSheet = .about
                            }
                        }
                        .background(Color(hex: "#1A1A1E"))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showSettings = false }
                        .foregroundColor(Color(hex: "#8A4AF3"))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private func settingsRow(icon: String, label: String, color: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: color).opacity(0.18))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: color))
                }
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.22))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notifications Sub-Sheet
    private var notificationsSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D10").ignoresSafeArea()
                VStack(spacing: 24) {
                    // Status card
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#FF6B6B").opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image(systemName: "bell.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "#FF6B6B"))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Push Notifications")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            Text(NotificationManager.shared.isAuthorized ? "Enabled ✓" : "Tap to enable in Settings")
                                .font(.system(size: 13))
                                .foregroundColor(NotificationManager.shared.isAuthorized
                                                 ? Color(hex: "#34D399") : Color(hex: "#FF6B6B"))
                        }
                        Spacer()
                    }
                    .padding(18)
                    .background(Color(hex: "#1A1A1E"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 0.5))

                    // What you get
                    VStack(alignment: .leading, spacing: 14) {
                        Text("WHAT YOU'LL RECEIVE")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.white.opacity(0.25))
                            .kerning(1.5)

                        ForEach([
                            ("sun.max.fill", "#F59E0B", "Daily 9 AM reminder", "Your pending task count, every morning"),
                            ("moon.stars.fill", "#A78BFA", "Evening streak guard", "8 PM nudge if you still have tasks left"),
                            ("calendar.badge.clock", "#60A5FA", "Due date alerts", "30 minutes before a task is due"),
                            ("party.popper.fill", "#34D399", "All-done celebration", "When you clear your entire list"),
                        ], id: \.2) { icon, color, title, subtitle in
                            HStack(spacing: 14) {
                                Image(systemName: icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: color))
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))
                                    Text(subtitle)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.38))
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(Color(hex: "#1A1A1E"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 0.5))

                    // Open Settings button
                    Button {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Notification Settings", systemImage: "arrow.up.right.square")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient(
                                colors: [Color(hex: "#FF6B6B"), Color(hex: "#FF3B30")],
                                startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { activeSubSheet = nil }
                        .foregroundColor(Color(hex: "#8A4AF3"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Focus Preferences Sub-Sheet
    private var focusPrefsSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D10").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        stepperCard(
                            icon: "timer", color: "#6E6BF5",
                            title: "Work Session",
                            subtitle: "Minutes of focused work",
                            value: $focusWorkMinutes, range: 5...90, step: 5
                        )

                        stepperCard(
                            icon: "cup.and.saucer.fill", color: "#34D399",
                            title: "Break Length",
                            subtitle: "Minutes to rest between sessions",
                            value: $focusBreakMinutes, range: 1...30, step: 1
                        )

                        stepperCard(
                            icon: "flag.checkered", color: "#F59E0B",
                            title: "Daily Session Goal",
                            subtitle: "Target sessions per day",
                            value: $focusSessionGoal, range: 1...12, step: 1
                        )

                        Text("Changes take effect next time you start Focus Mode.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.28))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        Spacer().frame(height: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Focus Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { activeSubSheet = nil }
                        .foregroundColor(Color(hex: "#8A4AF3"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func stepperCard(icon: String, color: String, title: String, subtitle: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: color).opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: color))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.38))
            }
            Spacer()
            HStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if value.wrappedValue - step >= range.lowerBound { value.wrappedValue -= step }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                Text("\(value.wrappedValue)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .frame(minWidth: 36)
                    .monospacedDigit()
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if value.wrappedValue + step <= range.upperBound { value.wrappedValue += step }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 30, height: 30)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#1A1A1E"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
    }

    // MARK: - Statistics Sub-Sheet
    private var statisticsSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D10").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        let totalCompleted = vm.completedTasks.count + vm.completedHistory.reduce(0) { $0 + $1.tasks.count }
                        let avgPerDay = vm.completedHistory.isEmpty ? 0 : vm.completedHistory.reduce(0) { $0 + $1.tasks.count } / max(vm.completedHistory.count, 1)
                        let bestDay = vm.completedHistory.max(by: { $0.tasks.count < $1.tasks.count })

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            statBlock(emoji: "✅", value: "\(totalCompleted)", label: "Total Completed")
                            statBlock(emoji: "🔥", value: "\(vm.streak)", label: "Current Streak")
                            statBlock(emoji: "⚡️", value: "\(vm.momentum)%", label: "Momentum")
                            statBlock(emoji: "📅", value: "\(vm.completedHistory.count)", label: "Days Logged")
                            statBlock(emoji: "📊", value: "\(avgPerDay)", label: "Avg / Day")
                            statBlock(emoji: "🏆", value: "\(bestDay?.tasks.count ?? 0)", label: "Best Day")
                        }

                        if !vm.completedHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("RECENT DAYS")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(.white.opacity(0.25))
                                    .kerning(1.5)

                                ForEach(vm.completedHistory.prefix(5)) { entry in
                                    HStack {
                                        Text(entry.date)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                        Spacer()
                                        Text("\(entry.tasks.count) task\(entry.tasks.count == 1 ? "" : "s")")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Color(hex: "#34D399"))
                                    }
                                    .padding(.vertical, 6)
                                    if entry.id != vm.completedHistory.prefix(5).last?.id {
                                        Divider().background(Color.white.opacity(0.06))
                                    }
                                }
                            }
                            .padding(18)
                            .background(Color(hex: "#1A1A1E"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { activeSubSheet = nil }
                        .foregroundColor(Color(hex: "#8A4AF3"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func statBlock(emoji: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Text(emoji).font(.system(size: 26))
            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(hex: "#1A1A1E"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
    }

    // MARK: - Privacy Sub-Sheet
    private var privacySheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D10").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Shield icon
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#60A5FA").opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: "shield.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color(hex: "#60A5FA"))
                        }

                        Text("Your data stays on your device.")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        VStack(spacing: 12) {
                            ForEach([
                                ("lock.fill", "#60A5FA", "100% On-Device", "Tasks, streaks, and stats are stored locally in UserDefaults. Nothing leaves your phone."),
                                ("wifi.slash", "#34D399", "No Accounts Required", "Opus works without signing in. No email, no password, no cloud sync."),
                                ("eye.slash.fill", "#A78BFA", "No Analytics", "We don't track what you do inside the app. No usage data is collected."),
                                ("bell.slash.fill", "#F59E0B", "Notifications are Local", "All reminders are scheduled on-device via UserNotifications. No servers involved."),
                            ], id: \.2) { icon, color, title, body in
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: icon)
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: color))
                                        .frame(width: 24, height: 24)
                                        .padding(.top, 2)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(body)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.45))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .padding(16)
                                .background(Color(hex: "#1A1A1E"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
                            }
                        }
                        Spacer().frame(height: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { activeSubSheet = nil }
                        .foregroundColor(Color(hex: "#8A4AF3"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - About Sub-Sheet
    private var aboutSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D10").ignoresSafeArea()
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 26)
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 100, height: 100)
                                .shadow(color: Color(hex: "#8A4AF3").opacity(0.55), radius: 28, x: 0, y: 10)
                            Text("✓")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("Opus")
                            .font(.system(size: 30, weight: .black))
                            .foregroundColor(.white)
                        Text("Version 1.0 · Build 4")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.32))
                    }
                    .padding(.top, 20)

                    VStack(spacing: 0) {
                        aboutRow(label: "Developer", value: storedName.isEmpty ? "Unknown" : storedName)
                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                        aboutRow(label: "Platform", value: "iOS 17+")
                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                        aboutRow(label: "Built with", value: "SwiftUI · WidgetKit")
                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                        aboutRow(label: "Beta", value: "TestFlight")
                    }
                    .background(Color(hex: "#1A1A1E"))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.07), lineWidth: 0.5))
                    .padding(.horizontal, 20)

                    Text("Made with focus, for people who build.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.28))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Spacer()
                }
            }
            .navigationTitle("About Opus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { activeSubSheet = nil }
                        .foregroundColor(Color(hex: "#8A4AF3"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    // MARK: - Add Task Sheet
    private var addTaskSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D10").ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(spacing: 20) {

                        // ── Title field ──
                        TextField("Task title", text: $vm.newTaskTitle)
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: "#8A4AF3").opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: vm.newTaskTitle) { _, new in
                                if new.count > InputValidator.maxTaskTitleLength {
                                    vm.newTaskTitle = String(new.prefix(InputValidator.maxTaskTitleLength))
                                }
                            }

                        // ── Category picker ──
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Category")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.35))
                                .kerning(0.5)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(TaskCategory.allCases) { cat in
                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            vm.newTaskCategory = cat
                                        } label: {
                                            HStack(spacing: 6) {
                                                Circle()
                                                    .fill(cat.color)
                                                    .frame(width: 7, height: 7)
                                                Text(cat.rawValue)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(
                                                        vm.newTaskCategory == cat
                                                            ? cat.color
                                                            : .white.opacity(0.45)
                                                    )
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 9)
                                            .background(
                                                vm.newTaskCategory == cat
                                                    ? cat.color.opacity(0.15)
                                                    : Color.white.opacity(0.06),
                                                in: Capsule()
                                            )
                                            .overlay(
                                                Capsule().stroke(
                                                    vm.newTaskCategory == cat
                                                        ? cat.color.opacity(0.45)
                                                        : Color.clear,
                                                    lineWidth: 1
                                                )
                                            )
                                            .animation(.spring(response: 0.3), value: vm.newTaskCategory)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // ── Schedule toggle ──
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Schedule")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.35))
                                .kerning(0.5)

                            HStack(spacing: 8) {
                                ForEach([TaskSchedule.today, TaskSchedule.later], id: \.self) { sched in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        vm.newTaskSchedule = sched
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: sched == .today ? "sun.max.fill" : "moon.fill")
                                                .font(.system(size: 12))
                                            Text(sched.rawValue.capitalized)
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(vm.newTaskSchedule == sched ? .white : .white.opacity(0.40))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 11)
                                        .background(
                                            vm.newTaskSchedule == sched
                                                ? LinearGradient(
                                                    colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                                    startPoint: .leading, endPoint: .trailing)
                                                : LinearGradient(
                                                    colors: [Color.white.opacity(0.07), Color.white.opacity(0.07)],
                                                    startPoint: .leading, endPoint: .trailing),
                                            in: RoundedRectangle(cornerRadius: 11)
                                        )
                                        .animation(.spring(response: 0.3), value: vm.newTaskSchedule)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // ── Repeat ──
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Repeat")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.35))
                                .kerning(0.5)

                            HStack(spacing: 8) {
                                ForEach(TaskRepeat.allCases, id: \.rawValue) { rep in
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        vm.newTaskRepeat = rep
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: rep.icon)
                                                .font(.system(size: 11, weight: .medium))
                                            Text(rep.label)
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        .foregroundColor(
                                            vm.newTaskRepeat == rep
                                                ? Color(hex: "#8A4AF3")
                                                : .white.opacity(0.40)
                                        )
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            vm.newTaskRepeat == rep
                                                ? Color(hex: "#8A4AF3").opacity(0.15)
                                                : Color.white.opacity(0.06),
                                            in: RoundedRectangle(cornerRadius: 10)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10).stroke(
                                                vm.newTaskRepeat == rep
                                                    ? Color(hex: "#8A4AF3").opacity(0.45)
                                                    : Color.clear,
                                                lineWidth: 1
                                            )
                                        )
                                        .animation(.spring(response: 0.3), value: vm.newTaskRepeat)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // ── Due date ──
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $vm.hasDueDate.animation(.spring(response: 0.3))) {
                                Label("Set due date", systemImage: "calendar")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#8A4AF3")))

                            if vm.hasDueDate {
                                DatePicker("", selection: $vm.newTaskDueDate,
                                           in: Date()...,
                                           displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .colorScheme(.dark)
                                    .accentColor(Color(hex: "#8A4AF3"))
                                    .labelsHidden()
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }

                        // ── Add button ──
                        Button(action: vm.addTask) {
                            Text("Add Task")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: Color(hex: "#8A4AF3").opacity(0.4), radius: 14, x: 0, y: 6)
                        }
                        .disabled(vm.newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(vm.newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                    }
                    .padding(20)

                    Spacer()
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.showAddTask = false }
                        .foregroundColor(.white.opacity(0.55))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

}

// MARK: - Preview
#Preview {
    DashboardView()
}
