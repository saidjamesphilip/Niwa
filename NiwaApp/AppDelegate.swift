import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up notification delegate EARLY — must be in didFinishLaunching
        NotificationManager.shared.setup()
        NotificationManager.shared.requestPermission()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cancel all pending notifications when the app quits —
        // reminders should only fire while the app is running
        NotificationManager.shared.cancelAllPending()
    }
}
