import SwiftUI

@main
struct OpusApp: App {

    init() {
        // Force dark mode across all windows
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = .dark }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
