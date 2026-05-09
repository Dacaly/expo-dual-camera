import ExpoModulesCore
import AVFoundation

public class ExpoDualCameraModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoDualCamera")

    AsyncFunction("isSupported") { () -> Bool in
      AVCaptureMultiCamSession.isMultiCamSupported
    }

    View(DualCameraView.self) {
      ViewName("ExpoDualCamera")

      Prop("frontFrame") { (view: DualCameraView, frame: [String: CGFloat]) in
        view.frontFrameProp = frame
      }
      Prop("backFrame") { (view: DualCameraView, frame: [String: CGFloat]) in
        view.backFrameProp = frame
      }
      Prop("frontGravity") { (view: DualCameraView, gravity: String) in
        view.frontGravityProp = gravity
      }
      Prop("backGravity") { (view: DualCameraView, gravity: String) in
        view.backGravityProp = gravity
      }
    }
  }
}