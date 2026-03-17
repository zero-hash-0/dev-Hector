import SwiftUI

// MARK: - Session Type
enum FocusSessionType: CaseIterable {
    case focus, shortBreak, longBreak

    var label: String {
        switch self {
        case .focus:      return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak:  return "Long Break"
        }
    }

    var duration: Int {
        switch self {
        case .focus:      return 25 * 60
        case .shortBreak: return 5  * 60
        case .longBreak:  return 15 * 60
        }
    }

    var color: Color {
        switch self {
        case .focus:      return Color(hex: "#8A4AF3")
        case .shortBreak: return Color(hex: "#34D399")
        case .longBreak:  return Color(hex: "#60A5FA")
        }
    }

    var icon: String {
        switch self {
        case .focus:      return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak:  return "figure.walk"
        }
    }
}

// MARK: - Focus View
struct FocusView: View {
    @State private var sessionType: FocusSessionType  = .focus
    @State private var timeRemaining: Int             = FocusSessionType.focus.duration
    @State private var isRunning                      = false
    @State private var completedSessions              = 0
    @State private var totalFocusMinutes              = 0
    @State private var currentTask                    = ""
    @State private var showTaskPicker                 = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let tasks: [OpusTask]
    let geo: GeometryProxy

    // Pending task titles for the picker
    private var pendingTasks: [OpusTask] { tasks.filter { !$0.isCompleted } }

