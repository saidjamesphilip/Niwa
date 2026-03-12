import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up notification delegate EARLY — must be in didFinishLaunching
        NotificationManager.shared.setup()
        NotificationManager.shared.requestPermission()
    }
}
