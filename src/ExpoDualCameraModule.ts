import { NativeModule, requireNativeModule } from 'expo';

import { ExpoDualCameraModuleEvents } from './ExpoDualCamera.types';

declare class ExpoDualCameraModule extends NativeModule<ExpoDualCameraModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoDualCameraModule>('ExpoDualCamera');
