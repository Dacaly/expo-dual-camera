import ExpoModulesCore
import AVFoundation

public class ExpoDualCameraModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoDualCamera")

    AsyncFunction("isSupported") { () -> Bool in
      AVCaptureMultiCamSession.isMultiCamSupported
    }

    View(DualCameraView.self) {
      Prop("side") { (view: DualCameraView, side: String) in
        view.setSide(side)
      }
      Prop("lens") { (view: DualCameraView, lens: String) in
        view.setLens(lens)
      }
    }
  }
}