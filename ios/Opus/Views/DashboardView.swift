import SwiftUI

// MARK: - Dashboard ViewModel
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var todayTasks: [OpusTask]      = OpusTask.sampleToday
    @Published var laterTasks: [OpusTask]      = OpusTask.sampleLater
    @Published var momentum: Int               = 77
    @Published var streak: Int                 = 14
    @Published var showLater: Bool             = false
    @Published var showAddTask: Bool           = false
    @Published var newTaskTitle: String        = ""

    var completedTasks: [OpusTask] { todayTasks.filter(\.isCompleted) }
    var pendingTasks:   [OpusTask] { todayTasks.filter { !$0.isCompleted } }

    func toggle(_ task: OpusTask) {
        guard let idx = todayTasks.firstIndex(where: { $0.id == task.id }) else { return }
        todayTasks[idx].isCompleted.toggle()
        // Recalculate momentum
        let pct = Double(completedTasks.count) / Double(max(todayTasks.count, 1))
        momentum = min(100, max(0, Int(Double(streak) * 4 + pct * 25)))
    }

    func addTask() {
        guard InputValidator.isValidTaskTitle(newTaskTitle) else { return }
        let title = InputValidator.sanitizeTaskTitle(newTaskTitle)
        let task = OpusTask(title: title, category: .work, schedule: .today, dueLabel: "today")
        todayTasks.append(task)
        newTaskTitle = ""
        showAddTask = false
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()
    @State private var selectedTab: AppTab = .today
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good morning."
        case 12..<17: return "Good afternoon."
        default:      return "Good evening."
        }
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {

                // ── Background ──
                backgroundLayer

                // ── Content ──
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {

                            // ── Header ──
                            headerSection

                            // ── Stats Card ──
                            StatsCard(
                                momentum: vm.momentum,
                                streak: vm.streak,
                                tasksCompleted: vm.completedTasks.count,
                                tasksTotal: vm.todayTasks.count
                            )
                            .padding(.horizontal, 20)

                            // ── Task List ──
                            taskListSection

                            // ── Later Section ──
                            laterSection

                            // Bottom padding for nav bar + home indicator
                            Spacer()
                                .frame(height: geo.safeAreaInsets.bottom + 88)
                        }
                        .padding(.top, geo.safeAreaInsets.top + 16)
                    }

                    Spacer(minLength: 0)
                }

                // ── Bottom Navigation ──
                VStack(spacing: 0) {
                    Spacer()
                    BottomNavigationBar(selectedTab: $selectedTab) {
                        withAnimation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.75)) {
                            vm.showAddTask = true
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .ignoresSafeArea(edges: .all)
        }
        .sheet(isPresented: $vm.showAddTask) { addTaskSheet }
        .preferredColorScheme(.dark)
    }

    // MARK: - Background
    private var backgroundLayer: some View {
        ZStack {
            Color(hex: "#08070A")

            // Purple glow top-left
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#6B3FA6").opacity(0.28),
                    Color.clear
                ]),
                center: .init(x: 0.2, y: 0.1),
                startRadius: 0,
                endRadius: 440
            )

            // Orange glow mid-right
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#F5A623").opacity(0.14),
                    Color.clear
                ]),
                center: .init(x: 0.9, y: 0.55),
                startRadius: 0,
                endRadius: 320
            )

            // Deep blue accent bottom
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#1E3A5F").opacity(0.20),
                    Color.clear
                ]),
                center: .init(x: 0.1, y: 0.9),
                startRadius: 0,
                endRadius: 260
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(nil)

                Text(greeting)
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(.white)
            }

            Spacer()

            Button {
                // Settings action
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 42, height: 42)
                    .background {
                        ZStack {
                            Circle().fill(.ultraThinMaterial)
                            Circle().fill(Color.white.opacity(0.07))
                            Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                        }
                    }
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Task List
    private var taskListSection: some View {
        VStack(spacing: 0) {
            // Section header
            HStack {
                Text("TODAY")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
                    .kerning(1.4)
                Spacer()
                Text("\(vm.pendingTasks.count) remaining")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            // Pending tasks
            VStack(spacing: 0) {
                ForEach(vm.pendingTasks) { task in
                    TaskRow(task: task) { vm.toggle(task) }
                        .padding(.horizontal, 16)

                    if task.id != vm.pendingTasks.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.horizontal, 16)
                    }
                }
            }
            .liquidGlass(cornerRadius: 20)
            .padding(.horizontal, 16)

            // Done section
            if !vm.completedTasks.isEmpty {
                doneSection
                    .padding(.top, 16)
            }
        }
    }

    // MARK: - Done Section
    private var doneSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("DONE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#34D399").opacity(0.6))
                    .kerning(1.4)
                Text("\(vm.completedTasks.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#34D399").opacity(0.5))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color(hex: "#34D399").opacity(0.1))
                    .clipShape(Capsule())
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(vm.completedTasks) { task in
                    TaskRow(task: task) { vm.toggle(task) }
                        .padding(.horizontal, 16)

                    if task.id != vm.completedTasks.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.horizontal, 16)
                    }
                }
            }
            .liquidGlass(cornerRadius: 20)
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
                HStack {
                    Text("LATER")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.35))
                        .kerning(1.4)
                    Text("\(vm.laterTasks.count)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                    Spacer()
                    Image(systemName: vm.showLater ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, vm.showLater ? 8 : 0)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Later tasks, \(vm.laterTasks.count) items")
            .accessibilityAddTraits(.isButton)

            if vm.showLater {
                VStack(spacing: 0) {
                    ForEach(vm.laterTasks) { task in
                        TaskRow(task: task) {}
                            .padding(.horizontal, 16)

                        if task.id != vm.laterTasks.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.06))
                                .padding(.horizontal, 16)
                        }
                    }
                }
                .liquidGlass(cornerRadius: 20)
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Add Task Sheet
    private var addTaskSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0F0E11").ignoresSafeArea()

                VStack(spacing: 20) {
                    TextField("Task title", text: $vm.newTaskTitle)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                        .onChange(of: vm.newTaskTitle) { _, new in
                            if new.count > InputValidator.maxTaskTitleLength {
                                vm.newTaskTitle = String(new.prefix(InputValidator.maxTaskTitleLength))
                            }
                        }

                    Button(action: vm.addTask) {
                        Text("Add Task")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#F5A623"), Color(hex: "#FF6B6B")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(vm.newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(vm.newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { vm.showAddTask = false }
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
}
