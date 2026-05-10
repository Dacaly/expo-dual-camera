import ExpoModulesCore
import AVFoundation

public class ExpoDualCameraModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoDualCamera")

    AsyncFunction("isSupported") { () -> Bool in
      AVCaptureMultiCamSession.isMultiCamSupported
    }

    View(DualCameraView.self) {
      Prop("frontCamera") { (view: DualCameraView, config: [String: Any]) in
        view.setCamera(.front, config: config)
      }
      Prop("backCamera") { (view: DualCameraView, config: [String: Any]) in
        view.setCamera(.back, config: config)
      }
    }
  }
}