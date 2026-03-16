import SwiftUI

struct ContentView: View {
    @State private var isLoading = true
    @State private var hasError = false

    var body: some View {
        ZStack {
            // Background always dark — prevents white flash
            Color(red: 15/255, green: 14/255, blue: 17/255)
                .ignoresSafeArea()

            // Web view — hidden until loaded
            OpusWebView(isLoading: $isLoading, hasError: $hasError)
                .ignoresSafeArea(edges: .bottom)
                .opacity(isLoading || hasError ? 0 : 1)

            // Launch screen while loading
            if isLoading {
                LaunchScreen()
                    .transition(.opacity)
            }

            // Offline / error state
            if hasError {
                OfflineView {
                    // Retry — flip back to loading, WebView will reload
                    hasError = false
                    isLoading = true
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.easeInOut(duration: 0.2), value: hasError)
    }
}
