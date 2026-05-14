import { NativeModule, requireNativeModule } from "expo";

declare class ExpoDualCameraModule extends NativeModule {
  isSupported(): Promise<boolean>;
  checkCameraPermission(): Promise<boolean>;
  requestCameraPermission(): Promise<boolean>;
  capturePhoto(side: "front" | "back"): Promise<string>;
  pause(): void;
  resume(): void;
  setTorch(enabled: boolean): void;
  setZoom(side: "front" | "back", factor: number): void;
}

export default requireNativeModule<ExpoDualCameraModule>("ExpoDualCamera");
