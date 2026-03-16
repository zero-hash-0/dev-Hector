import SwiftUI

struct LaunchScreen: View {
    @State private var scale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.5

    private let amber = Color(red: 245/255, green: 166/255, blue: 35/255)

    var body: some View {
        ZStack {
            Color(red: 15/255, green: 14/255, blue: 17/255)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                // Pulsing amber ring around the wordmark icon
                ZStack {
                    // Outer pulse ring
                    Circle()
                        .stroke(amber.opacity(ringOpacity), lineWidth: 1.5)
                        .frame(width: 72, height: 72)
                        .scaleEffect(scale)

                    // Solid background circle
                    Circle()
                        .fill(amber.opacity(0.12))
                        .frame(width: 52, height: 52)

                    // Opus symbol
                    Text("◉")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundColor(amber)
                }
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.1)
                        .repeatForever(autoreverses: false)
                    ) {
                        scale = 1.5
                        ringOpacity = 0
                    }
                }

                // Wordmark
                Text("opus")
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(.white.opacity(0.85))
                    .kerning(4)
            }
        }
    }
}

#Preview {
    LaunchScreen()
}
