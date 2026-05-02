import { registerWebModule, NativeModule } from 'expo';

import { ExpoDualCameraModuleEvents } from './ExpoDualCamera.types';

class ExpoDualCameraModule extends NativeModule<ExpoDualCameraModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ExpoDualCameraModule, 'ExpoDualCameraModule');
