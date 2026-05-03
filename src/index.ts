import ExpoDualCameraModule from './ExpoDualCameraModule';
import type { DualCameraProps } from './ExpoDualCamera.types';
export { DualCamera } from './DualCameraView';

export async function isSupported(): Promise<boolean> {
  return await ExpoDualCameraModule.isSupported();
}

export type { DualCameraProps };
