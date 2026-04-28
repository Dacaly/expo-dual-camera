import { requireNativeView } from 'expo-modules-core';

export interface Frame {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface DualCameraProps {
  frontFrame: Frame;
  backFrame: Frame;
  frontGravity?: 'resize' | 'resizeAspect' | 'resizeAspectFill';
  backGravity?: 'resize' | 'resizeAspect' | 'resizeAspectFill';
}

const NativeDualCamera = requireNativeView<DualCameraProps>('DualCamera');

export default NativeDualCamera;

export async function isSupported(): Promise<boolean> {
  return NativeDualCamera.isSupported?.() ?? false;
}
