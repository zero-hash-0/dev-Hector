import SwiftUI
import UserNotifications

@main
struct OpusApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        // Force dark mode across all windows
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = .dark }

        // Migration: clear the hardcoded "Hector" default that shipped in early builds.
        // Any device that still has the old default stored gets reset to empty so
        // users see the onboarding name prompt instead of the developer's name.
        let defaults = UserDefaults.standard
        if defaults.string(forKey: "userName") == "Hector",
           !defaults.bool(forKey: "userNameMigrated_v2") {
            defaults.removeObject(forKey: "userName")
            defaults.set(true, forKey: "userNameMigrated_v2")
        }
        // Also clear shared suite
        if let shared = UserDefaults(suiteName: "group.com.opus.betaapp") {
            if shared.string(forKey: "userName") == "Hector" {
                shared.removeObject(forKey: "userName")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    Task {
                        await NotificationManager.shared.requestPermission()
                    }
                }
        }
    }
}

// MARK: - AppDelegate for notification delegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear badge when app is opened
        NotificationManager.shared.clearBadge()
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 didReceive response: UNNotificationResponse,
                                 withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
