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

    var body: some View {
        ZStack(alignment: .bottom) {

            // Bar background
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    // Skip center slot for FAB
                    if tab == .focus {
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }

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
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .padding(.bottom, 4)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .fill(Color.white.opacity(0.04))
                    )
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 0.5)
                    }
                    .ignoresSafeArea(edges: .bottom)
            )

            // ── FAB ──
            Button(action: onAdd) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#F5A623"), Color(hex: "#FF6B6B")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: Color(hex: "#F5A623").opacity(0.4), radius: 12, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(FABButtonStyle())
            .offset(y: -24)
            .accessibilityLabel("Add task")
        }
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
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(
                                colors: [Color(hex: "#F5A623"), Color(hex: "#FF6B6B")],
                                startPoint: .top,
                                endPoint: .bottom
                              ))
                            : AnyShapeStyle(Color.white.opacity(0.35))
                    )
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

                Text(tab.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "#F5A623") : .white.opacity(0.35))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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
