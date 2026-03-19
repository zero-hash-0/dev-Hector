import SwiftUI

// MARK: - Project Model
struct Project: Identifiable, Codable {
    let id: UUID
    var name: String
    var emoji: String
    var colorHex: String
    var tasks: [OpusTask]
    var isArchived: Bool = false

    var color: Color { Color(hex: colorHex) }
    var completedCount: Int { tasks.filter(\.isCompleted).count }
    var progress: Double { tasks.isEmpty ? 0 : Double(completedCount) / Double(tasks.count) }

    init(id: UUID = UUID(), name: String, emoji: String, colorHex: String, tasks: [OpusTask] = []) {
        self.id       = id
        self.name     = name
        self.emoji    = emoji
        self.colorHex = colorHex
        self.tasks    = tasks
    }
}

// MARK: - Sample Data
extension Project {
    static let samples: [Project] = [
        Project(
            name: "Dev Portfolio", emoji: "💻", colorHex: "#8A4AF3",
            tasks: [
                OpusTask(title: "Design landing page",    category: .side,  isCompleted: true),
                OpusTask(title: "Write case studies",     category: .side,  isCompleted: true),
                OpusTask(title: "Add scroll animations",  category: .side),
                OpusTask(title: "SEO optimisation",       category: .side),
                OpusTask(title: "Deploy to Vercel",       category: .side),
            ]
        ),
        Project(
            name: "Learning Path", emoji: "📚", colorHex: "#60A5FA",
            tasks: [
                OpusTask(title: "Finish SwiftUI book",    category: .learn, isCompleted: true),
                OpusTask(title: "Complete iOS course",    category: .learn, isCompleted: true),
                OpusTask(title: "Build weather app",      category: .learn),
                OpusTask(title: "Study Core Data",        category: .learn),
            ]
        ),
        Project(
            name: "Health & Fitness", emoji: "💪", colorHex: "#34D399",
            tasks: [
                OpusTask(title: "Morning run 3×/week",   category: .health, isCompleted: true),
                OpusTask(title: "Meal prep Sunday",      category: .health),
                OpusTask(title: "Sleep by 10 PM",        category: .health),
            ]
        ),
    ]
}
