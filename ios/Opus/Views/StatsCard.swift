import SwiftUI

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
            // Track
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 6)
                .frame(width: 64, height: 64)

            // Progress
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [ringColor, ringColor.opacity(0.5)]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))
                .animation(
                    .spring(response: 1.2, dampingFraction: 0.7).delay(0.3),
                    value: animatedProgress
                )

            // Value label
            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: value) { _, _ in
            animatedProgress = progress
        }
    }
}

// MARK: - Streak Dots
struct StreakDots: View {
    let count: Int = 8

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i < 7 ? Color(hex: "#F5A623") : Color.white.opacity(0.15))
                    .frame(width: 6, height: 6)
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

            // ── Momentum ──
            VStack(spacing: 6) {
                MomentumRing(value: momentum)
                Text("Momentum")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 56)

            // ── Streak ──
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 20))
                    Text("\(streak)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Text("day streak")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
                StreakDots()
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 56)

            // ── Tasks ──
            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(tasksCompleted)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("of \(tasksTotal)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                }
                Text("today")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 4)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#F5A623"), Color(hex: "#FF6B6B")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * taskProgress, height: 4)
                            .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.4), value: taskProgress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 20, x: 0, y: 8)
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(hex: "#08070A").ignoresSafeArea()
        StatsCard(momentum: 77, streak: 14, tasksCompleted: 1, tasksTotal: 6)
            .padding(.horizontal, 20)
    }
}
