import ExpoDualCameraModule from "./ExpoDualCameraModule";
export { DualCameraFront, DualCameraBack } from "./DualCameraView";
export type { DualCameraFrontProps, DualCameraBackProps } from "./ExpoDualCamera.types";

export async function isSupported(): Promise<boolean> {
  return await ExpoDualCameraModule.isSupported();
}
