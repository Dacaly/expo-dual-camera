import AVFoundation
import UIKit
import ExpoModulesCore

public final class DualCameraView: UIView {
  private var multiCamSession: AVCaptureMultiCamSession?
  private var frontPreviewLayer: AVCaptureVideoPreviewLayer?
  private var backPreviewLayer: AVCaptureVideoPreviewLayer?

  // Styling props
  public var frontFrame: CGRect = .zero { didSet { updateFrontFrame() } }
  public var backFrame: CGRect = .zero { didSet { updateBackFrame() } }
  public var frontGravity: String = "resizeAspectFill" { didSet { updateFrontGravity() } }
  public var backGravity: String = "resizeAspectFill" { didSet { updateBackGravity() } }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .black
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func startDualCamera() {
    guard AVCaptureMultiCamSession.isMultiCamSupported else { return }

    let session = AVCaptureMultiCamSession()

    guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
          let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }

    do {
      let frontInput = try AVCaptureDeviceInput(device: frontCamera)
      let backInput = try AVCaptureDeviceInput(device: backCamera)

      let frontOutput = AVCaptureVideoDataOutput()
      frontOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

      let backOutput = AVCaptureVideoDataOutput()
      backOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

      session.beginConfiguration()

      if session.canAddInput(frontInput) { session.addInputWithNoConnections(frontInput) }
      if session.canAddInput(backInput) { session.addInputWithNoConnections(backInput) }
      if session.canAddOutput(frontOutput) { session.addOutputWithNoConnections(frontOutput) }
      if session.canAddOutput(backOutput) { session.addOutputWithNoConnections(backOutput) }

      let frontPreview = AVCaptureVideoPreviewLayer()
      frontPreview.setSessionWithNoConnection(session)
      frontPreview.videoGravity = .resizeAspectFill

      let backPreview = AVCaptureVideoPreviewLayer()
      backPreview.setSessionWithNoConnection(session)
      backPreview.videoGravity = .resizeAspectFill

      if let frontPort = frontInput.ports.first(where: { $0.sourceDeviceType == .builtInWideAngleCamera && $0.sourceDevicePosition == .front }),
         let frontConn = session.addConnection(AVCaptureConnection(inputPorts: [frontPort], output: frontOutput)) {
        frontConn.videoOrientation = .portrait
        frontPreview.addConnectedConnection(frontConn)
      }

      if let backPort = backInput.ports.first(where: { $0.sourceDeviceType == .builtInWideAngleCamera && $0.sourceDevicePosition == .back }),
         let backConn = session.addConnection(AVCaptureConnection(inputPorts: [backPort], output: backOutput)) {
        backConn.videoOrientation = .portrait
        backPreview.addConnectedConnection(backConn)
      }

      session.commitConfiguration()

      self.frontPreviewLayer = frontPreview
      self.backPreviewLayer = backPreview

      DispatchQueue.main.async {
        self.updateFrontFrame()
        self.updateBackFrame()
      }

      if let frontLayer = self.frontPreviewLayer, let backLayer = self.backPreviewLayer {
        layer.addSublayer(frontLayer)
        layer.addSublayer(backLayer)
      }

      DispatchQueue.global(qos: .userInitiated).async {
        session.startRunning()
      }

      self.multiCamSession = session
    } catch {
      print("DualCamera Error: \(error.localizedDescription)")
    }
  }

  private func updateFrontFrame() {
    DispatchQueue.main.async {
      self.frontPreviewLayer?.frame = self.frontFrame
    }
  }

  private func updateBackFrame() {
    DispatchQueue.main.async {
      self.backPreviewLayer?.frame = self.backFrame
    }
  }

  private func updateFrontGravity() {
    DispatchQueue.main.async {
      self.frontPreviewLayer?.videoGravity = self.gravityFromString(self.frontGravity)
    }
  }

  private func updateBackGravity() {
    DispatchQueue.main.async {
      self.backPreviewLayer?.videoGravity = self.gravityFromString(self.backGravity)
    }
  }

  private func gravityFromString(_ gravity: String) -> AVLayerVideoGravity {
    switch gravity {
    case "resize": return .resize
    case "resizeAspect": return .resizeAspect
    default: return .resizeAspectFill
    }
  }

  public func stopDualCamera() {
    multiCamSession?.stopRunning()
    multiCamSession = nil
    frontPreviewLayer?.removeFromSuperlayer()
    backPreviewLayer?.removeFromSuperlayer()
    frontPreviewLayer = nil
    backPreviewLayer = nil
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    updateFrontFrame()
    updateBackFrame()
  }
}

public final class DualCameraModule: Module {
  public func definition() -> ModuleDefinition {
    Name("DualCamera")

    View(DualCameraView.self) {
      Prop("frontFrame") { (view, frame: [String: CGFloat]) in
        let x = frame["x"] ?? 0
        let y = frame["y"] ?? 0
        let width = frame["width"] ?? view.bounds.width
        let height = frame["height"] ?? view.bounds.height
        view.frontFrame = CGRect(x: x, y: y, width: width, height: height)
      }

      Prop("backFrame") { (view, frame: [String: CGFloat]) in
        let x = frame["x"] ?? 0
        let y = frame["y"] ?? 0
        let width = frame["width"] ?? view.bounds.width
        let height = frame["height"] ?? view.bounds.height
        view.backFrame = CGRect(x: x, y: y, width: width, height: height)
      }

      Prop("frontGravity") { (view, gravity: String) in
        view.frontGravity = gravity
      }

      Prop("backGravity") { (view, gravity: String) in
        view.backGravity = gravity
      }

      DidStartProspectiveDirectory {
        view.startDualCamera()
      }

      DidStopProspectiveDirectory {
        view.stopDualCamera()
      }
    }

    AsyncFunction("isSupported") { resolve, reject in
      resolve(AVCaptureMultiCamSession.isMultiCamSupported)
    }
  }
}
