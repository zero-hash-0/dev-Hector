import WidgetKit
import SwiftUI

// MARK: - Shared suite
private let sharedSuite = "group.com.opus.betaapp"

// MARK: - Widget Entry
struct OpusEntry: TimelineEntry {
    let date:     Date
    let streak:   Int
    let momentum: Int
    let pending:  Int
    let total:    Int
    let topTasks: [WidgetTask]
    let userName: String
}

struct WidgetTask: Decodable, Identifiable {
    let id:          UUID
    let title:       String
    let isCompleted: Bool
    let category:    String   // raw string so we don't import the main model

    var categoryColor: Color {
        switch category {
        case "Work":     return Color(hex: "#F5A623")
        case "Side":     return Color(hex: "#A78BFA")
        case "Learn":    return Color(hex: "#34D399")
        case "Health":   return Color(hex: "#F87171")
        case "Personal": return Color(hex: "#60A5FA")
        default:         return Color(hex: "#8A4AF3")
        }
    }
}

// MARK: - Color helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Timeline Provider
struct OpusProvider: TimelineProvider {
    func placeholder(in context: Context) -> OpusEntry { sampleEntry() }
    func getSnapshot(in context: Context, completion: @escaping (OpusEntry) -> Void) { completion(entry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<OpusEntry>) -> Void) {
        let next = Calendar.current.date(byAdding: .minute, value: 20, to: .now)!
        completion(Timeline(entries: [entry()], policy: .after(next)))
    }

    private func entry() -> OpusEntry {
        let d        = UserDefaults(suiteName: sharedSuite) ?? .standard
        let streak   = d.integer(forKey: "streak")
        let momentum = d.integer(forKey: "momentum")
        let userName = d.string(forKey: "userName") ?? ""

        var pending  = 0
        var total    = 0
        var top      = [WidgetTask]()

        if let data  = d.data(forKey: "todayTasks_v1"),
           let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data) {
            total   = tasks.count
            let open = tasks.filter { !$0.isCompleted }
            pending = open.count
            top     = Array(open.prefix(3))
        }
        return OpusEntry(date: .now, streak: streak, momentum: momentum,
                         pending: pending, total: total, topTasks: top, userName: userName)
    }

    private func sampleEntry() -> OpusEntry {
        OpusEntry(date: .now, streak: 7, momentum: 74, pending: 3, total: 6,
                  topTasks: [
                    WidgetTask(id: UUID(), title: "Write proposal draft",  isCompleted: false, category: "Work"),
                    WidgetTask(id: UUID(), title: "Update portfolio",       isCompleted: false, category: "Side"),
                    WidgetTask(id: UUID(), title: "Read chapter 4",         isCompleted: false, category: "Learn"),
                  ],
                  userName: "Hector")
    }
}

// MARK: - Mood palette based on momentum
private func moodPalette(momentum: Int, pending: Int) -> (primary: Color, secondary: Color, glow: Color) {
    if pending == 0 {
        return (.init(hex: "#34D399"), .init(hex: "#10B981"), .init(hex: "#34D399"))
    }
    if momentum >= 75 {
        return (.init(hex: "#A78BFA"), .init(hex: "#8A4AF3"), .init(hex: "#8A4AF3"))
    }
    if momentum >= 40 {
        return (.init(hex: "#6E6BF5"), .init(hex: "#8A4AF3"), .init(hex: "#6E6BF5"))
    }
    return (.init(hex: "#60A5FA"), .init(hex: "#3B82F6"), .init(hex: "#60A5FA"))
}

// MARK: - Streak flame dots
private struct FlameTrail: View {
    let streak: Int
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<min(streak, 7), id: \.self) { i in
                let brightness = Double(i + 1) / Double(min(streak, 7))
                Circle()
                    .fill(Color(hex: "#F59E0B").opacity(0.35 + brightness * 0.55))
                    .frame(width: 4 + CGFloat(i) * 0.5, height: 4 + CGFloat(i) * 0.5)
            }
        }
    }
}

