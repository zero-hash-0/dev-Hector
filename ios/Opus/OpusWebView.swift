import SwiftUI
import WebKit

struct OpusWebView: UIViewRepresentable {
    @Binding var isLoading: Bool
    @Binding var hasError: Bool

    // Production URL — update if domain changes
    private let appURL = URL(string: "https://unruffled-chaum.vercel.app/opus/app")!
    // iOS-specific invite code — bypasses web cookie gate
    private let inviteCode = "OPUS-BETA-IOS"
    private let inviteDomain = "unruffled-chaum.vercel.app"

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = "OpusApp/1.0 iOS/\(UIDevice.current.systemVersion)"

        // Transparent background — our SwiftUI layer handles color
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = UIColor(
            red: 15/255, green: 14/255, blue: 17/255, alpha: 1
        )

        // Pull-to-refresh
        let refresh = UIRefreshControl()
        refresh.tintColor = UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1)
        refresh.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleRefresh(_:)),
            for: .valueChanged
        )
        webView.scrollView.refreshControl = refresh
        webView.scrollView.alwaysBounceVertical = true

        // Store reference so delegate can reload on retry
        context.coordinator.webView = webView

        // Inject invite cookie, then load
        injectInviteCookie(into: webView) {
            let request = URLRequest(
                url: self.appURL,
                cachePolicy: .returnCacheDataElseLoad,
                timeoutInterval: 20
            )
            webView.load(request)
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Reload triggered by ContentView retry button (hasError flipped to false)
        if !hasError && !isLoading && webView.url == nil {
            let request = URLRequest(url: appURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
            webView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, hasError: $hasError, appURL: appURL)
    }

    // MARK: - Cookie injection

    private func injectInviteCookie(into webView: WKWebView, completion: @escaping () -> Void) {
        guard let cookie = HTTPCookie(properties: [
            .domain:  inviteDomain,
            .path:    "/",
            .name:    "opus_invite",
            .value:   inviteCode,
            .secure:  "TRUE",
            .expires: Date(timeIntervalSinceNow: 365 * 24 * 60 * 60)
        ]) else {
            completion()
            return
        }
        webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie) {
            completion()
        }
    }

    // MARK: - Coordinator (navigation delegate)

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        @Binding var hasError: Bool
        let appURL: URL
        weak var webView: WKWebView?

        init(isLoading: Binding<Bool>, hasError: Binding<Bool>, appURL: URL) {
            _isLoading = isLoading
            _hasError = hasError
            self.appURL = appURL
        }

        // Page finished loading
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
            hasError = false
            webView.scrollView.refreshControl?.endRefreshing()
        }

        // Navigation failed after starting
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleError(error)
            webView.scrollView.refreshControl?.endRefreshing()
        }

        // Navigation failed before starting (DNS, timeout, etc.)
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleError(error)
            webView.scrollView.refreshControl?.endRefreshing()
        }

        // Decide which links to follow vs open externally
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Allow all navigation within our own domain
            if url.host == appURL.host {
                decisionHandler(.allow)
                return
            }

            // Open all other http/https links in Safari
            if let scheme = url.scheme, ["http", "https"].contains(scheme) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            // Allow tel:, mailto:, about:blank, etc.
            decisionHandler(.allow)
        }

        // Pull-to-refresh handler
        @objc func handleRefresh(_ sender: UIRefreshControl) {
            guard let webView = webView else {
                sender.endRefreshing()
                return
            }
            // Clear error, reload
            hasError = false
            let request = URLRequest(url: appURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
            webView.load(request)
        }

        // MARK: - Private

        private func handleError(_ error: Error) {
            let code = (error as NSError).code
            // Ignore user-cancelled navigations (e.g. redirect chains)
            guard code != NSURLErrorCancelled else { return }
            isLoading = false
            hasError = true
        }
    }
}
