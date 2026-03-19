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

// MARK: - Streak Heatmap (kept for ProfileView)
struct StreakHeatmap: View {
    let activeDays: Int
    private let weeks = 7
    private let daysPerWeek = 7

    private func intensity(week: Int, day: Int) -> Double {
        let total   = weeks * daysPerWeek
        let idx     = week * daysPerWeek + day
        let fromEnd = total - 1 - idx
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
                            .fill(lvl > 0
                                  ? Color(hex: "#8A4AF3").opacity(0.22 + lvl * 0.78)
                                  : Color.white.opacity(0.07))
                            .frame(width: 9, height: 9)
                    }
                }
            }
        }
    }
}

// MARK: - Week Completion Bars (Mon–Sun)
struct WeekBars: View {
    let history: [HistoryEntry]
    let todayCount: Int
    let accentColor: Color

    private struct DayData: Identifiable {
        let id: String
        let label: String
        let count: Int
        let isToday: Bool
    }

    private var days: [DayData] {
        let cal     = Calendar.current
        let isoFmt  = ISO8601DateFormatter(); isoFmt.formatOptions = [.withFullDate]
        let lblFmt  = DateFormatter();        lblFmt.dateFormat = "EEEEE"
        return (0..<7).reversed().map { offset -> DayData in
            let date    = cal.date(byAdding: .day, value: -offset, to: Date())!
            let dateStr = isoFmt.string(from: date)
            let isToday = offset == 0
            let count   = isToday
                ? todayCount
                : (history.first(where: { $0.date == dateStr })?.tasks.count ?? 0)
            return DayData(id: dateStr, label: lblFmt.string(from: date), count: count, isToday: isToday)
        }
    }

    var body: some View {
        let maxCount = max(days.map(\.count).max() ?? 0, 1)
        VStack(alignment: .leading, spacing: 6) {
            Text("WEEK")
                .font(.system(size: 7, weight: .black))
                .foregroundColor(.white.opacity(0.22))
                .kerning(1.2)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(days) { day in
                    VStack(spacing: 3) {
                        GeometryReader { geo in
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        day.isToday
                                        ? LinearGradient(colors: [accentColor.opacity(0.55), accentColor],
                                                         startPoint: .bottom, endPoint: .top)
                                        : LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.20)],
                                                         startPoint: .bottom, endPoint: .top)
                                    )
                                    .frame(height: max(3, geo.size.height * CGFloat(day.count) / CGFloat(maxCount)))
                                    .shadow(color: day.isToday ? accentColor.opacity(0.7) : .clear, radius: 5)
                            }
                        }
                        Text(day.label)
                            .font(.system(size: 7, weight: day.isToday ? .black : .medium))
                            .foregroundColor(day.isToday ? accentColor : .white.opacity(0.22))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 40)
        }
    }
}

// MARK: - ECG Pulse Line (animated momentum heartbeat)
struct PulseLine: View {
    let momentum: Int
    let color: Color

    private func ecgY(t: CGFloat, amplitude: CGFloat, midY: CGFloat) -> CGFloat {
        let t = ((t.truncatingRemainder(dividingBy: 1.0)) + 1.0).truncatingRemainder(dividingBy: 1.0)
        switch t {
        case 0.00..<0.18: return midY
        case 0.18..<0.28:
            let u = (t - 0.18) / 0.10
            return midY - amplitude * 0.20 * sin(u * .pi)
        case 0.28..<0.36: return midY
        case 0.36..<0.39:
            let u = (t - 0.36) / 0.03
            return midY + amplitude * 0.14 * u
        case 0.39..<0.43:
            let u = (t - 0.39) / 0.04
            return midY + amplitude * 0.14 - amplitude * 1.14 * u
        case 0.43..<0.47:
            let u = (t - 0.43) / 0.04
            return midY - amplitude + amplitude * 1.28 * u
        case 0.47..<0.50:
            let u = (t - 0.47) / 0.03
            return midY + amplitude * 0.28 - amplitude * 0.28 * u
        case 0.50..<0.68:
            let u = (t - 0.50) / 0.18
            return midY - amplitude * 0.32 * sin(u * .pi)
        default: return midY
        }
    }