// MARK: - ─────────────── SMALL WIDGET ───────────────
struct SmallWidgetView: View {
    let entry: OpusEntry
    private var palette: (primary: Color, secondary: Color, glow: Color) {
        moodPalette(momentum: entry.momentum, pending: entry.pending)
    }
    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.total - entry.pending) / Double(entry.total)
    }

    var body: some View {
        ZStack {
            // Layered background
            Color(hex: "#080810")

            // Ambient blob behind arc
            Circle()
                .fill(palette.glow.opacity(0.22))
                .frame(width: 140, height: 140)
                .blur(radius: 32)
                .offset(x: 20, y: -10)

            // ── Arc progress ring ──
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 9)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(stops: [
                                .init(color: palette.primary.opacity(0.4), location: 0),
                                .init(color: palette.primary,              location: 0.5),
                                .init(color: palette.secondary.opacity(0.9), location: 1),
                            ]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: palette.glow.opacity(0.9), radius: 6)

                // Center content
                VStack(spacing: 1) {
                    Text(entry.pending == 0 ? "✓" : "\(entry.pending)")
                        .font(.system(size: entry.pending == 0 ? 28 : 30,
                                      weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [palette.primary, palette.secondary],
                                           startPoint: .top, endPoint: .bottom)
                        )
                    Text(entry.pending == 0 ? "done" : "left")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            .offset(y: -4)

            // ── Bottom strip: streak ──
            VStack {
                Spacer()
                HStack {
                    // Opus logo mark
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 18, height: 18)
                        Text("✓")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    HStack(spacing: 3) {
                        Text("🔥")
                            .font(.system(size: 11))
                        Text("\(entry.streak)")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }

            // ── Momentum micro bar at very bottom ──
            VStack {
                Spacer()
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.clear)
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [palette.primary.opacity(0.7), palette.secondary],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: g.size.width * CGFloat(entry.momentum) / 100, height: 2)
                    }
                }
                .frame(height: 2)
            }
        }
        .containerBackground(Color(hex: "#080810"), for: .widget)
    }
}

