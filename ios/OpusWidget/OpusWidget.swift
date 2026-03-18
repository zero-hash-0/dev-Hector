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
    let category:    String

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
    func getSnapshot(in context: Context, completion: @escaping (OpusEntry) -> Void) { completion(sampleEntry()) }
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
            total    = tasks.count
            let open = tasks.filter { !$0.isCompleted }
            pending  = open.count
            top      = Array(open.prefix(3))
        }
        return OpusEntry(date: .now, streak: streak, momentum: momentum,
                         pending: pending, total: total, topTasks: top, userName: userName)
    }

    func sampleEntry() -> OpusEntry {
        OpusEntry(date: .now, streak: 12, momentum: 82, pending: 2, total: 5,
                  topTasks: [
                    WidgetTask(id: UUID(), title: "Finish design review",  isCompleted: false, category: "Work"),
                    WidgetTask(id: UUID(), title: "Update portfolio site",  isCompleted: false, category: "Side"),
                    WidgetTask(id: UUID(), title: "Read for 20 min",        isCompleted: false, category: "Learn"),
                  ],
                  userName: "Hector")
    }
}

// MARK: - Mood palette
private func moodPalette(momentum: Int, pending: Int) -> (a: Color, b: Color, glow: Color) {
    if pending == 0 {
        return (.init(hex: "#34D399"), .init(hex: "#059669"), .init(hex: "#34D399"))
    }
    if momentum >= 75 {
        return (.init(hex: "#C084FC"), .init(hex: "#8A4AF3"), .init(hex: "#A855F7"))
    }
    if momentum >= 40 {
        return (.init(hex: "#818CF8"), .init(hex: "#6366F1"), .init(hex: "#6E6BF5"))
    }
    return (.init(hex: "#60A5FA"), .init(hex: "#3B82F6"), .init(hex: "#60A5FA"))
}

// MARK: - Glowing tip dot at ring progress end
private struct RingTipDot: View {
    let progress: Double
    let radius: CGFloat
    let color: Color
    var body: some View {
        let angle = (progress * 360 - 90) * .pi / 180
        let x = cos(angle) * radius
        let y = sin(angle) * radius
        return Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .shadow(color: color, radius: 5)
            .shadow(color: color.opacity(0.4), radius: 10)
            .offset(x: x, y: y)
            .opacity(progress > 0.02 ? 1 : 0)
    }
}

// MARK: - Opus logo mark
private struct OpusMark: View {
    var size: CGFloat = 20
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(LinearGradient(
                    colors: [Color(hex: "#7C6BF5"), Color(hex: "#8A4AF3")],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
            Text("✓")
                .font(.system(size: size * 0.48, weight: .black))
                .foregroundColor(.white)
        }
    }
}

