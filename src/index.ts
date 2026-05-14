import ExpoDualCameraModule from "./ExpoDualCameraModule";

export { DualCameraFront, DualCameraBack } from "./DualCameraView";
export type { DualCameraFrontProps, DualCameraBackProps } from "./ExpoDualCamera.types";
export { useIsDualCameraReady } from "./useIsDualCameraReady";

/** Check if the device supports simultaneous front + back cameras. */
export async function isSupported(): Promise<boolean> {
  return await ExpoDualCameraModule.isSupported();
}

/** Check if camera permission has been granted. */
export async function checkCameraPermission(): Promise<boolean> {
  return await ExpoDualCameraModule.checkCameraPermission();
}

/** Request camera permission. Returns `true` if granted. */
export async function requestCameraPermission(): Promise<boolean> {
  return await ExpoDualCameraModule.requestCameraPermission();
}

/**
 * Capture a photo from the specified camera.
 * @returns A file URI pointing to a temporary JPEG.
 */
export async function capturePhoto(
  side: "front" | "back"
): Promise<string> {
  return await ExpoDualCameraModule.capturePhoto(side);
}

/** Pause the camera session without tearing it down. */
export function pause(): void {
  ExpoDualCameraModule.pause();
}

/** Resume a paused camera session. Fires `onReady` again on both views. */
export function resume(): void {
  ExpoDualCameraModule.resume();
}

/** Enable or disable the torch (back camera only). */
export function setTorch(enabled: boolean): void {
  ExpoDualCameraModule.setTorch(enabled);
}

/**
 * Set the zoom factor for a camera.
 * @param side  Which camera to zoom.
 * @param factor  Zoom multiplier (1.0 = no zoom). Clamped to device limits.
 */
export function setZoom(side: "front" | "back", factor: number): void {
  ExpoDualCameraModule.setZoom(side, factor);
}
