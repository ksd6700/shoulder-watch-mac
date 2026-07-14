import AppKit
import SwiftUI

final class SettingsWindowController {
    private let monitor: CameraMonitor
    private var window: NSWindow?

    init(monitor: CameraMonitor) {
        self.monitor = monitor
    }

    func show() {
        if window == nil {
            let hostingView = NSHostingView(rootView: SettingsView(monitor: monitor))
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 360),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Shoulder Watch"
            window.contentView = hostingView
            window.isReleasedWhenClosed = false
            self.window = window
        }

        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
