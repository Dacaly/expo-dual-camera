package expo.dualcamera;

import android.content.Context;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import expo.modules.core.AsyncFunction;
import expo.modules.core.ExpoModule;
import expo.modules.core.Promise;
import expo.modules.core.ModuleDefinition;

public class DualCameraModule extends ExpoModule {
  public DualCameraModule(Context context) {
    super(context);
  }

  @Override
  public ModuleDefinition definition() {
    return new ModuleDefinition(this)
      .asyncFunction("isSupported", this::isSupported);
  }

  private void isSupported(Promise promise) {
    CameraManager cameraManager = (CameraManager) getContext().getSystemService(Context.CAMERA_SERVICE);
    try {
      String[] cameraIds = cameraManager.getCameraIdList();
      boolean hasBack = false, hasFront = false;
      for (String id : cameraIds) {
        CameraCharacteristics chars = cameraManager.getCameraCharacteristics(id);
        Integer facing = chars.get(CameraCharacteristics.LENS_FACING);
        if (facing != null) {
          if (facing == CameraCharacteristics.LENS_FACING_BACK) hasBack = true;
          if (facing == CameraCharacteristics.LENS_FACING_FRONT) hasFront = true;
        }
      }
      promise.resolve(hasBack && hasFront);
    } catch (Exception e) {
      promise.resolve(false);
    }
  }
}
