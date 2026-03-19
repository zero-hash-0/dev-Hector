import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared suite
private let sharedSuite = "group.com.opus.betaapp"

// MARK: - Widget Theme
enum WidgetTheme: String, AppEnum {
    case obsidian = "obsidian"
    case midnight = "midnight"
    case ember    = "ember"
    case forest   = "forest"
    case crimson  = "crimson"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Theme"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .obsidian: DisplayRepresentation(title: "Obsidian",  subtitle: "Deep black, classic Opus"),
        .midnight: DisplayRepresentation(title: "Midnight",  subtitle: "Deep navy with electric blue"),
        .ember:    DisplayRepresentation(title: "Ember",     subtitle: "Warm dark with fiery orange"),
        .forest:   DisplayRepresentation(title: "Forest",    subtitle: "Dark green with emerald glow"),
        .crimson:  DisplayRepresentation(title: "Crimson",   subtitle: "Deep red, bold and striking"),
    ]

    var background: Color {
        switch self {
        case .obsidian: return Color(hex: "#07070F")
        case .midnight: return Color(hex: "#050818")
        case .ember:    return Color(hex: "#120500")
        case .forest:   return Color(hex: "#030D07")
        case .crimson:  return Color(hex: "#0F0204")
        }
    }

    var palette: (a: Color, b: Color, glow: Color) {
        switch self {
        case .obsidian: return (Color(hex: "#C084FC"), Color(hex: "#8A4AF3"), Color(hex: "#A855F7"))
        case .midnight: return (Color(hex: "#60A5FA"), Color(hex: "#4F46E5"), Color(hex: "#6E6BF5"))
        case .ember:    return (Color(hex: "#FB923C"), Color(hex: "#DC2626"), Color(hex: "#F97316"))
        case .forest:   return (Color(hex: "#34D399"), Color(hex: "#059669"), Color(hex: "#10B981"))
        case .crimson:  return (Color(hex: "#F87171"), Color(hex: "#DC2626"), Color(hex: "#EF4444"))
        }
    }

    func moodPalette(momentum: Int, pending: Int) -> (a: Color, b: Color, glow: Color) {
        if pending == 0 {
            return (Color(hex: "#34D399"), Color(hex: "#059669"), Color(hex: "#34D399"))
        }
        return palette
    }
}

// MARK: - Widget Intent
struct OpusWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Widget Theme"
    static var description = IntentDescription("Choose your Opus widget style.")
    @Parameter(title: "Theme", default: .obsidian)
    var theme: WidgetTheme
}

// MARK: - Widget Entry
struct OpusEntry: TimelineEntry {
    let date:     Date
    let streak:   Int
    let momentum: Int
    let pending:  Int
    let total:    Int
    let topTasks: [WidgetTask]
    let userName: String
    let theme:    WidgetTheme
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
struct OpusProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> OpusEntry { sampleEntry(theme: .obsidian) }

    func snapshot(for configuration: OpusWidgetIntent, in context: Context) async -> OpusEntry {
        sampleEntry(theme: configuration.theme)
    }

    func timeline(for configuration: OpusWidgetIntent, in context: Context) async -> Timeline<OpusEntry> {
        let next = Calendar.current.date(byAdding: .minute, value: 20, to: .now)!
        return Timeline(entries: [entry(theme: configuration.theme)], policy: .after(next))
    }

    private func entry(theme: WidgetTheme) -> OpusEntry {
        let d        = UserDefaults(suiteName: sharedSuite) ?? .standard
        let streak   = d.integer(forKey: "streak")
        let momentum = d.integer(forKey: "momentum")
        let userName = d.string(forKey: "userName") ?? ""
        var pending  = 0; var total = 0; var top = [WidgetTask]()
        if let data  = d.data(forKey: "todayTasks_v1"),
           let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data) {
            total = tasks.count
            let open = tasks.filter { !$0.isCompleted }
            pending  = open.count
            top      = Array(open.prefix(4))
        }
        return OpusEntry(date: .now, streak: streak, momentum: momentum,
                         pending: pending, total: total, topTasks: top,
                         userName: userName, theme: theme)
    }

    func sampleEntry(theme: WidgetTheme) -> OpusEntry {
        OpusEntry(date: .now, streak: 12, momentum: 82, pending: 3, total: 6,
                  topTasks: [
                    WidgetTask(id: UUID(), title: "Finish design review",  isCompleted: false, category: "Work"),
                    WidgetTask(id: UUID(), title: "Update portfolio site",  isCompleted: false, category: "Side"),
                    WidgetTask(id: UUID(), title: "Read 20 min",            isCompleted: false, category: "Learn"),
                    WidgetTask(id: UUID(), title: "Evening workout",        isCompleted: false, category: "Health"),
                  ],
                  userName: "Hector", theme: theme)
    }
}

