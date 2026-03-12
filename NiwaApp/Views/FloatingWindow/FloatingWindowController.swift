import AppKit
import SwiftUI

final class FloatingWindowController {
    private var panel: NSPanel?
    private let positionKey = "floatingWindowPosition"

    var isVisible: Bool { panel?.isVisible ?? false }

    func show(contentView: some View, alwaysOnTop: Bool) {
        if let existing = panel {
            existing.orderFront(nil)
            updateLevel(alwaysOnTop: alwaysOnTop)
            return
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 140),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.isMovableByWindowBackground = true
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hostingView = NSHostingView(rootView: contentView)
        panel.contentView = hostingView

        // Restore position
        if let posDict = UserDefaults.standard.dictionary(forKey: positionKey),
           let x = posDict["x"] as? CGFloat,
           let y = posDict["y"] as? CGFloat {
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            panel.center()
        }

        updateLevel(alwaysOnTop: alwaysOnTop)
        panel.orderFront(nil)
        self.panel = panel

        // Save position on move
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            self?.savePosition()
        }
    }

    func hide() {
        savePosition()
        panel?.orderOut(nil)
    }

    func toggle(contentView: some View, alwaysOnTop: Bool) {
        if isVisible {
            hide()
        } else {
            show(contentView: contentView, alwaysOnTop: alwaysOnTop)
        }
    }

    func updateLevel(alwaysOnTop: Bool) {
        panel?.level = alwaysOnTop ? .floating : .normal
    }

    private func savePosition() {
        guard let frame = panel?.frame else { return }
        UserDefaults.standard.set(
            ["x": frame.origin.x, "y": frame.origin.y],
            forKey: positionKey
        )
    }
}
