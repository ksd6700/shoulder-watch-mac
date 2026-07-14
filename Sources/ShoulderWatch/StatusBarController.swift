import AppKit
import Combine

final class StatusBarController: NSObject {
    private let monitor: CameraMonitor
    private let settingsWindowController: SettingsWindowController
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var cancellables = Set<AnyCancellable>()

    private var statusMenuItem: NSMenuItem?
    private var startStopMenuItem: NSMenuItem?
    private var beepMenuItem: NSMenuItem?
    private var thresholdMenuItems: [NSMenuItem] = []

    init(monitor: CameraMonitor) {
        self.monitor = monitor
        self.settingsWindowController = SettingsWindowController(monitor: monitor)
        super.init()

        configureStatusItem()
        buildMenu()
        observeMonitor()
        refresh()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.imagePosition = .imageOnly
        button.toolTip = "Shoulder Watch"
    }

    private func buildMenu() {
        thresholdMenuItems.removeAll()

        let menu = NSMenu()
        menu.autoenablesItems = false

        let titleItem = NSMenuItem(title: "Shoulder Watch", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        let statusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        self.statusMenuItem = statusItem

        menu.addItem(.separator())

        let startStopItem = NSMenuItem(title: "", action: #selector(toggleMonitoring), keyEquivalent: "")
        startStopItem.target = self
        menu.addItem(startStopItem)
        self.startStopMenuItem = startStopItem

        let beepItem = NSMenuItem(title: "警告音", action: #selector(toggleBeep), keyEquivalent: "")
        beepItem.target = self
        menu.addItem(beepItem)
        self.beepMenuItem = beepItem

        let testSoundItem = NSMenuItem(title: "テスト音を鳴らす", action: #selector(playTestSound), keyEquivalent: "")
        testSoundItem.target = self
        menu.addItem(testSoundItem)

        let thresholdRoot = NSMenuItem(title: "警告人数", action: nil, keyEquivalent: "")
        let thresholdMenu = NSMenu()
        for count in 2...4 {
            let item = NSMenuItem(title: "\(count)人以上", action: #selector(setThreshold(_:)), keyEquivalent: "")
            item.target = self
            item.tag = count
            thresholdMenu.addItem(item)
            thresholdMenuItems.append(item)
        }
        menu.addItem(thresholdRoot)
        menu.setSubmenu(thresholdMenu, for: thresholdRoot)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "設定を開く...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(title: "終了", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        self.statusItem.menu = menu
    }

    private func observeMonitor() {
        monitor.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.refresh()
                }
            }
            .store(in: &cancellables)
    }

    private func refresh() {
        if let button = statusItem.button {
            button.image = StatusBarIcon.make()
            button.contentTintColor = nil
            button.toolTip = monitor.alertActive ? "Shoulder Watch - のぞき見注意" : "Shoulder Watch"
        }

        statusMenuItem?.title = "\(monitor.statusTitle) - 顔 \(monitor.faceCount)人"
        startStopMenuItem?.title = monitor.isRunning ? "監視を停止" : "監視を開始"
        beepMenuItem?.state = monitor.beepEnabled ? .on : .off

        for item in thresholdMenuItems {
            item.state = item.tag == monitor.alertThreshold ? .on : .off
        }
    }

    @objc private func toggleMonitoring() {
        monitor.isRunning ? monitor.stop() : monitor.start()
    }

    @objc private func toggleBeep() {
        monitor.beepEnabled.toggle()
        refresh()
    }

    @objc private func playTestSound() {
        monitor.playTestSound()
    }

    @objc private func setThreshold(_ sender: NSMenuItem) {
        monitor.alertThreshold = sender.tag
        refresh()
    }

    @objc private func openSettings() {
        settingsWindowController.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
