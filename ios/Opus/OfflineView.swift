import SwiftUI

struct OfflineView: View {
    var onRetry: () -> Void

    var body: some View {
        ZStack {
            Color(red: 15/255, green: 14/255, blue: 17/255)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 64, height: 64)

                    Text("⚡")
                        .font(.system(size: 28))
                }

                // Copy
                VStack(spacing: 6) {
                    Text("No connection")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Check your network and try again.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }

                // Retry button
                Button(action: onRetry) {
                    Text("Try again")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 15/255, green: 14/255, blue: 17/255))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(
                            Color(red: 245/255, green: 166/255, blue: 35/255)
                        )
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    OfflineView { }
}
