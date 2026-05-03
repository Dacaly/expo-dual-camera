import UIKit
import AVFoundation

@objc(ExpoDualCameraView)
public class DualCameraView: UIView {

    // MARK: - Properties

    private var multiCamSession: AVCaptureMultiCamSession?
    private var frontPreviewLayer: AVCaptureVideoPreviewLayer?
    private var backPreviewLayer: AVCaptureVideoPreviewLayer?
    private var isSessionRunning = false

    private var frontFrame: CGRect = .zero
    private var backFrame: CGRect = .zero
    private var frontGravity: AVCaptureVideoPreviewLayer.Gravity = .resizeAspectFill
    private var backGravity: AVCaptureVideoPreviewLayer.Gravity = .resizeAspectFill

    private var errorLabel: UILabel?
    private var hasError = false

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
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
        frontPreviewLayer?.frame = frontFrame
        backPreviewLayer?.frame = backFrame
        errorLabel?.frame = bounds
    }

    // MARK: - Prop Setters

    public var frontFrameProp: [String: CGFloat] = [:] {
        didSet {
            frontFrame = CGRect(
                x: frontFrameProp["x"] ?? 0,
                y: frontFrameProp["y"] ?? 0,
                width: frontFrameProp["width"] ?? 0,
                height: frontFrameProp["height"] ?? 0
            )
            frontPreviewLayer?.frame = frontFrame
        }
    }

    public var backFrameProp: [String: CGFloat] = [:] {
        didSet {
            backFrame = CGRect(
                x: backFrameProp["x"] ?? 0,
                y: backFrameProp["y"] ?? 0,
                width: backFrameProp["width"] ?? 0,
                height: backFrameProp["height"] ?? 0
            )
            backPreviewLayer?.frame = backFrame
        }
    }

    public var frontGravityProp: String = "resizeAspectFill" {
        didSet {
            frontGravity = gravityFromString(frontGravityProp)
            frontPreviewLayer?.videoGravity = frontGravity
        }
    }

    public var backGravityProp: String = "resizeAspectFill" {
        didSet {
            backGravity = gravityFromString(backGravityProp)
            backPreviewLayer?.videoGravity = backGravity
        }
    }

    private func gravityFromString(_ gravity: String) -> AVCaptureVideoPreviewLayer.Gravity {
        switch gravity {
        case "resize":
            return .resize
        case "resizeAspect":
            return .resizeAspect
        case "resizeAspectFill":
            return .resizeAspectFill
        default:
            return .resizeAspectFill
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

    private func startMultiCamSession() {
        guard AVCaptureMultiCamSession.isSupported else {
            showError("Multi-camera not supported on this device")
            return
        }

        stopCamera()

        let session = AVCaptureMultiCamSession()

        guard let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let frontInput = try? AVCaptureDeviceInput(device: frontDevice) else {
            showError("Front camera unavailable")
            return
        }

        guard let backDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let backInput = try? AVCaptureDeviceInput(device: backDevice) else {
            showError("Back camera unavailable")
            return
        }

        session.beginConfiguration()

        if session.canAddInput(frontInput) {
            session.addInputWithNoConnections(frontInput)
        }
        let frontOutput = AVCaptureVideoDataOutput()
        frontOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        if session.canAddOutput(frontOutput) {
            session.addOutputWithNoConnections(frontOutput)
        }

        if session.canAddInput(backInput) {
            session.addInputWithNoConnections(backInput)
        }
        let backOutput = AVCaptureVideoDataOutput()
        backOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        if session.canAddOutput(backOutput) {
            session.addOutputWithNoConnections(backOutput)
        }

        guard let frontPort = frontInput.ports.first,
              let backPort = backInput.ports.first else {
            showError("Could not get camera ports")
            return
        }

        let frontConnection = AVCaptureConnection(inputPorts: [frontPort], output: frontOutput)
        if session.canAddConnection(frontConnection) {
            session.addConnection(frontConnection)
        }

        let backConnection = AVCaptureConnection(inputPorts: [backPort], output: backOutput)
        if session.canAddConnection(backConnection) {
            session.addConnection(backConnection)
        }

        session.commitConfiguration()

        let frontPreview = AVCaptureVideoPreviewLayer(session: session, qsPort: frontPort)
        frontPreview.videoGravity = frontGravity
        frontPreview.frame = frontFrame

        let backPreview = AVCaptureVideoPreviewLayer(session: session, qsPort: backPort)
        backPreview.videoGravity = backGravity
        backPreview.frame = backFrame

        layer.insertSublayer(backPreview, at: 0)
        layer.insertSublayer(frontPreview, at: 0)

        self.frontPreviewLayer = frontPreview
        self.backPreviewLayer = backPreview
        self.multiCamSession = session

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = session.isRunning
                if !session.isRunning {
                    self?.showError("Failed to start camera session")
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