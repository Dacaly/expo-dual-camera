import ExpoModulesCore

public class ExpoDualCameraModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoDualCamera")

    AsyncFunction("isSupported") { () -> Bool in
      AVCaptureMultiCamSession.isSupported
    }

    registerViewManager(ExpoDualCameraViewManager.self)
  }
}
