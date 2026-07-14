import AVFoundation
import Combine
import Vision

final class CameraMonitor: NSObject, ObservableObject {
    let session = AVCaptureSession()

    @Published var isRunning = false
    @Published var permissionDenied = false
    @Published var faceCount = 0
    @Published var alertActive = false
    @Published var statusTitle = "起動中"
    @Published var statusDetail = "カメラを準備しています"
    @Published var beepEnabled = true
    @Published var alertThreshold = 2
    @Published var holdSeconds = 0.7

    private let sessionQueue = DispatchQueue(label: "app.shoulderwatch.session")
    private let videoQueue = DispatchQueue(label: "app.shoulderwatch.video")
    private let alertSoundPlayer = AlertSoundPlayer()
    private lazy var faceRequest = VNDetectFaceRectanglesRequest()

    private var isConfigured = false
    private var suspiciousSince: Date?
    private var lastAnalysis = Date.distantPast
    private var lastBeep = Date.distantPast

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            statusTitle = "許可待ち"
            statusDetail = "カメラの使用を許可してください"
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionDenied = !granted
                    if granted {
                        self?.configureAndStart()
                    } else {
                        self?.statusTitle = "カメラ未許可"
                        self?.statusDetail = "システム設定でカメラ権限を許可すると使えます"
                    }
                }
            }
        case .denied, .restricted:
            permissionDenied = true
            statusTitle = "カメラ未許可"
            statusDetail = "システム設定でカメラ権限を許可すると使えます"
        @unknown default:
            permissionDenied = true
            statusTitle = "カメラ確認不可"
            statusDetail = "macOS のカメラ権限を確認してください"
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
            DispatchQueue.main.async {
                self.isRunning = false
                self.alertActive = false
                self.statusTitle = "停止中"
                self.statusDetail = "監視を停止しました"
            }
        }
    }

    func playTestSound() {
        alertSoundPlayer.play()
    }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            if !self.isConfigured {
                do {
                    try self.configureSession()
                    self.isConfigured = true
                } catch {
                    DispatchQueue.main.async {
                        self.statusTitle = "カメラエラー"
                        self.statusDetail = error.localizedDescription
                    }
                    return
                }
            }

            if !self.session.isRunning {
                self.session.startRunning()
            }

            DispatchQueue.main.async {
                self.isRunning = true
                self.permissionDenied = false
                self.statusTitle = "監視中"
                self.statusDetail = "顔が複数映ったら警告します"
            }
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .medium

        guard let camera = AVCaptureDevice.default(for: .video) else {
            throw MonitorError.noCamera
        }

        let input = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(input) else {
            throw MonitorError.cannotAddCamera
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.setSampleBufferDelegate(self, queue: videoQueue)

        guard session.canAddOutput(output) else {
            throw MonitorError.cannotAddOutput
        }
        session.addOutput(output)
    }

    private func updateFaceCount(_ count: Int) {
        faceCount = count

        let now = Date()
        if count >= alertThreshold {
            if suspiciousSince == nil {
                suspiciousSince = now
            }

            let elapsed = now.timeIntervalSince(suspiciousSince ?? now)
            if elapsed >= holdSeconds {
                alertActive = true
                statusTitle = "のぞき見注意"
                statusDetail = "\(count)人の顔を検出しています"

                if beepEnabled && now.timeIntervalSince(lastBeep) > 1.6 {
                    alertSoundPlayer.play()
                    lastBeep = now
                }
            } else {
                alertActive = false
                statusTitle = "確認中"
                statusDetail = "一瞬の誤検出を除外しています"
            }
        } else {
            suspiciousSince = nil
            alertActive = false

            if count == 0 {
                statusTitle = "監視中"
                statusDetail = "顔は検出されていません"
            } else {
                statusTitle = "安全"
                statusDetail = "検出中の顔は\(count)人です"
            }
        }
    }
}

extension CameraMonitor: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = Date()
        guard now.timeIntervalSince(lastAnalysis) > 0.25 else { return }
        lastAnalysis = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )

        do {
            try handler.perform([faceRequest])
            let count = faceRequest.results?.count ?? 0
            DispatchQueue.main.async { [weak self] in
                self?.updateFaceCount(count)
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.statusTitle = "解析エラー"
                self?.statusDetail = error.localizedDescription
            }
        }
    }
}

private enum MonitorError: LocalizedError {
    case noCamera
    case cannotAddCamera
    case cannotAddOutput

    var errorDescription: String? {
        switch self {
        case .noCamera:
            return "利用できるカメラが見つかりません"
        case .cannotAddCamera:
            return "カメラ入力を開始できません"
        case .cannotAddOutput:
            return "カメラ映像の解析を開始できません"
        }
    }
}