// MARK: - Shared Sub-views

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

private struct RingTipDot: View {
    let progress: Double; let radius: CGFloat; let color: Color
    var body: some View {
        let angle = (progress * 360 - 90) * .pi / 180
        return Circle().fill(color)
            .frame(width: 9, height: 9)
            .shadow(color: color, radius: 4)
            .offset(x: cos(angle) * radius, y: sin(angle) * radius)
            .opacity(progress > 0.02 ? 1 : 0)
    }
}

// Sleek task row for medium/large
private struct SlimTaskRow: View {
    let task: WidgetTask
    let accent: Color
    var body: some View {
        HStack(spacing: 10) {
            // Category color bar
            Capsule()
                .fill(task.categoryColor)
                .frame(width: 3, height: 22)
                .shadow(color: task.categoryColor.opacity(0.7), radius: 3)

            Text(task.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)

            Spacer(minLength: 0)

            // Checkbox
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(accent.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 18, height: 18)
                RoundedRectangle(cornerRadius: 5)
                    .fill(accent.opacity(0.07))
                    .frame(width: 18, height: 18)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: [task.categoryColor.opacity(0.22), Color.white.opacity(0.04)],
                                startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 0.75))
        }
    }
}

// MARK: - SMALL WIDGET — bold number hero
struct SmallWidgetView: View {
    let entry: OpusEntry
    private var pal: (a: Color, b: Color, glow: Color) {
        entry.theme.moodPalette(momentum: entry.momentum, pending: entry.pending)
    }
    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.total - entry.pending) / Double(entry.total)
    }
    private var dayLabel: String {
        let f = DateFormatter(); f.dateFormat = "EEE d"
        return f.string(from: entry.date).uppercased()
    }

    var body: some View {
        ZStack {
            // Background
            entry.theme.background

            // Diagonal corner glow
            LinearGradient(
                colors: [pal.glow.opacity(0.28), Color.clear],
                startPoint: .topLeading, endPoint: .bottomTrailing)

            // Radial bloom under number
            RadialGradient(
                colors: [pal.glow.opacity(0.40), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 0, endRadius: 70)

            VStack(alignment: .leading, spacing: 0) {
                // Top row
                HStack {
                    OpusMark(size: 20)
                    Spacer()
                    // Streak badge
                    HStack(spacing: 3) {
                        Text("🔥").font(.system(size: 11))
                        Text("\(entry.streak)")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(pal.a.opacity(0.30), lineWidth: 0.75))
                }

                Spacer()

                // Hero number
                if entry.pending == 0 {
                    Text("✓")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundStyle(LinearGradient(colors: [pal.a, pal.b],
                                                        startPoint: .top, endPoint: .bottom))
                        .shadow(color: pal.glow.opacity(0.6), radius: 16)
                    Text("All done!")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.50))
                } else {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text("\(entry.pending)")
                            .font(.system(size: 62, weight: .black, design: .rounded))
                            .foregroundStyle(LinearGradient(colors: [pal.a, pal.b],
                                                            startPoint: .top, endPoint: .bottom))
                            .shadow(color: pal.glow.opacity(0.55), radius: 14)
                        Text(entry.total > 0 ? "/\(entry.total)" : "")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.28))
                            .offset(y: -6)
                    }
                    Text(entry.pending == 1 ? "task left" : "tasks left")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.40))
                        .kerning(0.3)
                }

                Spacer()

                // Bottom: date + momentum bar
                VStack(alignment: .leading, spacing: 5) {
                    Text(dayLabel)
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white.opacity(0.20))
                        .kerning(1.0)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08)).frame(height: 3)
                            Capsule()
                                .fill(LinearGradient(colors: [pal.a, pal.b],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(width: g.size.width * CGFloat(entry.momentum) / 100, height: 3)
                                .shadow(color: pal.glow.opacity(0.9), radius: 3)
                        }
                    }
                    .frame(height: 3)
                }
            }
            .padding(14)

            // Top glint line
            VStack {
                LinearGradient(colors: [Color.clear, pal.a.opacity(0.55), Color.clear],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(height: 1)
                Spacer()
            }
        }
        .containerBackground(entry.theme.background, for: .widget)
    }
}

