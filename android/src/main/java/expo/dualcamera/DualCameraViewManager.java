package expo.dualcamera;

import android.app.Activity;
import android.content.Context;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.core.content.ContextCompat;
import androidx.lifecycle.LifecycleOwner;
import androidx.camera.view.PreviewView;
import com.google.common.util.concurrent.ListenableFuture;
import expo.modules.core.ModuleDefinition;
import expo.modules.core.view.ViewManager;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

public class DualCameraViewManager extends ViewManager {
  private PreviewView frontPreviewView;
  private PreviewView backPreviewView;
  private ProcessCameraProvider cameraProvider;
  private Activity activity;
  private LifecycleOwner lifecycleOwner;

  @Override
  public String getName() { return "DualCamera"; }

  @Override
  public View createViewInstance(Context context) {
    if (!(context instanceof Activity)) {
      throw new IllegalStateException("DualCameraViewManager requires an Activity context");
    }
    if (!(context instanceof LifecycleOwner)) {
      throw new IllegalStateException("DualCameraViewManager requires a LifecycleOwner context");
    }

    activity = (Activity) context;
    lifecycleOwner = (LifecycleOwner) context;

    FrameLayout container = new FrameLayout(context);
    container.setLayoutParams(new ViewGroup.LayoutParams(
      ViewGroup.LayoutParams.MATCH_PARENT,
      ViewGroup.LayoutParams.MATCH_PARENT
    ));

    frontPreviewView = new PreviewView(context);
    backPreviewView = new PreviewView(context);

    FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
      FrameLayout.LayoutParams.MATCH_PARENT,
      FrameLayout.LayoutParams.MATCH_PARENT
    );

    container.addView(frontPreviewView, 0, params);
    container.addView(backPreviewView, 1, params);

    startCamera();

    return container;
  }

  private void startCamera() {
    if (activity == null || lifecycleOwner == null) return;

    ListenableFuture<ProcessCameraProvider> cameraProviderFuture =
      ProcessCameraProvider.getInstance(activity);

    cameraProviderFuture.addListener(() -> {
      try {
        cameraProvider = cameraProviderFuture.get();

        Preview frontPreview = new Preview.Builder().build();
        Preview backPreview = new Preview.Builder().build();

        frontPreview.setSurfaceProvider(frontPreviewView.getSurfaceProvider());
        backPreview.setSurfaceProvider(backPreviewView.getSurfaceProvider());

        CameraSelector frontSelector = new CameraSelector.Builder()
          .requireLensFacing(CameraSelector.LENS_FACING_FRONT)
          .build();

        CameraSelector backSelector = new CameraSelector.Builder()
          .requireLensFacing(CameraSelector.LENS_FACING_BACK)
          .build();

        cameraProvider.unbindAll();

        try {
          cameraProvider.bindToLifecycle(
            lifecycleOwner,
            frontSelector,
            frontPreview
          );
        } catch (Exception e) {
          android.util.Log.e("DualCamera", "Failed to bind front camera", e);
        }

        try {
          cameraProvider.bindToLifecycle(
            lifecycleOwner,
            backSelector,
            backPreview
          );
        } catch (Exception e) {
          android.util.Log.e("DualCamera", "Failed to bind back camera", e);
        }
      } catch (ExecutionException | InterruptedException e) {
        android.util.Log.e("DualCamera", "Failed to get camera provider", e);
      }
    }, ContextCompat.getMainExecutor(activity));
  }

  @Override
  public Map<String, Object> getConstants() {
    return new HashMap<>();
  }

  @Override
  public void setProps(View view, Map<String, Object> props) {
    if (!(view instanceof FrameLayout)) return;

    FrameLayout container = (FrameLayout) view;

    if (props.containsKey("frontFrame")) {
      final Map<String, Object> frame = (Map<String, Object>) props.get("frontFrame");
      container.post(() -> {
        int x = getInt(frame, "x", 0);
        int y = getInt(frame, "y", 0);
        int width = getInt(frame, "width", container.getWidth() / 2);
        int height = getInt(frame, "height", container.getHeight());
        frontPreviewView.layout(x, y, x + width, y + height);
      });
    }

    if (props.containsKey("backFrame")) {
      final Map<String, Object> frame = (Map<String, Object>) props.get("backFrame");
      container.post(() -> {
        int x = getInt(frame, "x", container.getWidth() / 2);
        int y = getInt(frame, "y", 0);
        int width = getInt(frame, "width", container.getWidth() / 2);
        int height = getInt(frame, "height", container.getHeight());
        backPreviewView.layout(x, y, x + width, y + height);
      });
    }
  }

  private int getInt(Map<String, Object> map, String key, int defaultValue) {
    Object value = map.get(key);
    if (value instanceof Number) {
      return ((Number) value).intValue();
    }
    return defaultValue;
  }

  @Override
  protected ModuleDefinition getTypedExportedModule() {
    return null;
  }
}
