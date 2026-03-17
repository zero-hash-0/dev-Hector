import SwiftUI

// MARK: - Onboarding Goal
enum OnboardingGoal: String, CaseIterable {
    case builder    = "Build & Ship"
    case learner    = "Learn & Grow"
    case balance    = "Work-Life Balance"
    case health     = "Health & Fitness"
    case creator    = "Create & Design"

    var emoji: String {
        switch self {
        case .builder:  return "🚀"
        case .learner:  return "📚"
        case .balance:  return "⚖️"
        case .health:   return "💪"
        case .creator:  return "🎨"
        }
    }

    var description: String {
        switch self {
        case .builder:  return "Ship projects and side hustles"
        case .learner:  return "Master new skills every day"
        case .balance:  return "Stay productive without burnout"
        case .health:   return "Build healthy daily habits"
        case .creator:  return "Bring ideas to life"
        }
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("userName")     private var userName     = ""

    @State private var page:         Int              = 0
    @State private var name:         String           = ""
    @State private var selectedGoal: OnboardingGoal?  = nil
    @State private var animIn:       Bool             = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Background
            Color(hex: "#0D0D10").ignoresSafeArea()
            RadialGradient(
                gradient: Gradient(colors: [Color(hex: "#6B3FA6").opacity(0.42), Color.clear]),
                center: .init(x: 0.2, y: 0.1),
                startRadius: 0, endRadius: 520
            ).ignoresSafeArea()
            RadialGradient(
                gradient: Gradient(colors: [Color(hex: "#3D2C8D").opacity(0.28), Color.clear]),
                center: .init(x: 0.85, y: 0.75),
                startRadius: 0, endRadius: 380
            ).ignoresSafeArea()

            switch page {
            case 0:  welcomePage
            case 1:  namePage
            default: goalPage
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? .none : .spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                animIn = true
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Page 1: Welcome
    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo mark
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .shadow(color: Color(hex: "#8A4AF3").opacity(0.6), radius: 36, x: 0, y: 16)
                    .scaleEffect(animIn ? 1 : 0.6)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .scaleEffect(animIn ? 1 : 0.6)
            }
            .animation(reduceMotion ? .none : .spring(response: 0.65, dampingFraction: 0.72), value: animIn)
            .padding(.bottom, 40)

            VStack(spacing: 14) {
                Text("Welcome to Opus")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(animIn ? 1 : 0)
                    .offset(y: animIn ? 0 : 20)
                    .animation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: animIn)

                Text("Your personal productivity OS.\nFocus. Build. Ship.")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.50))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(animIn ? 1 : 0)
                    .offset(y: animIn ? 0 : 16)
                    .animation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: animIn)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Feature chips
            VStack(spacing: 12) {
                featureRow(icon: "checklist",         color: "#8A4AF3", text: "Capture tasks in seconds")
                featureRow(icon: "timer",             color: "#6E6BF5", text: "Deep work with Pomodoro focus")
                featureRow(icon: "chart.bar.fill",    color: "#34D399", text: "Track streaks and momentum")
                featureRow(icon: "folder.fill",       color: "#60A5FA", text: "Organize goals with projects")
            }
            .padding(.horizontal, 28)
            .opacity(animIn ? 1 : 0)
            .offset(y: animIn ? 0 : 24)
            .animation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8).delay(0.35), value: animIn)

            Spacer()

            nextButton("Get Started") {
                advance()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
            .opacity(animIn ? 1 : 0)
            .offset(y: animIn ? 0 : 16)
            .animation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8).delay(0.45), value: animIn)
        }
    }

    private func featureRow(icon: String, color: String, text: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: color).opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: color))
            }
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.72))
            Spacer()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
        }
    }

    // MARK: - Page 2: Name
    private var namePage: some View {
        VStack(spacing: 0) {
            pageHeader(step: "1 of 2")

            Spacer()

            VStack(spacing: 28) {
                VStack(spacing: 12) {
                    Text("What should we\ncall you?")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    Text("Your name shows up in greetings and your profile.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.42))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)

                // Name field
                TextField("First name", text: $name)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 18)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        name.trimmingCharacters(in: .whitespaces).isEmpty
                                            ? Color.white.opacity(0.1)
                                            : Color(hex: "#8A4AF3").opacity(0.55),
                                        lineWidth: 1.5
                                    )
                            )
                    }
                    .padding(.horizontal, 28)
                    .submitLabel(.next)
                    .onSubmit { if canAdvanceName { advance() } }
            }

            Spacer()

            nextButton("Continue", disabled: !canAdvanceName) {
                advance()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
        }
    }

    private var canAdvanceName: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Page 3: Goal
    private var goalPage: some View {
        VStack(spacing: 0) {
            pageHeader(step: "2 of 2")

            Spacer()

            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("What's your main\nfocus, \(name.trimmingCharacters(in: .whitespaces))?")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    Text("We'll tailor your experience to match your goals.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.42))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)

                VStack(spacing: 10) {
                    ForEach(OnboardingGoal.allCases, id: \.rawValue) { goal in
                        goalRow(goal)
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer()

            nextButton("Start Using Opus", disabled: selectedGoal == nil) {
                finishOnboarding()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 48)
        }
    }

    private func goalRow(_ goal: OnboardingGoal) -> some View {
        let selected = selectedGoal == goal
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedGoal = goal
            }
        } label: {
            HStack(spacing: 16) {
                Text(goal.emoji)
                    .font(.system(size: 26))

                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(selected ? .white : .white.opacity(0.75))
                    Text(goal.description)
                        .font(.system(size: 12))
                        .foregroundColor(selected ? .white.opacity(0.65) : .white.opacity(0.35))
                }

                Spacer()

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(selected ? Color(hex: "#8A4AF3") : .white.opacity(0.2))
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(selected ? Color(hex: "#8A4AF3").opacity(0.14) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                selected ? Color(hex: "#8A4AF3").opacity(0.5) : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selected)
    }

    // MARK: - Shared Components

    private func pageHeader(step: String) -> some View {
        HStack {
            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<2, id: \.self) { i in
                    Capsule()
                        .fill(i < page
                              ? Color(hex: "#8A4AF3")
                              : (i == page - 1 ? Color(hex: "#8A4AF3") : Color.white.opacity(0.2)))
                        .frame(width: (page - 1) == i ? 20 : 8, height: 8)
                        .animation(.spring(response: 0.4), value: page)
                }
            }
            Spacer()
            Text(step)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.32))
        }
        .padding(.horizontal, 28)
        .padding(.top, 60)
        .padding(.bottom, 8)
    }

    private func nextButton(_ label: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            Text(label)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    LinearGradient(
                        colors: disabled
                            ? [Color.white.opacity(0.1), Color.white.opacity(0.1)]
                            : [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: disabled ? .clear : Color(hex: "#8A4AF3").opacity(0.45), radius: 18, x: 0, y: 8)
        }
        .disabled(disabled)
        .animation(.spring(response: 0.3), value: disabled)
    }

    // MARK: - Navigation
    private func advance() {
        withAnimation(reduceMotion ? .none : .spring(response: 0.45, dampingFraction: 0.85)) {
            page += 1
        }
    }

    private func finishOnboarding() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        userName = trimmed.isEmpty ? "Friend" : trimmed
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.85)) {
            hasOnboarded = true
        }
    }
}

#Preview {
    OnboardingView()
}
