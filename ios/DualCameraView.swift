import ExpoModulesCore
import UIKit
import AVFoundation

public class DualCameraView: ExpoView {

    // MARK: - Properties

    private var multiCamSession: AVCaptureMultiCamSession?
    private var frontPreviewLayer: AVCaptureVideoPreviewLayer?
    private var backPreviewLayer: AVCaptureVideoPreviewLayer?
    private var isSessionRunning = false

    enum CameraSide {
        case front, back
    }

    private struct CameraConfig {
        var frame: CGRect = .zero
        var zIndex: CGFloat = 0
        var borderRadius: CGFloat = 0
        var gravity: AVLayerVideoGravity = .resizeAspectFill
    }

    private var frontConfig = CameraConfig()
    private var backConfig = CameraConfig()

    private var errorLabel: UILabel?
    private var hasError = false

    // MARK: - Initialization

    public required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
        backgroundColor = .black
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle (Visibility-based camera control)

    public override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil {
            startCameraIfAllowed()
        } else {
            stopCamera()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updatePreviewLayerFrames()
    }

    // MARK: - Frame Calculations

    private func updatePreviewLayerFrames() {
        frontPreviewLayer?.frame = frontConfig.frame
        backPreviewLayer?.frame = backConfig.frame
        errorLabel?.frame = bounds
    }

    // MARK: - Prop Setters

    public func setCamera(_ side: CameraSide, config: [String: Any]) {
        let x = config["x"] as? CGFloat ?? 0
        let y = config["y"] as? CGFloat ?? 0
        let w = config["width"] as? CGFloat ?? 0
        let h = config["height"] as? CGFloat ?? 0
        let zIndex = config["zIndex"] as? CGFloat ?? 0
        let borderRadius = config["borderRadius"] as? CGFloat ?? 0
        let objectFit = config["objectFit"] as? String ?? "cover"

        let gravity: AVLayerVideoGravity = switch objectFit {
            case "contain": .resizeAspect
            case "fill": .resize
            default: .resizeAspectFill
        }

        let cfg = CameraConfig(
            frame: CGRect(x: x, y: y, width: w, height: h),
            zIndex: zIndex,
            borderRadius: borderRadius,
            gravity: gravity
        )

        switch side {
        case .front:
            frontConfig = cfg
            frontPreviewLayer?.frame = cfg.frame
            frontPreviewLayer?.videoGravity = cfg.gravity
            frontPreviewLayer?.cornerRadius = cfg.borderRadius
            frontPreviewLayer?.masksToBounds = cfg.borderRadius > 0
            frontPreviewLayer?.zPosition = cfg.zIndex
        case .back:
            backConfig = cfg
            backPreviewLayer?.frame = cfg.frame
            backPreviewLayer?.videoGravity = cfg.gravity
            backPreviewLayer?.cornerRadius = cfg.borderRadius
            backPreviewLayer?.masksToBounds = cfg.borderRadius > 0
            backPreviewLayer?.zPosition = cfg.zIndex
        }
    }

    // MARK: - Camera Control

    private func startCameraIfAllowed() {
        checkCameraAuthorization { [weak self] granted in
            guard granted else {
                DispatchQueue.main.async {
                    self?.showError("Camera permission denied")
                }
                return
            }

            DispatchQueue.main.async {
                self?.startMultiCamSession()
            }
        }
    }

    private func checkCameraAuthorization(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private let sessionQueue = DispatchQueue(label: "com.expodualcamera.session")


    private func startMultiCamSession() {
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            showError("Multi-camera not supported on this device")
            return
        }

        stopCamera()

        let session = AVCaptureMultiCamSession()

        guard let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let frontInput = try? AVCaptureDeviceInput(device: frontDevice),
            let backDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let backInput = try? AVCaptureDeviceInput(device: backDevice) else {
            showError("Camera unavailable")
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else { return }

            session.beginConfiguration()

            if session.canAddInput(frontInput) { session.addInputWithNoConnections(frontInput) }
            if session.canAddInput(backInput) { session.addInputWithNoConnections(backInput) }

            let frontOutput = AVCaptureVideoDataOutput()
            let backOutput = AVCaptureVideoDataOutput()
            if session.canAddOutput(frontOutput) { session.addOutputWithNoConnections(frontOutput) }
            if session.canAddOutput(backOutput) { session.addOutputWithNoConnections(backOutput) }

            guard let frontPort = frontInput.ports.first,
                let backPort = backInput.ports.first else {
                DispatchQueue.main.async { self.showError("Could not get camera ports") }
                return
            }

            let frontConnection = AVCaptureConnection(inputPorts: [frontPort], output: frontOutput)
            let backConnection = AVCaptureConnection(inputPorts: [backPort], output: backOutput)
            if session.canAddConnection(frontConnection) { session.addConnection(frontConnection) }
            if session.canAddConnection(backConnection) { session.addConnection(backConnection) }

            session.commitConfiguration()

            // Capture ports for preview layer creation on main thread
            DispatchQueue.main.async {
                // Create preview layers without auto-connections
                let frontPreview = AVCaptureVideoPreviewLayer()
                frontPreview.setSessionWithNoConnection(session)
                frontPreview.videoGravity = self.frontGravity
                frontPreview.frame = self.frontFrame

                let backPreview = AVCaptureVideoPreviewLayer()
                backPreview.setSessionWithNoConnection(session)
                backPreview.videoGravity = self.backGravity
                backPreview.frame = self.backFrame

                // Explicitly connect each port to its preview layer
                let frontPreviewConnection = AVCaptureConnection(inputPort: frontPort, videoPreviewLayer: frontPreview)
                if session.canAddConnection(frontPreviewConnection) {
                    session.addConnection(frontPreviewConnection)
                }

                let backPreviewConnection = AVCaptureConnection(inputPort: backPort, videoPreviewLayer: backPreview)
                if session.canAddConnection(backPreviewConnection) {
                    session.addConnection(backPreviewConnection)
                }

                self.layer.addSublayer(backPreview)
                self.layer.addSublayer(frontPreview)
                self.frontPreviewLayer = frontPreview
                self.backPreviewLayer = backPreview
                self.multiCamSession = session
                self.setCamera(.front, config: [:])
                self.setCamera(.back, config: [:])
            }

            session.startRunning()

            DispatchQueue.main.async {
                self.isSessionRunning = session.isRunning
                if !session.isRunning {
                    self.showError("Failed to start camera session")
                }
            }
        }
    }

    private func stopCamera() {
        multiCamSession?.stopRunning()
        isSessionRunning = false

        frontPreviewLayer?.removeFromSuperlayer()
        backPreviewLayer?.removeFromSuperlayer()
        frontPreviewLayer = nil
        backPreviewLayer = nil
        multiCamSession = nil
    }

    // MARK: - Error Handling

    private func showError(_ message: String) {
        hasError = true

        if errorLabel == nil {
            let label = UILabel()
            label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 14, weight: .medium)
            addSubview(label)
            errorLabel = label
        }

        errorLabel?.text = message
        errorLabel?.frame = bounds

        frontPreviewLayer?.isHidden = true
        backPreviewLayer?.isHidden = true
    }

    // MARK: - Cleanup

    deinit {
        stopCamera()
    }
}