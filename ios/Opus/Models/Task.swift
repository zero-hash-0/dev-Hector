import SwiftUI

// MARK: - Task Category
enum TaskCategory: String, CaseIterable, Identifiable, Codable {
    case work   = "Work"
    case side   = "Side"
    case learn  = "Learn"
    case health = "Health"
    case personal = "Personal"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .work:     return Color(hex: "#F5A623")
        case .side:     return Color(hex: "#A78BFA")
        case .learn:    return Color(hex: "#34D399")
        case .health:   return Color(hex: "#F87171")
        case .personal: return Color(hex: "#60A5FA")
        }
    }
}

// MARK: - Task Schedule
enum TaskSchedule: String, Codable {
    case today = "today"
    case later = "later"
}

// MARK: - Task Model
struct OpusTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var category: TaskCategory
    var schedule: TaskSchedule
    var dueLabel: String?
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        title: String,
        category: TaskCategory,
        schedule: TaskSchedule = .today,
        dueLabel: String? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.schedule = schedule
        self.dueLabel = dueLabel
        self.isCompleted = isCompleted
    }
}

// MARK: - Sample Data
extension OpusTask {
    static let sampleToday: [OpusTask] = [
        OpusTask(title: "Write proposal draft",  category: .work,  schedule: .today, dueLabel: "today"),
        OpusTask(title: "Review Q2 metrics",      category: .work,  schedule: .today),
        OpusTask(title: "Update portfolio",        category: .side,  schedule: .today),
        OpusTask(title: "Read chapter 4",          category: .learn, schedule: .today),
        OpusTask(title: "Expense report",          category: .work,  schedule: .today),
        OpusTask(title: "Call with Sarah",         category: .work,  schedule: .today, dueLabel: "2pm", isCompleted: true),
    ]

    static let sampleLater: [OpusTask] = [
        OpusTask(title: "Plan sprint backlog",  category: .work,  schedule: .later),
        OpusTask(title: "Design system audit", category: .side,  schedule: .later),
        OpusTask(title: "Finish SwiftUI book", category: .learn, schedule: .later),
    ]
}

// MARK: - Color hex helper
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
