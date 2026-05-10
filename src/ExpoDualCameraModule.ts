import { NativeModule, requireNativeModule } from "expo";

declare class ExpoDualCameraModule extends NativeModule {
  isSupported(): Promise<boolean>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoDualCameraModule>("ExpoDualCamera");