    private func makePath(size: CGSize, phaseOffset: CGFloat) -> Path {
        let amplitude = max(2, CGFloat(momentum) / 100.0 * size.height * 0.44)
        let midY      = size.height / 2
        let cycles: CGFloat = 2.5
        var path = Path()
        for i in 0...Int(size.width) {
            let x = CGFloat(i)
            let t = x / size.width * cycles + phaseOffset
            let y = ecgY(t: t, amplitude: amplitude, midY: midY)
            i == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
        }
        return path
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PULSE")
                .font(.system(size: 7, weight: .black))
                .foregroundColor(.white.opacity(0.22))
                .kerning(1.2)
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
                let p = CGFloat(tl.date.timeIntervalSinceReferenceDate) * 0.18
                Canvas { ctx, size in
                    let path = makePath(size: size, phaseOffset: -p)
                    // Outer glow
                    ctx.stroke(path, with: .color(color.opacity(0.30)), lineWidth: 5)
                    // Main line
                    ctx.stroke(path, with: .color(color.opacity(0.90)), lineWidth: 1.5)
                    // Glowing dot at lead edge
                    let amp    = max(2, CGFloat(momentum) / 100.0 * size.height * 0.44)
                    let dotX   = size.width * 0.82
                    let dotT   = dotX / size.width * 2.5 + (-p)
                    let dotY   = ecgY(t: dotT, amplitude: amp, midY: size.height / 2)
                    let dot    = CGRect(x: dotX - 3.5, y: dotY - 3.5, width: 7, height: 7)
                    ctx.fill(Path(ellipseIn: dot), with: .color(color))
                    let halo   = CGRect(x: dotX - 6, y: dotY - 6, width: 12, height: 12)
                    ctx.fill(Path(ellipseIn: halo), with: .color(color.opacity(0.30)))
                }
            }
            .frame(height: 40)
        }
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let momentum: Int
    let streak: Int
    let tasksCompleted: Int
    let tasksTotal: Int
    let history: [HistoryEntry]

    private var taskProgress: CGFloat {
        tasksTotal > 0 ? CGFloat(tasksCompleted) / CGFloat(tasksTotal) : 0
    }

    private var moodTag: (label: String, emoji: String, color: Color) {
        switch momentum {
        case 80...100: return ("On fire",     "🔥", Color(hex: "#F97316"))
        case 60..<80:  return ("Crushing it", "⚡", Color(hex: "#A78BFA"))
        case 40..<60:  return ("Building up", "💪", Color(hex: "#60A5FA"))
        case 20..<40:  return ("Warming up",  "🌱", Color(hex: "#34D399"))
        default:       return ("Let's go",    "🎯", Color(hex: "#8A4AF3"))
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Top: Ring + Stats ──
            HStack(alignment: .center, spacing: 0) {

                // Left: Momentum Ring + mood tag
                VStack(spacing: 8) {
                    MomentumRing(value: momentum)

                    HStack(spacing: 4) {
                        Text(moodTag.emoji).font(.system(size: 9))
                        Text(moodTag.label.uppercased())
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(moodTag.color)
                            .kerning(0.7)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(moodTag.color.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(moodTag.color.opacity(0.25), lineWidth: 0.5))
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 1, height: 120)

                // Right: Streak + task progress
                VStack(alignment: .leading, spacing: 16) {

                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("🔥").font(.system(size: 18))
                        Text("\(streak)")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("day streak")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))
                            .offset(y: -1)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(tasksCompleted)")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
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
                                Capsule().fill(Color.white.opacity(0.07)).frame(height: 6)
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                        startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * taskProgress, height: 6)
                                    .animation(.spring(response: 1.1, dampingFraction: 0.72).delay(0.4),
                                               value: taskProgress)
                            }
                        }
                        .frame(height: 6)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.leading, 20).padding(.trailing, 16)
            }
            .padding(.vertical, 22)

            // ── Bottom: Week Bars + Pulse Line ──
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 16)

            HStack(alignment: .top, spacing: 0) {
                WeekBars(
                    history: history,
                    todayCount: tasksCompleted,
                    accentColor: moodTag.color
                )
                .frame(maxWidth: .infinity)
                .padding(.leading, 18).padding(.trailing, 10)

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1)
                    .padding(.vertical, 4)

                PulseLine(momentum: momentum, color: moodTag.color)
                    .frame(maxWidth: .infinity)
                    .padding(.leading, 10).padding(.trailing, 18)
            }
            .padding(.vertical, 14)
        }
        .background {
            RoundedRectangle(cornerRadius: 26)
                .fill(Color(hex: "#0F0A1F"))
                .overlay(alignment: .topLeading) {
                    // Purple ambient bloom behind momentum ring
                    Ellipse()
                        .fill(Color(hex: "#6E6BF5").opacity(0.18))
                        .frame(width: 180, height: 140)
                        .blur(radius: 44)
                        .offset(x: -20, y: -20)
                        .allowsHitTesting(false)
                }
                .overlay {
                    // Top-heavy gradient border glow
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#A78BFA").opacity(0.70),
                                    Color(hex: "#6E6BF5").opacity(0.30),
                                    Color(hex: "#8A4AF3").opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color(hex: "#6E6BF5").opacity(0.22), radius: 32, x: 0, y: 10)
                .shadow(color: .black.opacity(0.65), radius: 18, x: 0, y: 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(hex: "#0D0D10").ignoresSafeArea()
        StatsCard(momentum: 77, streak: 14, tasksCompleted: 2, tasksTotal: 6, history: [])
            .padding(.horizontal, 20)
    }
}
