import UserNotifications
import Foundation

// MARK: - NotificationManager
@MainActor
final class NotificationManager: ObservableObject {

    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task { await refreshAuthorizationStatus() }
    }

    // MARK: - Request Permission
    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                await scheduleDailyMorningReminder()
                await scheduleEveningStreakGuard()
            }
        } catch {
            isAuthorized = false
        }
    }

    // MARK: - Refresh status
    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Daily 9 AM task reminder
    func scheduleDailyMorningReminder(pendingCount: Int = 0) async {
        center.removePendingNotificationRequests(withIdentifiers: ["opus.daily.morning"])

        var components        = DateComponents()
        components.hour       = 9
        components.minute     = 0
        let trigger           = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let content           = UNMutableNotificationContent()
        content.title         = pendingCount > 0
            ? "You've got \(pendingCount) task\(pendingCount == 1 ? "" : "s") today 💪"
            : "Good morning. What are you building today?"
        content.body          = "Open Opus and keep your streak alive."
        content.sound         = .default
        content.badge         = pendingCount > 0 ? NSNumber(value: pendingCount) : 0

        let request = UNNotificationRequest(identifier: "opus.daily.morning",
                                            content: content,
                                            trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - Evening streak guard (8 PM) — fires only if not dismissed
    func scheduleEveningStreakGuard() async {
        center.removePendingNotificationRequests(withIdentifiers: ["opus.streak.guard"])

        var components    = DateComponents()
        components.hour   = 20
        components.minute = 0
        let trigger       = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let content       = UNMutableNotificationContent()
        content.title     = "Don't break your streak 🔥"
        content.body      = "You still have tasks left. Finish strong."
        content.sound     = .default

        let request = UNNotificationRequest(identifier: "opus.streak.guard",
                                            content: content,
                                            trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - Due date notification
    func scheduleDueDateNotification(for task: OpusTask) async {
        guard let due = task.dueDate else { return }

        // 30 minutes before due
        let fireDate = due.addingTimeInterval(-30 * 60)
        guard fireDate > Date() else { return }

        let identifier = "opus.due.\(task.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content       = UNMutableNotificationContent()
        content.title     = "Due soon: \(task.title)"
        content.body      = "This task is due in 30 minutes."
        content.sound     = .default
        content.categoryIdentifier = "TASK_DUE"

        let comps   = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - Cancel due date notification for a task
    func cancelDueDateNotification(for taskID: UUID) {
        center.removePendingNotificationRequests(
            withIdentifiers: ["opus.due.\(taskID.uuidString)"]
        )
    }

    // MARK: - All tasks done celebration
    func sendAllDoneNotification() async {
        let content       = UNMutableNotificationContent()
        content.title     = "All done! 🎉"
        content.body      = "You crushed every task today. Momentum is maxed."
        content.sound     = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "opus.alldone.\(UUID())",
                                            content: content,
                                            trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - Clear badge
    func clearBadge() {
        center.setBadgeCount(0)
    }
}
