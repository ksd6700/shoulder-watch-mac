import AppKit
import AVFoundation

final class AlertSoundPlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let queue = DispatchQueue(label: "app.shoulderwatch.alert-sound")
    private var isConfigured = false

    func play() {
        queue.async { [weak self] in
            self?.playTone()
        }
    }

    private func playTone() {
        do {
            try configureIfNeeded()
            let buffer = makeWarningBuffer()
            player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
            player.play()
        } catch {
            NSSound.beep()
        }
    }

    private func configureIfNeeded() throws {
        guard !isConfigured else {
            if !engine.isRunning {
                try engine.start()
            }
            return
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 1.0
        try engine.start()
        isConfigured = true
    }

    private func makeWarningBuffer() -> AVAudioPCMBuffer {
        let sampleRate = 44_100.0
        let duration = 0.42
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let channel = buffer.floatChannelData?[0] else { return buffer }

        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let frequency = time < duration / 2 ? 880.0 : 660.0
            let phase = 2.0 * Double.pi * frequency * time
            let attack = min(time / 0.025, 1.0)
            let release = min((duration - time) / 0.04, 1.0)
            let envelope = max(0.0, min(attack, release))
            channel[frame] = Float(sin(phase) * 0.42 * envelope)
        }

        return buffer
    }
}