// MARK: - MEDIUM WIDGET — editorial layout
struct MediumWidgetView: View {
    let entry: OpusEntry
    private var pal: (a: Color, b: Color, glow: Color) {
        entry.theme.moodPalette(momentum: entry.momentum, pending: entry.pending)
    }
    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.total - entry.pending) / Double(entry.total)
    }
    private var firstName: String {
        entry.userName.split(separator: " ").first.map(String.init) ?? ""
    }
    private var timeGreeting: String {
        let h = Calendar.current.component(.hour, from: entry.date)
        switch h {
        case 0..<12: return "Morning"
        case 12..<17: return "Afternoon"
        default: return "Evening"
        }
    }
    private var momentumLabel: String {
        switch entry.momentum {
        case 80...100: return "On fire 🔥"
        case 60..<80:  return "Crushing it ⚡"
        case 40..<60:  return "Building up 💪"
        default:       return "Let's go 🎯"
        }
    }

    var body: some View {
        ZStack {
            entry.theme.background

            // Left-side glow bloom
            RadialGradient(colors: [pal.glow.opacity(0.30), Color.clear],
                           center: UnitPoint(x: 0.18, y: 0.5),
                           startRadius: 0, endRadius: 130)

            // Top glint
            VStack {
                LinearGradient(colors: [Color.clear, pal.a.opacity(0.50), Color.clear],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(height: 1)
                Spacer()
            }

            HStack(spacing: 0) {

                // ── LEFT: Big number hero ──
                VStack(alignment: .leading, spacing: 0) {

                    // Greeting
                    VStack(alignment: .leading, spacing: 1) {
                        Text(timeGreeting.uppercased())
                            .font(.system(size: 7.5, weight: .black))
                            .foregroundColor(pal.a.opacity(0.70))
                            .kerning(1.4)
                        if !firstName.isEmpty {
                            Text(firstName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }

                    Spacer()

                    // Hero count
                    if entry.pending == 0 {
                        Text("✓")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundStyle(LinearGradient(colors: [pal.a, pal.b],
                                                            startPoint: .top, endPoint: .bottom))
                            .shadow(color: pal.glow.opacity(0.6), radius: 14)
                        Text("all done!")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.45))
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(entry.pending)")
                                .font(.system(size: 56, weight: .black, design: .rounded))
                                .foregroundStyle(LinearGradient(colors: [pal.a, pal.b],
                                                                startPoint: .top, endPoint: .bottom))
                                .shadow(color: pal.glow.opacity(0.55), radius: 12)
                            Text("left of \(entry.total)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.35))
                        }
                    }

                    Spacer()

                    // Streak + momentum
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 5) {
                            Text("🔥")
                                .font(.system(size: 12))
                            Text("\(entry.streak) day streak")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.08)).frame(height: 3)
                                Capsule()
                                    .fill(LinearGradient(colors: [pal.a, pal.b],
                                                         startPoint: .leading, endPoint: .trailing))
                                    .frame(width: g.size.width * CGFloat(entry.momentum) / 100, height: 3)
                                    .shadow(color: pal.glow.opacity(0.8), radius: 3)
                            }
                        }
                        .frame(height: 3).clipShape(Capsule())
                    }
                }
                .padding(14)
                .frame(width: 140)

                // ── Divider ──
                Rectangle()
                    .fill(LinearGradient(colors: [Color.clear, pal.a.opacity(0.25), Color.clear],
                                        startPoint: .top, endPoint: .bottom))
                    .frame(width: 1)
                    .padding(.vertical, 14)

                // ── RIGHT: Task list ──
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    HStack(spacing: 6) {
                        Circle().fill(pal.a).frame(width: 5, height: 5)
                            .shadow(color: pal.glow, radius: 3)
                        Text("TODAY")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white.opacity(0.30))
                            .kerning(1.3)
                        Spacer()
                        OpusMark(size: 17)
                    }
                    .padding(.bottom, 8)

                    if entry.topTasks.isEmpty {
                        Spacer()
                        VStack(spacing: 6) {
                            Text("🎉").font(.system(size: 28))
                            Text("Streak kept!")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(entry.topTasks.prefix(3)) { task in
                                SlimTaskRow(task: task, accent: pal.a)
                            }
                            if entry.pending > 3 {
                                Text("+ \(entry.pending - 3) more")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(pal.a.opacity(0.55))
                                    .padding(.leading, 6)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
                .padding(13)
            }
        }
        .containerBackground(entry.theme.background, for: .widget)
    }
}

