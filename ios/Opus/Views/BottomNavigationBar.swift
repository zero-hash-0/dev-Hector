import SwiftUI

// MARK: - Tab
enum AppTab: Int, CaseIterable {
    case today    = 0
    case projects = 1
    case focus    = 2
    case profile  = 3

    var label: String {
        switch self {
        case .today:    return "Today"
        case .projects: return "Projects"
        case .focus:    return "Focus Mode"
        case .profile:  return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .today:    return "sun.max.fill"
        case .projects: return "square.grid.2x2"
        case .focus:    return "scope"
        case .profile:  return "person.circle"
        }
    }
}

// MARK: - Bottom Navigation Bar
struct BottomNavigationBar: View {
    @Binding var selectedTab: AppTab
    let onAdd: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let leftTabs:  [AppTab] = [.today, .projects]
    private let rightTabs: [AppTab] = [.focus, .profile]

    var body: some View {
        VStack(spacing: -34) {
            // ── FAB — floats above the pill, overlaps it by half ──
            Button(action: onAdd) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "#6E6BF5"), Color(hex: "#8A4AF3")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 56, height: 56)
                        .shadow(color: Color(hex: "#8A4AF3").opacity(0.65), radius: 18, x: 0, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(FABButtonStyle())
            .frame(width: 56, height: 56)     // lock to circle size — prevents full-width hit steal
            .contentShape(Circle())           // only the circle is tappable
            .accessibilityLabel("Add task")
            .zIndex(1)

            // ── Tab pill — sized by HStack content, Capsule in background ──
            HStack(spacing: 0) {
                // Left tabs
                HStack(spacing: 0) {
                    ForEach(leftTabs, id: \.self) { tab in
                        TabBarItem(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            reduceMotion: reduceMotion
                        ) {
                            withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // Gap for FAB
                Spacer().frame(width: 64)

                // Right tabs
                HStack(spacing: 0) {
                    ForEach(rightTabs, id: \.self) { tab in
                        TabBarItem(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            reduceMotion: reduceMotion
                        ) {
                            withAnimation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = tab
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background {
                ZStack {
                    // Rich opaque dark-purple base
                    Capsule().fill(Color(hex: "#110D24"))
                    // Subtle violet shimmer on top half
                    Capsule().fill(
                        LinearGradient(
                            colors: [Color(hex: "#6E6BF5").opacity(0.28), Color.clear],
                            startPoint: .top, endPoint: .center
                        )
                    )
                    // Top-bright border glow
                    Capsule().stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "#A78BFA").opacity(0.80),
                                Color(hex: "#6E6BF5").opacity(0.40),
                                Color(hex: "#8A4AF3").opacity(0.10)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }
                .shadow(color: Color(hex: "#6E6BF5").opacity(0.30), radius: 24, x: 0, y: 6)
                .shadow(color: .black.opacity(0.60), radius: 30, x: 0, y: 12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
}

// MARK: - Tab Bar Item
private struct TabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Glow halo behind selected icon
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "#8A4AF3").opacity(0.18))
                            .frame(width: 36, height: 36)
                            .blur(radius: 8)
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(
                            isSelected
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [Color(hex: "#C4B5FD"), Color(hex: "#8A4AF3")],
                                    startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(Color.white.opacity(0.30))
                        )
                        .scaleEffect(isSelected ? 1.10 : 1.0)
                        .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                }

                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? Color(hex: "#C4B5FD") : .white.opacity(0.30))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                // Active indicator dot
                Circle()
                    .fill(Color(hex: "#8A4AF3"))
                    .frame(width: 4, height: 4)
                    .shadow(color: Color(hex: "#8A4AF3").opacity(0.9), radius: 4)
                    .opacity(isSelected ? 1 : 0)
                    .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - FAB Button Style
private struct FABButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? (reduceMotion ? 1.0 : 0.92) : 1.0)
            .animation(reduceMotion ? .none : .spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(hex: "#08070A").ignoresSafeArea()
        VStack {
            Spacer()
            BottomNavigationBar(selectedTab: .constant(.today), onAdd: {})
        }
    }
}
