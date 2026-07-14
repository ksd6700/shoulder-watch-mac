import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = CameraMonitor()
    private var statusBarController: StatusBarController?
    private var edgeAlertController: EdgeAlertController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController(monitor: monitor)
        edgeAlertController = EdgeAlertController(monitor: monitor)
        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }
}
