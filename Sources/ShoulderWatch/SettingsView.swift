import SwiftUI

struct SettingsView: View {
    @ObservedObject var monitor: CameraMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            Divider()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Toggle("警告音を鳴らす", isOn: $monitor.beepEnabled)
                        .toggleStyle(.switch)

                    Spacer()

                    Button {
                        monitor.playTestSound()
                    } label: {
                        Label("テスト", systemImage: "speaker.wave.2.fill")
                    }
                }

                Stepper(value: $monitor.alertThreshold, in: 2...4) {
                    Text("\(monitor.alertThreshold)人以上で警告")
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("検出の待ち時間")
                        Spacer()
                        Text(String(format: "%.1f秒", monitor.holdSeconds))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $monitor.holdSeconds, in: 0.3...2.0, step: 0.1)
                }
            }

            Divider()

            Text("カメラプレビューは表示しません。映像は保存せず、このMac内で顔の数だけを確認します。")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            HStack {
                Button {
                    monitor.isRunning ? monitor.stop() : monitor.start()
                } label: {
                    Label(monitor.isRunning ? "監視を停止" : "監視を開始", systemImage: monitor.isRunning ? "pause.fill" : "play.fill")
                }
                .keyboardShortcut(.space, modifiers: [])

                Spacer()

                Button("閉じる") {
                    NSApp.keyWindow?.close()
                }
            }
        }
        .padding(24)
        .frame(width: 440, height: 360)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: monitor.alertActive ? "eye.trianglebadge.exclamationmark" : "eye")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(monitor.alertActive ? .red : .primary)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(monitor.statusTitle)
                    .font(.system(size: 22, weight: .bold))
                Text(monitor.statusDetail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(monitor.faceCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("顔")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
