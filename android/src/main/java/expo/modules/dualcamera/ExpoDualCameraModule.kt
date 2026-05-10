package expo.modules.dualcamera

import android.Manifest
import android.content.pm.PackageManager
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.Promise

class ExpoDualCameraModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("ExpoDualCamera")

    AsyncFunction("isSupported") { promise: Promise ->
      val context = appContext.reactContext ?: run {
        promise.resolve(false); return@AsyncFunction
      }
      val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
      cameraProviderFuture.addListener({
        val provider = cameraProviderFuture.get()
        val supported = provider.availableConcurrentCameraInfos.isNotEmpty()
        promise.resolve(supported)
      }, ContextCompat.getMainExecutor(context))
    }

    View(DualCameraView::class) {
        Prop("frontCamera") { view: DualCameraView, config: Map<String, Any> ->
            view.setCameraConfig("front", config)
        }
        Prop("backCamera") { view: DualCameraView, config: Map<String, Any> ->
            view.setCameraConfig("back", config)
        }
    }

    AsyncFunction("checkCameraPermission") { promise: Promise ->
      val activity = appContext.activity ?: run {
        promise.reject("E_ACTIVITY", "Activity not found")
        return@AsyncFunction
      }

      val hasPermission = ContextCompat.checkSelfPermission(
        activity,
        Manifest.permission.CAMERA
      ) == PackageManager.PERMISSION_GRANTED

      promise.resolve(hasPermission)
    }

    AsyncFunction("requestCameraPermission") { promise: Promise ->
      val activity = appContext.activity ?: run {
        promise.reject("E_ACTIVITY", "Activity not found")
        return@AsyncFunction
      }

      val hasPermission = ContextCompat.checkSelfPermission(
        activity,
        Manifest.permission.CAMERA
      ) == PackageManager.PERMISSION_GRANTED

      if (hasPermission) {
        promise.resolve(true)
        return@AsyncFunction
      }

      val PERMISSION_REQUEST_CODE = 1001
      activity.requestPermissions(
        arrayOf(Manifest.permission.CAMERA),
        PERMISSION_REQUEST_CODE
      ) { result ->
        promise.resolve(result.isGranted)
      }
    }
  }
}
