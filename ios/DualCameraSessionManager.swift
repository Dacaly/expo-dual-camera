import AVFoundation
import UIKit

class DualCameraSessionManager {
    static let shared = DualCameraSessionManager()

    private var session: AVCaptureMultiCamSession?
    private weak var frontView: DualCameraView?
    private weak var backView: DualCameraView?
    private var isRunning = false
    private var backLens: String = "wide"

    private let sessionQueue = DispatchQueue(label: "com.expodualcamera.session")

    private init() {}

    // MARK: - Registration

    func register(_ view: DualCameraView, side: String) {
        if side == "front" { frontView = view }
        else { backView = view }
        startIfReady()
    }

    func unregister(_ view: DualCameraView) {
        if view === frontView { frontView = nil }
        if view === backView { backView = nil }
        stop()
    }

    func setBackLens(_ lens: String) {
        guard lens != backLens else { return }
        backLens = lens
        if isRunning {
            stop()
            startIfReady()
        }
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

        guard let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let frontInput = try? AVCaptureDeviceInput(device: frontDevice) else {
            frontView.showError("Front camera unavailable")
            return
        }

        let preferredType = backDeviceType()
        guard let backDevice = AVCaptureDevice.default(preferredType, for: .video, position: .back)
                ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let backInput = try? AVCaptureDeviceInput(device: backDevice) else {
            backView.showError("Back camera unavailable")
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
                DispatchQueue.main.async {
                    frontView.showError("Could not get camera ports")
                    backView.showError("Could not get camera ports")
                }
                return
            }

            let frontConnection = AVCaptureConnection(inputPorts: [frontPort], output: frontOutput)
            let backConnection = AVCaptureConnection(inputPorts: [backPort], output: backOutput)
            if session.canAddConnection(frontConnection) { session.addConnection(frontConnection) }
            if session.canAddConnection(backConnection) { session.addConnection(backConnection) }

            session.commitConfiguration()

            DispatchQueue.main.async {
                let frontPreview = AVCaptureVideoPreviewLayer()
                frontPreview.setSessionWithNoConnection(session)

                let backPreview = AVCaptureVideoPreviewLayer()
                backPreview.setSessionWithNoConnection(session)

                let frontPreviewConn = AVCaptureConnection(inputPort: frontPort, videoPreviewLayer: frontPreview)
                if session.canAddConnection(frontPreviewConn) {
                    session.addConnection(frontPreviewConn)
                }

                let backPreviewConn = AVCaptureConnection(inputPort: backPort, videoPreviewLayer: backPreview)
                if session.canAddConnection(backPreviewConn) {
                    session.addConnection(backPreviewConn)
                }

                frontView.attachPreview(frontPreview)
                backView.attachPreview(backPreview)

                self.session = session
            }

            session.startRunning()

            DispatchQueue.main.async {
                self.isRunning = session.isRunning
                if !session.isRunning {
                    frontView.showError("Failed to start camera session")
                    backView.showError("Failed to start camera session")
                }
            }
        }
    }

    private func stop() {
        sessionQueue.async { [weak self] in
            self?.session?.stopRunning()

            DispatchQueue.main.async {
                self?.isRunning = false
                self?.frontView?.detachPreview()
                self?.backView?.detachPreview()
                self?.session = nil
            }
        }
    }
}