// MARK: - SMALL WIDGET
struct SmallWidgetView: View {
    let entry: OpusEntry
    private var pal: (a: Color, b: Color, glow: Color) { moodPalette(momentum: entry.momentum, pending: entry.pending) }
    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.total - entry.pending) / Double(entry.total)
    }

    var body: some View {
        ZStack {
            Color(hex: "#07070F")

            // Radial glow bloom
            RadialGradient(colors: [pal.glow.opacity(0.32), Color.clear],
                           center: .center, startRadius: 10, endRadius: 90)

            // Corner wash
            LinearGradient(colors: [pal.a.opacity(0.1), Color.clear],
                           startPoint: .topLeading, endPoint: .bottomTrailing)

            VStack(spacing: 0) {
                Spacer()

                // Ring
                ZStack {
                    Circle().stroke(Color.white.opacity(0.06), lineWidth: 11)
                        .frame(width: 98, height: 98)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(colors: [pal.a.opacity(0.5), pal.a, pal.b],
                                            center: .center,
                                            startAngle: .degrees(-90), endAngle: .degrees(270)),
                            style: StrokeStyle(lineWidth: 11, lineCap: .round))
                        .frame(width: 98, height: 98)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: pal.glow.opacity(0.9), radius: 8)

                    RingTipDot(progress: progress, radius: 49, color: pal.a)

                    VStack(spacing: 2) {
                        if entry.pending == 0 {
                            Text("✓")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(LinearGradient(colors: [pal.a, pal.b],
                                                                startPoint: .top, endPoint: .bottom))
                        } else {
                            Text("\(entry.pending)")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(LinearGradient(colors: [pal.a, pal.b],
                                                                startPoint: .top, endPoint: .bottom))
                            Text(entry.pending == 1 ? "task left" : "tasks left")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                                .kerning(0.4)
                        }
                    }
                }

                Spacer()

                // Bottom row
                HStack {
                    OpusMark(size: 18)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 12))
                        Text("\(entry.streak)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                }
                .padding(.horizontal, 13)
                .padding(.bottom, 12)
            }

            // Top glow line
            VStack {
                LinearGradient(colors: [Color.clear, pal.a.opacity(0.5), Color.clear],
                               startPoint: .leading, endPoint: .trailing).frame(height: 1)
                Spacer()
            }

            // Bottom momentum line
            VStack {
                Spacer()
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.clear)
                        Rectangle()
                            .fill(LinearGradient(colors: [pal.a, pal.b],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: g.size.width * CGFloat(entry.momentum) / 100, height: 2)
                            .shadow(color: pal.glow.opacity(0.9), radius: 4)
                    }
                }
                .frame(height: 2)
            }
        }
        .containerBackground(Color(hex: "#07070F"), for: .widget)
    }
}