// MARK: - LARGE WIDGET — bento grid layout
struct LargeWidgetView: View {
    let entry: OpusEntry
    private var pal: (a: Color, b: Color, glow: Color) {
        entry.theme.moodPalette(momentum: entry.momentum, pending: entry.pending)
    }
    private var progress: Double {
        guard entry.total > 0 else { return 0 }
        return Double(entry.total - entry.pending) / Double(entry.total)
    }
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: entry.date)
        let name = entry.userName.split(separator: " ").first.map(String.init) ?? ""
        let suffix = name.isEmpty ? "" : ", \(name)"
        switch h {
        case 0..<12:  return "Good morning\(suffix)"
        case 12..<17: return "Good afternoon\(suffix)"
        default:      return "Good evening\(suffix)"
        }
    }
    private var dateLabel: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"
        return f.string(from: entry.date)
    }
    private var momentumLabel: String {
        switch entry.momentum {
        case 80...100: return "On fire 🔥"
        case 60..<80:  return "Crushing it ⚡"
        case 40..<60:  return "Building up 💪"
        case 20..<40:  return "Warming up 🌱"
        default:       return "Let's go 🎯"
        }
    }

    var body: some View {
        ZStack {
            entry.theme.background

            // Radial glow top-center
            RadialGradient(colors: [pal.glow.opacity(0.25), Color.clear],
                           center: UnitPoint(x: 0.5, y: 0.15),
                           startRadius: 0, endRadius: 200)

            // Top glint
            VStack {
                LinearGradient(colors: [Color.clear, pal.a.opacity(0.55), Color.clear],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(height: 1)
                Spacer()
            }

            VStack(spacing: 0) {

                // ── HEADER ──
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(greeting)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text(dateLabel)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.30))
                    }
                    Spacer()
                    OpusMark(size: 28)
                }
                .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 12)

                // ── BENTO ROW: 3 stat tiles ──
                HStack(spacing: 8) {
                    // Pending count tile
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(pal.a.opacity(0.20), lineWidth: 1))
                        RadialGradient(colors: [pal.glow.opacity(0.22), Color.clear],
                                       center: .center, startRadius: 0, endRadius: 50)
                        VStack(spacing: 2) {
                            Text(entry.pending == 0 ? "✓" : "\(entry.pending)")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(LinearGradient(colors: [pal.a, pal.b],
                                                                startPoint: .top, endPoint: .bottom))
                                .shadow(color: pal.glow.opacity(0.5), radius: 8)
                            Text(entry.pending == 0 ? "all done" : "remaining")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white.opacity(0.32))
                                .kerning(0.3)
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 72)

                    // Streak tile
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "#F97316").opacity(0.20), lineWidth: 1))
                        VStack(spacing: 2) {
                            Text("🔥")
                                .font(.system(size: 18))
                            Text("\(entry.streak)")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text("day streak")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white.opacity(0.32))
                                .kerning(0.3)
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 72)

                    // Momentum tile
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(pal.a.opacity(0.20), lineWidth: 1))
                        VStack(spacing: 4) {
                            // Mini ring
                            ZStack {
                                Circle().stroke(Color.white.opacity(0.08), lineWidth: 4)
                                    .frame(width: 36, height: 36)
                                Circle()
                                    .trim(from: 0, to: CGFloat(entry.momentum) / 100)
                                    .stroke(pal.a, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .frame(width: 36, height: 36)
                                    .rotationEffect(.degrees(-90))
                                    .shadow(color: pal.glow.opacity(0.8), radius: 4)
                                Text("\(entry.momentum)")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            Text("momentum")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white.opacity(0.32))
                                .kerning(0.3)
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 72)
                }
                .padding(.horizontal, 14)

                // ── DIVIDER ──
                Rectangle()
                    .fill(LinearGradient(colors: [Color.clear, pal.a.opacity(0.18), Color.clear],
                                        startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                // ── TASK LIST ──
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Circle().fill(pal.a).frame(width: 5, height: 5)
                            .shadow(color: pal.glow, radius: 3)
                        Text("UP NEXT")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.white.opacity(0.25))
                            .kerning(1.5)
                        Spacer()
                        Text("\(entry.total - entry.pending)/\(entry.total) done")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(pal.a.opacity(0.60))
                    }
                    .padding(.bottom, 8)

                    if entry.topTasks.isEmpty {
                        VStack(spacing: 8) {
                            Text("🏆")
                                .font(.system(size: 32))
                            Text("Nothing left — great work!")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.35))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    } else {
                        VStack(spacing: 5) {
                            ForEach(entry.topTasks) { task in
                                SlimTaskRow(task: task, accent: pal.a)
                            }
                            if entry.pending > 4 {
                                Text("+ \(entry.pending - 4) more tasks")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(pal.a.opacity(0.50))
                                    .padding(.leading, 6)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)

                Spacer(minLength: 0)

                // ── BOTTOM MOMENTUM BAR ──
                VStack(spacing: 3) {
                    HStack {
                        Text(momentumLabel)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(pal.a.opacity(0.60))
                        Spacer()
                        Text("\(entry.momentum)%")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.07)).frame(height: 4)
                            Capsule()
                                .fill(LinearGradient(colors: [pal.a, pal.b],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(width: g.size.width * CGFloat(entry.momentum) / 100, height: 4)
                                .shadow(color: pal.glow.opacity(0.9), radius: 4)
                        }
                    }
                    .frame(height: 4).clipShape(Capsule())
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .containerBackground(entry.theme.background, for: .widget)
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
        AppIntentConfiguration(kind: kind, intent: OpusWidgetIntent.self, provider: OpusProvider()) { entry in
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

struct OpusLockProvider: TimelineProvider {
    func placeholder(in context: Context) -> OpusEntry {
        OpusEntry(date: .now, streak: 7, momentum: 65, pending: 2, total: 5,
                  topTasks: [WidgetTask(id: UUID(), title: "Review PR", isCompleted: false, category: "Work")],
                  userName: "", theme: .obsidian)
    }
    func getSnapshot(in context: Context, completion: @escaping (OpusEntry) -> Void) {
        completion(placeholder(in: context))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<OpusEntry>) -> Void) {
        let d        = UserDefaults(suiteName: sharedSuite) ?? .standard
        let streak   = d.integer(forKey: "streak")
        let momentum = d.integer(forKey: "momentum")
        var pending  = 0; var top = [WidgetTask]()
        if let data  = d.data(forKey: "todayTasks_v1"),
           let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data) {
            let open = tasks.filter { !$0.isCompleted }
            pending  = open.count
            top      = Array(open.prefix(1))
        }
        let entry = OpusEntry(date: .now, streak: streak, momentum: momentum,
                              pending: pending, total: 0, topTasks: top,
                              userName: "", theme: .obsidian)
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct OpusLockWidget: Widget {
    let kind = "OpusLockWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OpusLockProvider()) { entry in
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
