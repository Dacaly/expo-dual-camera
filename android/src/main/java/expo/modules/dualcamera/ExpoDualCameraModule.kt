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

    // MARK: - Support Check

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

    // MARK: - Permissions

    AsyncFunction("checkCameraPermission") { promise: Promise ->
      val activity = appContext.activity ?: run {
        promise.reject("E_ACTIVITY", "Activity not found"); return@AsyncFunction
      }
      val hasPermission = ContextCompat.checkSelfPermission(
        activity, Manifest.permission.CAMERA
      ) == PackageManager.PERMISSION_GRANTED
      promise.resolve(hasPermission)
    }

    AsyncFunction("requestCameraPermission") { promise: Promise ->
      val activity = appContext.activity ?: run {
        promise.reject("E_ACTIVITY", "Activity not found"); return@AsyncFunction
      }
      val hasPermission = ContextCompat.checkSelfPermission(
        activity, Manifest.permission.CAMERA
      ) == PackageManager.PERMISSION_GRANTED
      if (hasPermission) {
        promise.resolve(true); return@AsyncFunction
      }
      val PERMISSION_REQUEST_CODE = 1001
      activity.requestPermissions(
        arrayOf(Manifest.permission.CAMERA), PERMISSION_REQUEST_CODE
      ) { result ->
        promise.resolve(result.isGranted)
      }
    }

    // MARK: - Photo Capture

    AsyncFunction("capturePhoto") { side: String, promise: Promise ->
      val context = appContext.reactContext ?: run {
        promise.reject("E_CONTEXT", "Context not available"); return@AsyncFunction
      }
      DualCameraSessionManager.capturePhoto(side, context) { result ->
        result.onSuccess { uri -> promise.resolve(uri) }
        result.onFailure { error ->
          promise.reject("E_CAPTURE", error.message ?: "Capture failed", error)
        }
      }
    }

    // MARK: - Session Control

    Function("pause") {
      DualCameraSessionManager.pause()
    }

    Function("resume") {
      DualCameraSessionManager.resume()
    }

    // MARK: - Torch

    Function("setTorch") { enabled: Boolean ->
      DualCameraSessionManager.setTorch(enabled)
    }

    // MARK: - Zoom

    Function("setZoom") { side: String, factor: Double ->
      DualCameraSessionManager.setZoom(side, factor.toFloat())
    }

    // MARK: - View

    View(DualCameraView::class) {
      Events("onReady", "onError")

      Prop("side") { view: DualCameraView, side: String ->
        view.setSide(side)
      }
      Prop("lens") { view: DualCameraView, lens: String ->
        view.setLens(lens)
      }
    }
  }
}
