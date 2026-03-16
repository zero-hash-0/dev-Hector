import SwiftUI

struct TaskRow: View {
    let task: OpusTask
    let onToggle: () -> Void

    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 12) {

            // ── Completion toggle ──
            Button(action: {
                withAnimation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.65)) {
                    onToggle()
                }
            }) {
                ZStack {
                    Circle()
                        .stroke(
                            task.isCompleted
                                ? Color(hex: "#34D399")
                                : Color.white.opacity(0.18),
                            lineWidth: 1.5
                        )
                        .frame(width: 24, height: 24)

                    if task.isCompleted {
                        Circle()
                            .fill(Color(hex: "#34D399").opacity(0.15))
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "#34D399"))
                            .transition(
                                reduceMotion
                                    ? .opacity
                                    : .scale.combined(with: .opacity)
                            )
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Mark complete")

            // ── Category dot ──
            Circle()
                .fill(task.category.color)
                .frame(width: 7, height: 7)

            // ── Title ──
            Text(task.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(task.isCompleted ? .white.opacity(0.35) : .white.opacity(0.9))
                .strikethrough(task.isCompleted, color: .white.opacity(0.3))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeOut(duration: 0.2), value: task.isCompleted)

            // ── Due label ──
            if let due = task.dueLabel {
                Text(due)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.35))
            }

            // ── Category pill ──
            Text(task.category.rawValue)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(task.category.color)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(task.category.color.opacity(0.12))
                        .overlay(
                            Capsule()
                                .stroke(task.category.color.opacity(0.25), lineWidth: 0.5)
                        )
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(reduceMotion ? .none : .spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(hex: "#08070A").ignoresSafeArea()
        VStack(spacing: 0) {
            ForEach(OpusTask.sampleToday) { task in
                TaskRow(task: task, onToggle: {})
                    .padding(.horizontal, 20)
                if task.id != OpusTask.sampleToday.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.06))
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}
