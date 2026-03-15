import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var timerEngine: FocusTimerEngine?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationManager.shared.setup()
        NotificationManager.shared.requestPermission()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let engine = timerEngine, engine.state == .focusing {
            let alert = NSAlert()
            alert.messageText = "Focus session in progress"
            alert.informativeText = "You have an active focus timer. Quitting will lose your progress and XP for this session."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Quit Anyway")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationManager.shared.cancelAllPending()
    }
}
