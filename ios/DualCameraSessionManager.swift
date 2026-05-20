import AVFoundation
import UIKit

// MARK: - Capture Options & Result

struct CaptureOptions {
    let quality: Double
    let base64: Bool

    init(from dict: [String: Any]?) {
        quality = dict?["quality"] as? Double ?? 1.0
        base64 = dict?["base64"] as? Bool ?? false
    }
}

// MARK: - Photo Capture Delegate

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let options: CaptureOptions
    private let completion: (Result<[String: Any], Error>) -> Void

    init(options: CaptureOptions, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        self.options = options
        self.completion = completion
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            completion(.failure(error))
            return
        }
        guard var data = photo.fileDataRepresentation() else {
            completion(.failure(DualCameraError.noPhotoData))
            return
        }

        let dimensions = photo.resolvedSettings.photoDimensions

        if options.quality < 1.0, let image = UIImage(data: data),
           let compressed = image.jpegData(compressionQuality: CGFloat(options.quality)) {
            data = compressed
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".jpg")
        do {
            try data.write(to: url)
            var result: [String: Any] = [
                "uri": url.absoluteString,
                "width": Int(dimensions.width),
                "height": Int(dimensions.height),
            ]
            if options.base64 {
                result["base64"] = data.base64EncodedString()
            }
            completion(.success(result))
        } catch {
            completion(.failure(error))
        }
    }
}

// MARK: - Error Types

enum DualCameraError: LocalizedError {
    case sessionNotRunning
    case noPhotoData
    case noPhotoOutput
    case torchUnavailable

    var errorDescription: String? {
        switch self {
        case .sessionNotRunning: return "Camera session is not running"
        case .noPhotoData: return "Failed to get photo data"
        case .noPhotoOutput: return "Photo output not available"
        case .torchUnavailable: return "Torch is not available on this device"
        }
    }
}

// MARK: - Session Manager

class DualCameraSessionManager {
    static let shared = DualCameraSessionManager()

    // Views (main thread only)
    private weak var frontView: DualCameraView?
    private weak var backView: DualCameraView?

    // Session state
    private var session: AVCaptureMultiCamSession?
    private(set) var isRunning = false
    private var isPaused = false
    private var isStopping = false
    private var backLens: String = "wide"

    // Devices
    private var frontDevice: AVCaptureDevice?
    private var backDevice: AVCaptureDevice?

    // Photo outputs
    private var frontPhotoOutput: AVCapturePhotoOutput?
    private var backPhotoOutput: AVCapturePhotoOutput?

    // In-flight photo delegates
    private var activePhotoDelegates: [UUID: PhotoCaptureDelegate] = [:]

    // Settings (set via view props, used during capture)
    private var flashMode: AVCaptureDevice.FlashMode = .off

    private let sessionQueue = DispatchQueue(label: "com.expodualcamera.session")

    private init() {}

    // MARK: - Permission Helpers