// MARK: - MEDIUM WIDGET
struct MediumWidgetView: View {
    let entry: OpusEntry
    private var pal: (a: Color, b: Color, glow: Color) { moodPalette(momentum: entry.momentum, pending: entry.pending) }
    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.total - entry.pending) / Double(entry.total)
    }
    private var greeting: String {
        let h    = Calendar.current.component(.hour, from: entry.date)
        let name = entry.userName.split(separator: " ").first.map(String.init) ?? ""
        let pre: String
        switch h {
        case 0..<12: pre = "Morning"
        case 12..<17: pre = "Afternoon"
        default: pre = "Evening"
        }
        return name.isEmpty ? pre : "\(pre), \(name)."
    }

    var body: some View {
        ZStack {
            Color(hex: "#07070F")
            RadialGradient(colors: [pal.glow.opacity(0.18), Color.clear],
                           center: UnitPoint(x: 0.15, y: 0.5),
                           startRadius: 5, endRadius: 160)

            HStack(spacing: 0) {

                // LEFT: ring + streak
                VStack(alignment: .leading, spacing: 0) {
                    Text(greeting)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                        .lineLimit(1)

                    Spacer()

                    ZStack {
                        Circle().stroke(Color.white.opacity(0.07), lineWidth: 12)
                            .frame(width: 82, height: 82)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                AngularGradient(colors: [pal.a.opacity(0.4), pal.a, pal.b],
                                                center: .center,
                                                startAngle: .degrees(-90), endAngle: .degrees(270)),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 82, height: 82)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: pal.glow.opacity(0.9), radius: 8)
                        RingTipDot(progress: progress, radius: 41, color: pal.a)
                        VStack(spacing: 1) {
                            Text(entry.pending == 0 ? "✓" : "\(entry.total - entry.pending)")
                                .font(.system(size: entry.pending == 0 ? 26 : 24,
                                              weight: .black, design: .rounded))
                                .foregroundStyle(LinearGradient(colors: [pal.a, pal.b],
                                                                startPoint: .top, endPoint: .bottom))
                            Text(entry.pending == 0 ? "done!" : "of \(entry.total)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white.opacity(0.28))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    Spacer()

                    HStack(spacing: 5) {
                        Text("🔥").font(.system(size: 13))
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(entry.streak)")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text("streak")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.white.opacity(0.26))
                                .kerning(0.3)
                        }
                    }
                }
                .padding(14)
                .frame(width: 118)

                // Divider
                Rectangle()
                    .fill(LinearGradient(colors: [Color.clear, pal.a.opacity(0.22), Color.clear],
                                        startPoint: .top, endPoint: .bottom))
                    .frame(width: 1).padding(.vertical, 14)

                // RIGHT: tasks
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        HStack(spacing: 5) {
                            Circle().fill(pal.a).frame(width: 5, height: 5)
                                .shadow(color: pal.glow, radius: 3)
                            Text("TODAY")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(.white.opacity(0.28))
                                .kerning(1.2)
                        }
                        Spacer()
                        OpusMark(size: 17)
                    }
                    .padding(.bottom, 8)

                    if entry.topTasks.isEmpty {
                        Spacer()
                        VStack(spacing: 5) {
                            Text("🎉").font(.system(size: 26))
                            Text("All done!").font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.45))
                            Text("Streak kept 🔥")
                                .font(.system(size: 9)).foregroundColor(pal.a.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(entry.topTasks) { task in
                                HStack(spacing: 10) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(task.categoryColor)
                                        .frame(width: 3, height: 30)
                                        .shadow(color: task.categoryColor.opacity(0.9), radius: 3)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(task.title)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.88))
                                            .lineLimit(1)
                                        Text(task.category)
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(task.categoryColor.opacity(0.7))
                                    }
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                        .frame(width: 18, height: 18)
                                }
                                .padding(.horizontal, 9).padding(.vertical, 5)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.07), lineWidth: 0.5))
                            }
                            if entry.pending > 3 {
                                Text("+ \(entry.pending - 3) more")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white.opacity(0.2))
                                    .padding(.leading, 4)
                            }
                        }
                        Spacer()
                    }

                    // Momentum bar
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Momentum").font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.white.opacity(0.2))
                            Spacer()
                            Text("\(entry.momentum)%").font(.system(size: 8, weight: .black))
                                .foregroundColor(pal.a.opacity(0.8))
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.05))
                                Capsule()
                                    .fill(LinearGradient(colors: [pal.a, pal.b],
                                                         startPoint: .leading, endPoint: .trailing))
                                    .frame(width: g.size.width * CGFloat(entry.momentum) / 100)
                                    .shadow(color: pal.glow.opacity(0.7), radius: 3)
                            }
                        }
                        .frame(height: 4).clipShape(Capsule())
                    }
                }
                .padding(13)
            }

            // Top glow line
            VStack {
                LinearGradient(colors: [Color.clear, pal.a.opacity(0.4), Color.clear],
                               startPoint: .leading, endPoint: .trailing).frame(height: 1)
                Spacer()
            }
        }
        .containerBackground(Color(hex: "#07070F"), for: .widget)
    }
}

