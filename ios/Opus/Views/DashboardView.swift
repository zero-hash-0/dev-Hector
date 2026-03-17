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
    }

    func deleteTask(_ task: OpusTask) {
        withAnimation(.spring(response: 0.4)) {
            todayTasks.removeAll { $0.id == task.id }
        }
    }

    func addTask() {
        guard InputValidator.isValidTaskTitle(newTaskTitle) else { return }
        let title = InputValidator.sanitizeTaskTitle(newTaskTitle)
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
            dueLabel:   dueLabel,
            taskRepeat: newTaskRepeat
        )
        if newTaskSchedule == .today { todayTasks.append(task) }
        else                         { laterTasks.append(task) }
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

// MARK: - Dashboard View
struct DashboardView: View {
    @StateObject private var vm           = DashboardViewModel()
    @State private var selectedTab: AppTab = .today
    @State private var showSettings       = false
    @State private var focusedTask: OpusTask? = nil
    @State private var filterCategory: TaskCategory? = nil
    @Namespace private var cardNS
    @AppStorage("hasOnboarded") private var hasOnboarded = false
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

                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)
                            Image(systemName: "person.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                        Text("Hector")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 0) {
                        ForEach([
                            ("bell.fill",       "Notifications"),
                            ("moon.fill",       "Focus Preferences"),
                            ("chart.bar.fill",  "Statistics"),
                            ("shield.fill",     "Privacy"),
                            ("info.circle.fill","About Opus")
                        ], id: \.1) { icon, title in
                            HStack(spacing: 14) {
                                Image(systemName: icon)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "#8A4AF3"))
                                    .frame(width: 28)
                                Text(title)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.22))
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)

                            if title != "About Opus" {
                                Divider()
                                    .background(Color.white.opacity(0.06))
                                    .padding(.horizontal, 18)
                            }
                        }
                    }
                    .liquidGlass(cornerRadius: 20)
                    .padding(.horizontal, 16)

                    Spacer()
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
