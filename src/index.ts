import { createPermissionHook } from "expo-modules-core";
import type { PermissionResponse } from "expo-modules-core";

import ExpoDualCameraModule from "./ExpoDualCameraModule";
import type {
  DualCameraCapturedPicture,
  DualCameraPictureOptions,
} from "./ExpoDualCamera.types";

export { DualCameraFrontView, DualCameraBackView } from "./DualCameraView";
export type {
  DualCameraFrontViewProps,
  DualCameraBackViewProps,
  DualCameraCapturedPicture,
  DualCameraPictureOptions,
  FlashMode,
  FocusMode,
  CameraMountError,
  PermissionResponse,
} from "./ExpoDualCamera.types";
export { useIsDualCameraReady } from "./useIsDualCameraReady";

/** Check if the device supports simultaneous front + back cameras. */
export async function isSupported(): Promise<boolean> {
  return await ExpoDualCameraModule.isSupported();
}

/** Checks user's permissions for accessing camera. */
export async function getCameraPermissionsAsync(): Promise<PermissionResponse> {
  return await ExpoDualCameraModule.getCameraPermissionsAsync();
}

/** Asks the user to grant permissions for accessing camera. */
export async function requestCameraPermissionsAsync(): Promise<PermissionResponse> {
  return await ExpoDualCameraModule.requestCameraPermissionsAsync();
}

/**
 * Check or request permissions to access the camera.
 *
 * @example
 * ```ts
 * const [status, requestPermission] = useCameraPermissions();
 * ```
 */
export const useCameraPermissions = createPermissionHook({
  getMethod: getCameraPermissionsAsync,
  requestMethod: requestCameraPermissionsAsync,
});

/**
 * Capture a photo from the specified camera.
 * @returns An object containing the file `uri`, `width`, and `height`.
 */
export async function takePictureAsync(
  side: "front" | "back",
  options?: DualCameraPictureOptions
): Promise<DualCameraCapturedPicture> {
  return await ExpoDualCameraModule.takePictureAsync(side, options);
}

/** Pause the camera session without tearing it down. */
export function pausePreview(): void {
  ExpoDualCameraModule.pausePreview();
}

/** Resume a paused camera session. Fires `onCameraReady` again on both views. */
export function resumePreview(): void {
  ExpoDualCameraModule.resumePreview();
}
