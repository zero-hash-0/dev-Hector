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
                            colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.55), radius: 24, x: 0, y: 12)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: CGFloat { CGFloat(value) / CGFloat(maxValue) }

    var body: some View {
        ZStack {
            // Outer glow halo
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "#8A4AF3").opacity(0.35), Color(hex: "#6E6BF5").opacity(0.08)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 20
                )
                .frame(width: 114, height: 114)
                .blur(radius: 8)

            // Track
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 12)
                .frame(width: 114, height: 114)

            // Progress arc — violet gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(hex: "#6E6BF5").opacity(0.65), location: 0),
                            .init(color: Color(hex: "#8A4AF3"),               location: 0.45),
                            .init(color: Color(hex: "#A78BFA"),               location: 1)
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 114, height: 114)
                .rotationEffect(.degrees(-90))
                .shadow(color: Color(hex: "#8A4AF3").opacity(0.85), radius: 12)
                .animation(
                    reduceMotion ? .none : .spring(response: 1.4, dampingFraction: 0.65).delay(0.15),
                    value: animatedProgress
                )

            // Center label
            VStack(spacing: 1) {
                Text("\(value)")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.82)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                Text("score")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.28))
                    .kerning(1.4)
            }
        }
        .onAppear {
            if reduceMotion { animatedProgress = progress }
            else { DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { animatedProgress = progress } }
        }
        .onChange(of: value) { _, _ in animatedProgress = progress }
    }
}

// MARK: - Streak Heatmap (GitHub-style 7×7 grid)
struct StreakHeatmap: View {
    let activeDays: Int
    private let weeks = 7
    private let daysPerWeek = 7

    private func intensity(week: Int, day: Int) -> Double {
        let total      = weeks * daysPerWeek          // 49 cells
        let idx        = week * daysPerWeek + day     // 0 = oldest column, top row
        let fromEnd    = total - 1 - idx              // 0 = most recent cell
        guard fromEnd < activeDays else { return 0 }
        if fromEnd < 7  { return 1.00 }
        if fromEnd < 14 { return 0.72 }
        if fromEnd < 28 { return 0.45 }
        return 0.25
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<weeks, id: \.self) { week in
                VStack(spacing: 3) {
                    ForEach(0..<daysPerWeek, id: \.self) { day in
                        let lvl = intensity(week: week, day: day)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                lvl > 0
                                    ? Color(hex: "#8A4AF3").opacity(0.22 + lvl * 0.78)
                                    : Color.white.opacity(0.07)
                            )
                            .frame(width: 9, height: 9)
                            .animation(
                                .spring(response: 0.5).delay(Double(week * daysPerWeek + day) * 0.007),
                                value: activeDays
                            )
                    }
                }
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
            VStack(spacing: 8) {
                MomentumRing(value: momentum)
                Text("Momentum")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.28))
                    .kerning(0.6)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 1, height: 110)

            // ── Stats Column ──
            VStack(alignment: .leading, spacing: 16) {

                // Streak row
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("🔥")
                            .font(.system(size: 18))
                        Text("\(streak)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("day streak")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))
                            .offset(y: -1)
                    }
                    StreakHeatmap(activeDays: min(streak, 49))
                }

                // Tasks progress
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(tasksCompleted)")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("/ \(tasksTotal)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))
                        Spacer()
                        Text("tasks")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.28))
                            .kerning(0.5)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.07))
                                .frame(height: 6)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * taskProgress, height: 6)
                                .animation(
                                    .spring(response: 1.1, dampingFraction: 0.72).delay(0.4),
                                    value: taskProgress
                                )
                        }
                    }
                    .frame(height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 20)
            .padding(.trailing, 16)
        }
        .padding(.vertical, 24)
        .liquidGlass(cornerRadius: 26)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(hex: "#0D0D10").ignoresSafeArea()
        StatsCard(momentum: 77, streak: 14, tasksCompleted: 2, tasksTotal: 6)
            .padding(.horizontal, 20)
    }
}
