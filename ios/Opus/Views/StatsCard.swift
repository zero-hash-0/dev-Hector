import SwiftUI

// MARK: - Liquid Glass Modifier
struct LiquidGlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 22
    func body(content: Content) -> some View {
        content.background {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.10), Color.white.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                // Top specular highlight
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.30), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.45), radius: 28, x: 0, y: 10)
        }
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 22) -> some View {
        modifier(LiquidGlassBackground(cornerRadius: cornerRadius))
    }
}

// MARK: - Momentum Ring
struct MomentumRing: View {
    let value: Int
    let maxValue: Int = 100
    @State private var animatedProgress: CGFloat = 0

    private var progress: CGFloat { CGFloat(value) / CGFloat(maxValue) }
    private var ringColor: Color {
        switch value {
        case 80...: return Color(hex: "#F5A623")
        case 60...: return Color(hex: "#A78BFA")
        default:    return Color(hex: "#60A5FA")
        }
    }

    var body: some View {
        ZStack {
            // Glow halo
            Circle()
                .stroke(ringColor.opacity(0.15), lineWidth: 16)
                .frame(width: 104, height: 104)
                .blur(radius: 4)
            // Track
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 11)
                .frame(width: 104, height: 104)
            // Progress arc
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: ringColor.opacity(0.55), location: 0),
                            .init(color: ringColor,               location: 0.5),
                            .init(color: ringColor.opacity(0.85), location: 1)
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 11, lineCap: .round)
                )
                .frame(width: 104, height: 104)
                .rotationEffect(.degrees(-90))
                .shadow(color: ringColor.opacity(0.7), radius: 8)
                .animation(.spring(response: 1.4, dampingFraction: 0.65).delay(0.15), value: animatedProgress)
            // Label
            VStack(spacing: 1) {
                Text("\(value)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("score")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.38))
                    .kerning(0.8)
            }
        }
        .onAppear { animatedProgress = progress }
        .onChange(of: value) { _, _ in animatedProgress = progress }
    }
}

// MARK: - Streak Dots
struct StreakDots: View {
    let filled: Int
    let total: Int = 7
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < filled ? Color(hex: "#F5A623") : Color.white.opacity(0.12))
                    .frame(width: 20, height: 5)
                    .animation(.spring(response: 0.4).delay(Double(i) * 0.04), value: filled)
            }
        }
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let momentum: Int
    let streak: Int
    let tasksCompleted: Int
    let tasksTotal: Int

    private var taskProgress: CGFloat {
        tasksTotal > 0 ? CGFloat(tasksCompleted) / CGFloat(tasksTotal) : 0
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {

            // ── Momentum Ring ──
            VStack(spacing: 10) {
                MomentumRing(value: momentum)
                Text("Momentum")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.38))
                    .kerning(0.4)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 90)

            // ── Stats Column ──
            VStack(alignment: .leading, spacing: 18) {

                // Streak
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("🔥")
                            .font(.system(size: 18))
                        Text("\(streak)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("day streak")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .offset(y: -1)
                    }
                    StreakDots(filled: min(streak, 7))
                }

                // Tasks progress
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(tasksCompleted)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("/ \(tasksTotal)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                        Spacer()
                        Text("tasks")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.35))
                            .kerning(0.4)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08)).frame(height: 7)
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#F5A623"), Color(hex: "#FF6B6B")],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: geo.size.width * taskProgress, height: 7)
                                .animation(.spring(response: 1.1, dampingFraction: 0.72).delay(0.4), value: taskProgress)
                        }
                    }
                    .frame(height: 7)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 22)
            .padding(.trailing, 20)
        }
        .padding(.vertical, 26)
        .liquidGlass(cornerRadius: 26)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(hex: "#08070A").ignoresSafeArea()
        StatsCard(momentum: 77, streak: 14, tasksCompleted: 2, tasksTotal: 6)
            .padding(.horizontal, 20)
    }
}