    static func permissionResponse() -> [String: Any] {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return ["status": "granted", "granted": true, "canAskAgain": true, "expires": "never"]
        case .denied, .restricted:
            return ["status": "denied", "granted": false, "canAskAgain": false, "expires": "never"]
        default:
            return ["status": "undetermined", "granted": false, "canAskAgain": true, "expires": "never"]
        }
    }

    // MARK: - Registration

    func register(_ view: DualCameraView, side: String) {
        if side == "front" { frontView = view }
        else { backView = view }
        startIfReady()
    }

    func unregister(_ view: DualCameraView) {
        if view === frontView { frontView = nil }
        if view === backView { backView = nil }
        if !isStopping {
            stop()
        }
    }

    func setBackLens(_ lens: String) {
        guard lens != backLens else { return }
        backLens = lens
        if isRunning {
            stop()
            startIfReady()
        }
    }

    // MARK: - Props forwarded from views

    func setZoom(side: String, normalizedZoom: Double) {
        let device = (side == "front") ? frontDevice : backDevice
        guard let dev = device else { return }

        let minZoom = dev.minAvailableVideoZoomFactor
        let maxZoom = dev.maxAvailableVideoZoomFactor
        let factor = minZoom + CGFloat(normalizedZoom) * (maxZoom - minZoom)

        do {
            try dev.lockForConfiguration()
            dev.videoZoomFactor = factor
            dev.unlockForConfiguration()
        } catch {}
    }

    func setTorch(_ enabled: Bool) {
        guard let device = backDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = enabled ? .on : .off
            device.unlockForConfiguration()
        } catch {}
    }

    func setFlash(_ mode: String) {
        switch mode {
        case "on": flashMode = .on
        case "auto": flashMode = .auto
        default: flashMode = .off
        }
    }

    func setAutofocus(side: String, mode: String) {
        let device = (side == "front") ? frontDevice : backDevice
        guard let dev = device, dev.isFocusModeSupported(.continuousAutoFocus) else { return }

        do {
            try dev.lockForConfiguration()
            // expo-camera: "on" = focus once and lock, "off" = continuous autofocus
            dev.focusMode = (mode == "on") ? .autoFocus : .continuousAutoFocus
            dev.unlockForConfiguration()
        } catch {}
    }

    // MARK: - Lens Selection

    private func backDeviceType() -> AVCaptureDevice.DeviceType {
        switch backLens {
        case "ultraWide": return .builtInUltraWideCamera
        case "telephoto": return .builtInTelephotoCamera
        default: return .builtInWideAngleCamera
        }
    }

    // MARK: - Session Lifecycle

    private func startIfReady() {
        guard let frontView = frontView, let backView = backView else { return }
        guard !isRunning else { return }

        // Don't restart while we're stopping the session
        if isStopping { return }

        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async { self?.startIfReady() }
                } else {
                    DispatchQueue.main.async {
                        self?.frontView?.showError("Camera permission denied")
                        self?.backView?.showError("Camera permission denied")
                    }
                }
            }
            return
        }

        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            frontView.showError("Multi-camera not supported")
            backView.showError("Multi-camera not supported")
            return
        }

        let session = AVCaptureMultiCamSession()

        guard let frontDev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let frontInput = try? AVCaptureDeviceInput(device: frontDev) else {
            frontView.showError("Front camera unavailable")
            return
        }

        let preferredType = backDeviceType()
        guard let backDev = AVCaptureDevice.default(preferredType, for: .video, position: .back)
                ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let backInput = try? AVCaptureDeviceInput(device: backDev) else {
            backView.showError("Back camera unavailable")
            return
        }

        // Capture strong refs for the closure
        let capturedFrontView = frontView
        let capturedBackView = backView

        sessionQueue.async { [weak self] in
            guard let self else { return }

            session.beginConfiguration()

            // --- Inputs ---
            if session.canAddInput(frontInput) { session.addInputWithNoConnections(frontInput) }
            if session.canAddInput(backInput) { session.addInputWithNoConnections(backInput) }

            // --- Video data outputs ---
            let frontOutput = AVCaptureVideoDataOutput()
            let backOutput = AVCaptureVideoDataOutput()
            if session.canAddOutput(frontOutput) { session.addOutputWithNoConnections(frontOutput) }
            if session.canAddOutput(backOutput) { session.addOutputWithNoConnections(backOutput) }

            // --- Photo outputs ---
            let frontPhoto = AVCapturePhotoOutput()
            let backPhoto = AVCapturePhotoOutput()
            if session.canAddOutput(frontPhoto) { session.addOutputWithNoConnections(frontPhoto) }
            if session.canAddOutput(backPhoto) { session.addOutputWithNoConnections(backPhoto) }

            guard let frontPort = frontInput.ports.first,
                  let backPort = backInput.ports.first else {
                DispatchQueue.main.async {
                    capturedFrontView.showError("Could not get camera ports")
                    capturedBackView.showError("Could not get camera ports")
                }
                return
            }

            // --- Video connections ---
            let frontVideoConn = AVCaptureConnection(inputPorts: [frontPort], output: frontOutput)
            let backVideoConn = AVCaptureConnection(inputPorts: [backPort], output: backOutput)
            if session.canAddConnection(frontVideoConn) { session.addConnection(frontVideoConn) }
            if session.canAddConnection(backVideoConn) { session.addConnection(backVideoConn) }

            // --- Photo connections ---
            let frontPhotoConn = AVCaptureConnection(inputPorts: [frontPort], output: frontPhoto)
            let backPhotoConn = AVCaptureConnection(inputPorts: [backPort], output: backPhoto)
            if session.canAddConnection(frontPhotoConn) { session.addConnection(frontPhotoConn) }
            if session.canAddConnection(backPhotoConn) { session.addConnection(backPhotoConn) }

            session.commitConfiguration()

            // --- Preview layers (must be on main thread for UIKit) ---
            DispatchQueue.main.async {
                let frontPreview = AVCaptureVideoPreviewLayer()
                frontPreview.setSessionWithNoConnection(session)
                let backPreview = AVCaptureVideoPreviewLayer()
                backPreview.setSessionWithNoConnection(session)

                let frontPreviewConn = AVCaptureConnection(inputPort: frontPort, videoPreviewLayer: frontPreview)
                if session.canAddConnection(frontPreviewConn) { session.addConnection(frontPreviewConn) }
                let backPreviewConn = AVCaptureConnection(inputPort: backPort, videoPreviewLayer: backPreview)
                if session.canAddConnection(backPreviewConn) { session.addConnection(backPreviewConn) }

                capturedFrontView.attachPreview(frontPreview)
                capturedBackView.attachPreview(backPreview)

                self.session = session
                self.frontDevice = frontDev
                self.backDevice = backDev
                self.frontPhotoOutput = frontPhoto
                self.backPhotoOutput = backPhoto

                // Start the session AFTER preview connections are wired up
                self.sessionQueue.async {
                    session.startRunning()

                    DispatchQueue.main.async {
                        if session.isRunning {
                            self.isRunning = true
                            self.isPaused = false
                            capturedFrontView.sessionDidStart()
                            capturedBackView.sessionDidStart()
                        } else {
                            capturedFrontView.showError("Failed to start camera session")
                            capturedBackView.showError("Failed to start camera session")
                        }
                    }
                }
            }
        }
    }

    private func stop() {
        guard !isStopping else { return }
        isStopping = true
        isRunning = false
        isPaused = false
        activePhotoDelegates.removeAll()

        sessionQueue.async { [weak self] in
            self?.session?.stopRunning()

            DispatchQueue.main.async {
                self?.isStopping = false
                self?.frontView?.detachPreview()
                self?.backView?.detachPreview()
                self?.session = nil
                self?.frontDevice = nil
                self?.backDevice = nil
                self?.frontPhotoOutput = nil
                self?.backPhotoOutput = nil
            }
        }
    }

    // MARK: - Pause / Resume

    func pausePreview() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        sessionQueue.async { [weak self] in
            self?.session?.stopRunning()
        }
    }

    func resumePreview() {
        guard isPaused else { return }
        isPaused = false
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session?.startRunning()

            DispatchQueue.main.async {
                if self.session?.isRunning == true {
                    self.frontView?.sessionDidStart()
                    self.backView?.sessionDidStart()
                } else {
                    self.frontView?.showError("Failed to resume camera session")
                    self.backView?.showError("Failed to resume camera session")
                }
            }
        }
    }

    // MARK: - Photo Capture

    func takePicture(side: String, options: CaptureOptions, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard isRunning, !isPaused else {
            completion(.failure(DualCameraError.sessionNotRunning))
            return
        }

        let output = (side == "front") ? frontPhotoOutput : backPhotoOutput
        guard let photoOutput = output else {
            completion(.failure(DualCameraError.noPhotoOutput))
            return
        }

        let delegateID = UUID()
        let delegate = PhotoCaptureDelegate(options: options) { [weak self] result in
            self?.activePhotoDelegates.removeValue(forKey: delegateID)
            completion(result)
        }
        activePhotoDelegates[delegateID] = delegate

        let settings = AVCapturePhotoSettings()
        if side == "back", photoOutput.supportedFlashModes.contains(flashMode) {
            settings.flashMode = flashMode
        }

        // Set video orientation for the photo connection
        if let connection = photoOutput.connection(with: .photo) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }

        sessionQueue.async {
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
}