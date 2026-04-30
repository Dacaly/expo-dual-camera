import { requireNativeViewManager, requireOptionalNativeModule } from 'expo-modules-core';

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

const NativeDualCamera = requireNativeViewManager<DualCameraProps>('DualCamera');

export default NativeDualCamera;

// Use native isSupported from the module
export async function isSupported(): Promise<boolean> {
  try {
    const module = requireOptionalNativeModule<{ isSupported: () => Promise<boolean> }>('DualCamera');
    if (module && typeof module.isSupported === 'function') {
      return await module.isSupported();
    }
  } catch {
    // Ignore errors
  }
  return false;
}