// MARK: - LARGE WIDGET
struct LargeWidgetView: View {
    let entry: OpusEntry
    private var pal: (a: Color, b: Color, glow: Color) { moodPalette(momentum: entry.momentum, pending: entry.pending) }
    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.total - entry.pending) / Double(entry.total)
    }
    private var greeting: String {
        let h    = Calendar.current.component(.hour, from: entry.date)
        let name = entry.userName.split(separator: " ").first.map(String.init) ?? ""
        switch h {
        case 0..<12: return "Good morning\(name.isEmpty ? "" : ", \(name)")."
        case 12..<17: return "Good afternoon\(name.isEmpty ? "" : ", \(name)")."
        default: return "Good evening\(name.isEmpty ? "" : ", \(name)")."
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "#07070F")
            RadialGradient(colors: [pal.glow.opacity(0.22), Color.clear],
                           center: UnitPoint(x: 0.5, y: 0.2),
                           startRadius: 10, endRadius: 220)

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.75))
                        Text(entry.pending == 0
                             ? "All tasks complete today 🎉"
                             : "\(entry.pending) task\(entry.pending == 1 ? "" : "s") remaining")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.32))
                    }
                    Spacer()
                    OpusMark(size: 30)
                }
                .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 14)

                // Big ring
                ZStack {
                    Circle().stroke(Color.white.opacity(0.06), lineWidth: 14)
                        .frame(width: 130, height: 130)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(colors: [pal.a.opacity(0.4), pal.a, pal.b],
                                            center: .center,
                                            startAngle: .degrees(-90), endAngle: .degrees(270)),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: pal.glow, radius: 14)
                    RingTipDot(progress: progress, radius: 65, color: pal.a)
                    VStack(spacing: 3) {
                        Text(entry.pending == 0 ? "✓" : "\(entry.total - entry.pending)")
                            .font(.system(size: entry.pending == 0 ? 44 : 40,
                                          weight: .black, design: .rounded))
                            .foregroundStyle(LinearGradient(colors: [pal.a, pal.b],
                                                            startPoint: .top, endPoint: .bottom))
                        Text(entry.pending == 0 ? "all done" : "of \(entry.total) done")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.26))
                    }
                }
                .padding(.bottom, 16)

                // Stats row
                HStack(spacing: 10) {
                    statPill(emoji: "🔥", value: "\(entry.streak)", label: "streak")
                    statPill(emoji: "⚡️", value: "\(entry.momentum)%", label: "momentum")
                    statPill(emoji: "✅", value: "\(entry.total - entry.pending)/\(entry.total)", label: "done")
                }
                .padding(.horizontal, 16).padding(.bottom, 14)

                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1).padding(.horizontal, 16)

                // Task list
                VStack(alignment: .leading, spacing: 6) {
                    Text("UP NEXT")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.white.opacity(0.2))
                        .kerning(1.5)
                        .padding(.top, 12)

                    if entry.topTasks.isEmpty {
                        HStack { Spacer()
                            Text("Nothing left — great work! 🏆")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.3))
                            Spacer() }
                        .padding(.vertical, 12)
                    } else {
                        ForEach(entry.topTasks) { task in
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(task.categoryColor)
                                    .frame(width: 3, height: 32)
                                    .shadow(color: task.categoryColor.opacity(0.9), radius: 4)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.88)).lineLimit(1)
                                    Text(task.category)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(task.categoryColor.opacity(0.7))
                                }
                                Spacer()
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    .frame(width: 20, height: 20)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(Color.white.opacity(0.035))
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                            .overlay(RoundedRectangle(cornerRadius: 11)
                                .stroke(Color.white.opacity(0.06), lineWidth: 0.5))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.bottom, 16)
            }

            // Top glow
            VStack {
                LinearGradient(colors: [Color.clear, pal.a.opacity(0.45), Color.clear],
                               startPoint: .leading, endPoint: .trailing).frame(height: 1)
                Spacer()
            }
        }
        .containerBackground(Color(hex: "#07070F"), for: .widget)
    }

    private func statPill(emoji: String, value: String, label: String) -> some View {
        let pal = moodPalette(momentum: entry.momentum, pending: entry.pending)
        return VStack(spacing: 3) {
            Text(emoji).font(.system(size: 16))
            Text(value).font(.system(size: 15, weight: .black, design: .rounded)).foregroundColor(.white)
            Text(label).font(.system(size: 8, weight: .semibold)).foregroundColor(.white.opacity(0.24)).kerning(0.3)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(pal.a.opacity(0.16), lineWidth: 1))
    }
}

// MARK: - Lock Screen
struct AccessoryCircularView: View {
    let entry: OpusEntry
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("🔥").font(.system(size: 16))
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
                    Text("Opus").font(.system(size: 13, weight: .black)).foregroundColor(.white)
                    Text("·").foregroundColor(.white.opacity(0.3))
                    Text("\(entry.pending) left")
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                }
                if let first = entry.topTasks.first {
                    Text(first.title).font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5)).lineLimit(1)
                } else {
                    Text("All tasks complete 🎉").font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            Spacer()
            VStack(spacing: 1) {
                Text("🔥").font(.system(size: 13))
                Text("\(entry.streak)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundColor(.white)
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
        case .systemLarge:  LargeWidgetView(entry: entry)
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
