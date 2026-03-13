import SwiftUI
import AppKit

struct ResizeDragHandle: View {
    @Binding var height: CGFloat
    let minHeight: CGFloat = 200
    let defaultHeight: CGFloat = 600

    static let userDefaultsKey = "niwa.dropdown.contentMaxHeight"

    @State private var isHovered = false
    @State private var dragStartHeight: CGFloat?

    private var maxHeight: CGFloat {
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 900
        return min(screenHeight - 300, 900)
    }

    var body: some View {
        Rectangle()
            .fill(isHovered ? DesignTokens.Colors.secondary.opacity(0.08) : Color.clear)
            .frame(height: 8)
            .overlay {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(
                        isHovered
                            ? DesignTokens.Colors.secondary.opacity(0.6)
                            : DesignTokens.Colors.textMuted.opacity(0.3)
                    )
                    .frame(width: 40, height: 3)
            }
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if dragStartHeight == nil {
                            dragStartHeight = height
                        }
                        let newHeight = (dragStartHeight ?? height) + value.translation.height
                        height = min(max(newHeight, minHeight), maxHeight)
                    }
                    .onEnded { _ in
                        dragStartHeight = nil
                        UserDefaults.standard.set(Double(height), forKey: ResizeDragHandle.userDefaultsKey)
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(DesignTokens.Animation.viewTransition) {
                    height = defaultHeight
                }
                UserDefaults.standard.set(Double(defaultHeight), forKey: ResizeDragHandle.userDefaultsKey)
            }
            .accessibilityLabel("Resize handle")
            .accessibilityAdjustableAction { direction in
                let step: CGFloat = 50
                switch direction {
                case .increment:
                    height = min(height + step, maxHeight)
                case .decrement:
                    height = max(height - step, minHeight)
                @unknown default:
                    break
                }
                UserDefaults.standard.set(Double(height), forKey: ResizeDragHandle.userDefaultsKey)
            }
    }
}