// MARK: - ─────────────── MEDIUM WIDGET ───────────────
struct MediumWidgetView: View {
    let entry: OpusEntry
    private var palette: (primary: Color, secondary: Color, glow: Color) {
        moodPalette(momentum: entry.momentum, pending: entry.pending)
    }
    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.total - entry.pending) / Double(entry.total)
    }
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: entry.date)
        let name = entry.userName.trimmingCharacters(in: .whitespaces).split(separator: " ").first.map(String.init) ?? ""
        switch h {
        case 0..<12:  return "Morning\(name.isEmpty ? "" : ", \(name)")."
        case 12..<17: return "Afternoon\(name.isEmpty ? "" : ", \(name)")."
        default:      return "Evening\(name.isEmpty ? "" : ", \(name)")."
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "#080810")

            // Ambient glow left
            Circle()
                .fill(palette.glow.opacity(0.18))
                .frame(width: 180, height: 180)
                .blur(radius: 50)
                .offset(x: -60, y: 0)

            HStack(spacing: 0) {

                // ── LEFT: ring + stats ──
                VStack(spacing: 8) {
                    // Greeting
                    Text(greeting)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.35))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 11)
                            .frame(width: 84, height: 84)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: palette.primary.opacity(0.5), location: 0),
                                        .init(color: palette.primary,              location: 0.6),
                                        .init(color: palette.secondary,            location: 1),
                                    ]),
                                    center: .center,
                                    startAngle: .degrees(-90),
                                    endAngle: .degrees(270)
                                ),
                                style: StrokeStyle(lineWidth: 11, lineCap: .round)
                            )
                            .frame(width: 84, height: 84)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: palette.glow.opacity(0.8), radius: 8)

                        VStack(spacing: 0) {
                            Text(entry.pending == 0 ? "✓" : "\(entry.pending)")
                                .font(.system(size: entry.pending == 0 ? 24 : 26,
                                              weight: .heavy, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(colors: [palette.primary, palette.secondary],
                                                   startPoint: .top, endPoint: .bottom)
                                )
                            Text(entry.pending == 0 ? "done!" : "tasks")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }

                    Spacer()

                    // Streak with flame trail
                    VStack(spacing: 3) {
                        FlameTrail(streak: entry.streak)
                        HStack(spacing: 3) {
                            Text("🔥")
                                .font(.system(size: 11))
                            Text("\(entry.streak)")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .frame(width: 120)
                .padding(14)

                // ── Divider ──
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, palette.primary.opacity(0.3), Color.clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 1)
                    .padding(.vertical, 12)

                // ── RIGHT: tasks ──
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("TODAY")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white.opacity(0.22))
                            .kerning(1.2)

                        Spacer()

                        // Opus logo
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 18, height: 18)
                            Text("✓")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 8)

                    if entry.topTasks.isEmpty {
                        Spacer()
                        VStack(spacing: 6) {
                            Text("🎉")
                                .font(.system(size: 28))
                            Text("All clear!")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(entry.topTasks) { task in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(task.categoryColor)
                                        .frame(width: 6, height: 6)
                                        .shadow(color: task.categoryColor.opacity(0.7), radius: 3)
                                    Text(task.title)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.80))
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 9)
                                .padding(.vertical, 7)
                                .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.04))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
                                        )
                                }
                            }

                            if entry.pending > 3 {
                                Text("+ \(entry.pending - 3) more task\(entry.pending - 3 > 1 ? "s" : "")")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.25))
                                    .padding(.leading, 8)
                            }
                        }
                        Spacer()
                    }

                    // Momentum bar at bottom
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Momentum")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.22))
                            Spacer()
                            Text("\(entry.momentum)%")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(palette.primary.opacity(0.7))
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.06))
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [palette.primary, palette.secondary],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                                    .frame(width: g.size.width * CGFloat(entry.momentum) / 100)
                                    .shadow(color: palette.glow.opacity(0.6), radius: 3)
                            }
                        }
                        .frame(height: 4)
                    }
                }
                .padding(14)
            }

            // Thin top accent line
            VStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, palette.primary.opacity(0.6), Color.clear],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                Spacer()
            }
        }
        .containerBackground(Color(hex: "#080810"), for: .widget)
    }
}

// MARK: - Lock Screen Views
struct AccessoryCircularView: View {
    let entry: OpusEntry
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("🔥")
                    .font(.system(size: 16))
                Text("\(entry.streak)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

struct AccessoryRectangularView: View {
    let entry: OpusEntry
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("Opus")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.white)
                    Text("·")
                        .foregroundColor(.white.opacity(0.3))
                    Text("\(entry.pending) left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                if let first = entry.topTasks.first {
                    Text(first.title)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                } else {
                    Text("All tasks complete 🎉")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            Spacer()
            VStack(spacing: 1) {
                Text("🔥")
                    .font(.system(size: 13))
                Text("\(entry.streak)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Widget Bundle
@main
struct OpusWidgetBundle: WidgetBundle {
    var body: some Widget {
        OpusHomeWidget()
        OpusLockWidget()
    }
}

struct OpusHomeWidget: Widget {
    let kind = "OpusHomeWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OpusProvider()) { entry in
            OpusHomeWidgetView(entry: entry)
        }
        .configurationDisplayName("Opus")
        .description("Tasks and streak — live on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

struct OpusHomeWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: OpusEntry
    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

struct OpusLockWidget: Widget {
    let kind = "OpusLockWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OpusProvider()) { entry in
            OpusLockWidgetView(entry: entry)
        }
        .configurationDisplayName("Opus")
        .description("Streak and tasks on your lock screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

struct OpusLockWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: OpusEntry
    var body: some View {
        switch family {
        case .accessoryCircular:    AccessoryCircularView(entry: entry)
        case .accessoryRectangular: AccessoryRectangularView(entry: entry)
        default:                    AccessoryCircularView(entry: entry)
        }
    }
}
