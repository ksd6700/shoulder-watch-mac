import AppKit
import Combine
import SwiftUI

final class EdgeAlertController {
    private let monitor: CameraMonitor
    private var panels: [NSPanel] = []
    private var cancellables = Set<AnyCancellable>()

    init(monitor: CameraMonitor) {
        self.monitor = monitor

        monitor.$alertActive
            .receive(on: RunLoop.main)
            .sink { [weak self] active in
                active ? self?.show() : self?.hide()
            }
            .store(in: &cancellables)
    }

    deinit {
        hide()
    }

    private func show() {
        guard panels.isEmpty else { return }
        panels = NSScreen.screens.map(makePanel)
        panels.forEach { $0.orderFrontRegardless() }
    }

    private func hide() {
        panels.forEach {
            $0.orderOut(nil)
            $0.close()
        }
        panels.removeAll()
    }

    private func makePanel(for screen: NSScreen) -> NSPanel {
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.isOpaque = false
        panel.level = .statusBar

        let hostingView = NSHostingView(rootView: EdgeAlertView(monitor: monitor))
        hostingView.frame = NSRect(origin: .zero, size: screen.frame.size)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView

        return panel
    }
}

struct EdgeAlertView: View {
    @ObservedObject var monitor: CameraMonitor

    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.red.opacity(0.88), lineWidth: 12)
                .shadow(color: .red.opacity(0.55), radius: 18)

            VStack {
                HStack {
                    Spacer()

                    HStack(spacing: 10) {
                        Image(systemName: "eye.trianglebadge.exclamationmark")
                            .font(.system(size: 22, weight: .bold))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("のぞき見注意")
                                .font(.system(size: 18, weight: .bold))
                            Text("\(monitor.faceCount)人の顔を検出")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.94))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(.top, 30)
                .padding(.trailing, 30)

                Spacer()
            }
        }
        .background(Color.clear)
        .allowsHitTesting(false)
    }
}