    // MARK: Computed
    var timeDisplay: String {
        String(format: "%02d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    var progress: CGFloat {
        let total = CGFloat(sessionType.duration)
        return (total - CGFloat(timeRemaining)) / total
    }

    var sessionsUntilLongBreak: Int { 4 }

    // MARK: Body
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                headerSection
                sessionTypePicker
                timerRing
                sessionDots
                controlButtons
                currentTaskCard
                statsRow
                Spacer().frame(height: geo.safeAreaInsets.bottom + 140)
            }
            .padding(.top, geo.safeAreaInsets.top + 16)
        }
        .onReceive(clock) { _ in tick() }
        .onAppear {
            // Default to first pending task if nothing selected
            if currentTask.isEmpty, let first = pendingTasks.first {
                currentTask = first.title
            }
        }
        .sheet(isPresented: $showTaskPicker) { taskPickerSheet }
    }

    // MARK: Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Focus Mode")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                Text(sessionType.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(sessionType.color.opacity(0.85))
            }
            Spacer()
            // Total today
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(totalFocusMinutes)m")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "#A78BFA"), Color(hex: "#8A4AF3")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                Text("today")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: Session Type Picker
    private var sessionTypePicker: some View {
        HStack(spacing: 0) {
            ForEach(FocusSessionType.allCases, id: \.label) { type in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.8)) {
                        sessionType   = type
                        timeRemaining = type.duration
                        isRunning     = false
                    }
                } label: {
                    Text(type.label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(sessionType == type ? .white : .white.opacity(0.38))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            sessionType == type
                                ? type.color.opacity(0.28)
                                : Color.clear,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
    }

    // MARK: Timer Ring
    private var timerRing: some View {
        ZStack {
            // Ambient glow
            Circle()
                .fill(sessionType.color.opacity(isRunning ? 0.07 : 0.03))
                .frame(width: 260, height: 260)
                .blur(radius: 20)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isRunning)

            // Track
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 16)
                .frame(width: 224, height: 224)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: sessionType.color.opacity(0.55), location: 0),
                            .init(color: sessionType.color,               location: 0.5),
                            .init(color: sessionType.color.opacity(0.9),  location: 1)
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 224, height: 224)
                .rotationEffect(.degrees(-90))
                .shadow(color: sessionType.color.opacity(0.75), radius: 14)
                .animation(.linear(duration: 0.5), value: progress)

            // Center
            VStack(spacing: 6) {
                Text(timeDisplay)
                    .font(.system(size: 58, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()

                HStack(spacing: 5) {
                    Image(systemName: sessionType.icon)
                        .font(.system(size: 11))
                    Text(isRunning ? "Keep going" : "Ready when you are")
                        .font(.system(size: 12))
                }
                .foregroundColor(.white.opacity(0.35))
            }
        }
    }

    // MARK: Session Dots
    private var sessionDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<sessionsUntilLongBreak, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(i < completedSessions % sessionsUntilLongBreak
                          ? sessionType.color
                          : Color.white.opacity(0.12))
                    .frame(width: i < completedSessions % sessionsUntilLongBreak ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4), value: completedSessions)
            }
        }
    }

    // MARK: Controls
    private var controlButtons: some View {
        HStack(spacing: 20) {
            // Reset
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                timeRemaining = sessionType.duration
                isRunning = false
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
                    .frame(width: 54, height: 54)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
            }

            // Play / Pause
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7)) {
                    isRunning.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#6E6BF5"), sessionType.color],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: sessionType.color.opacity(0.65), radius: 22, x: 0, y: 8)
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                        .offset(x: isRunning ? 0 : 2)
                }
            }

            // Skip
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                completeSession()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))
                    .frame(width: 54, height: 54)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
    }

    // MARK: Current Task Card
    private var currentTaskCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Focusing on")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.32))
                .kerning(0.5)
                .padding(.horizontal, 20)

            Button { showTaskPicker = true } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 8, height: 8)
                    Text(currentTask.isEmpty ? "Tap to select a task" : currentTask)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(currentTask.isEmpty ? .white.opacity(0.35) : .white.opacity(0.88))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "#1A1A1E"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "#8A4AF3").opacity(0.25), lineWidth: 1)
                        )
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
        }
    }

    // MARK: Stats Row
    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(completedSessions)", label: "Sessions", icon: "checkmark.seal.fill")
            statCard(value: "\(totalFocusMinutes)m", label: "Focus Time", icon: "timer")
            statCard(value: "\(completedSessions / max(sessionsUntilLongBreak, 1))", label: "Deep Work", icon: "brain")
        }
        .padding(.horizontal, 16)
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#8A4AF3").opacity(0.8))
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.32))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#1A1A1E"))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 0.5))
        }
    }

    // MARK: Task Picker Sheet
    private var taskPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0D0D10").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        if pendingTasks.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40, weight: .thin))
                                    .foregroundColor(Color(hex: "#34D399").opacity(0.6))
                                Text("All tasks done!")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Add tasks from the Today tab")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(40)
                        } else {
                            ForEach(pendingTasks) { task in
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    currentTask = task.title
                                    showTaskPicker = false
                                } label: {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(task.category.color)
                                            .frame(width: 8, height: 8)
                                        Text(task.title)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white.opacity(0.88))
                                            .lineLimit(1)
                                        Spacer()
                                        Text(task.category.rawValue)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(task.category.color)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(task.category.color.opacity(0.12))
                                            .clipShape(Capsule())
                                        if currentTask == task.title {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Color(hex: "#8A4AF3"))
                                        }
                                    }
                                    .padding(14)
                                    .background {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(currentTask == task.title
                                                  ? Color(hex: "#8A4AF3").opacity(0.12)
                                                  : Color(hex: "#1A1A1E"))
                                            .overlay(RoundedRectangle(cornerRadius: 14)
                                                .stroke(currentTask == task.title
                                                        ? Color(hex: "#8A4AF3").opacity(0.35)
                                                        : Color.white.opacity(0.06), lineWidth: 1))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Focusing on")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showTaskPicker = false }
                        .foregroundColor(.white.opacity(0.55))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    // MARK: Logic
    private func tick() {
        guard isRunning else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
            if sessionType == .focus { totalFocusMinutes = (sessionType.duration - timeRemaining) / 60 }
        } else {
            completeSession()
        }
    }

    private func completeSession() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isRunning = false
        if sessionType == .focus {
            completedSessions += 1
            let isLongBreak = completedSessions % sessionsUntilLongBreak == 0
            sessionType = isLongBreak ? .longBreak : .shortBreak
        } else {
            sessionType = .focus
        }
        timeRemaining = sessionType.duration
    }
}
