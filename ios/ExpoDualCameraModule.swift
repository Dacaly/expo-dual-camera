import ExpoModulesCore
import AVFoundation

public class ExpoDualCameraModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoDualCamera")

    // MARK: - Support Check

    AsyncFunction("isSupported") { () -> Bool in
      AVCaptureMultiCamSession.isMultiCamSupported
    }

    // MARK: - Permissions

    AsyncFunction("checkCameraPermission") { () -> Bool in
      AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    AsyncFunction("requestCameraPermission") { (promise: Promise) in
      AVCaptureDevice.requestAccess(for: .video) { granted in
        promise.resolve(granted)
      }
    }

    // MARK: - Photo Capture

    AsyncFunction("capturePhoto") { (side: String, promise: Promise) in
      DualCameraSessionManager.shared.capturePhoto(side: side) { result in
        switch result {
        case .success(let uri):
          promise.resolve(uri)
        case .failure(let error):
          promise.reject("E_CAPTURE", error.localizedDescription)
        }
      }
    }

    // MARK: - Session Control

    Function("pause") {
      DualCameraSessionManager.shared.pause()
    }

    Function("resume") {
      DualCameraSessionManager.shared.resume()
    }

    // MARK: - Torch

    Function("setTorch") { (enabled: Bool) in
      try DualCameraSessionManager.shared.setTorch(enabled)
    }

    // MARK: - Zoom

    Function("setZoom") { (side: String, factor: Double) in
      DualCameraSessionManager.shared.setZoom(side: side, factor: factor)
    }

    // MARK: - View

    View(DualCameraView.self) {
      Events("onReady", "onError")

      Prop("side") { (view: DualCameraView, side: String) in
        view.setSide(side)
      }
      Prop("lens") { (view: DualCameraView, lens: String) in
        view.setLens(lens)
      }
    }
  }
}
