import SwiftUI
import AppKit

struct ResizeDragHandle: View {
    @Binding var height: CGFloat
    let minHeight: CGFloat = 200
    let defaultHeight: CGFloat = 600

    static let userDefaultsKey = "niwa.dropdown.contentMaxHeight"

    @State private var isHovered = false
    @State private var isDragging = false
    @State private var dragOffset: CGFloat = 0

    private var maxHeight: CGFloat {
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 900
        return min(screenHeight - 300, 900)
    }

    var body: some View {
        VStack(spacing: 0) {
            // During drag, show a spacer that previews the extra height
            if isDragging && dragOffset > 0 {
                Rectangle()
                    .fill(DesignTokens.Colors.secondary.opacity(0.04))
                    .frame(height: dragOffset)
            }

            // The handle itself
            Rectangle()
                .fill((isHovered || isDragging) ? DesignTokens.Colors.secondary.opacity(0.1) : Color.clear)
                .frame(height: 12)
                .overlay {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(
                            (isHovered || isDragging)
                                ? DesignTokens.Colors.secondary.opacity(0.6)
                                : DesignTokens.Colors.textMuted.opacity(0.3)
                        )
                        .frame(width: 40, height: 3)
                }
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
        .highPriorityGesture(
            DragGesture(minimumDistance: 3)
                .onChanged { value in
                    isDragging = true
                    let targetHeight = height + value.translation.height
                    let clamped = min(max(targetHeight, minHeight), maxHeight)
                    // Preview offset is the difference from current height
                    dragOffset = clamped - height
                }
                .onEnded { value in
                    let targetHeight = height + value.translation.height
                    let clamped = min(max(targetHeight, minHeight), maxHeight)
                    // Apply the final height in one step
                    isDragging = false
                    dragOffset = 0
                    withAnimation(.easeOut(duration: 0.15)) {
                        height = clamped
                    }
                    UserDefaults.standard.set(Double(clamped), forKey: ResizeDragHandle.userDefaultsKey)
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
