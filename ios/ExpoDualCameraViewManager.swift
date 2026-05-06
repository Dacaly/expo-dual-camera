import ExpoModulesCore

public class ExpoDualCameraViewManager: Module {

  public func definition() -> ModuleDefinition {
    Name("ExpoDualCamera")

    View(ExpoDualCameraView.self) {
      ViewName("ExpoDualCamera")

      Prop("frontFrame") { (view: ExpoDualCameraView, frame: [String: CGFloat]) in
        view.frontFrameProp = frame
      }

      Prop("backFrame") { (view: ExpoDualCameraView, frame: [String: CGFloat]) in
        view.backFrameProp = frame
      }

      Prop("frontGravity") { (view: ExpoDualCameraView, gravity: String) in
        view.frontGravityProp = gravity
      }

      Prop("backGravity") { (view: ExpoDualCameraView, gravity: String) in
        view.backGravityProp = gravity
      }
    }
  }
}