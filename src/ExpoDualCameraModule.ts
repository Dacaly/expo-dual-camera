import { NativeModule, requireNativeModule } from "expo";
import type { PermissionResponse } from "expo-modules-core";
import type {
  DualCameraCapturedPicture,
  DualCameraPictureOptions,
} from "./ExpoDualCamera.types";

declare class ExpoDualCameraModule extends NativeModule {
  isSupported(): Promise<boolean>;
  getCameraPermissionsAsync(): Promise<PermissionResponse>;
  requestCameraPermissionsAsync(): Promise<PermissionResponse>;
  takePictureAsync(
    side: "front" | "back",
    options?: DualCameraPictureOptions
  ): Promise<DualCameraCapturedPicture>;
  pausePreview(): void;
  resumePreview(): void;
}

export default requireNativeModule<ExpoDualCameraModule>("ExpoDualCamera");
