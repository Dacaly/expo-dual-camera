package expo.modules.dualcamera

import android.content.Context
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import java.lang.ref.WeakReference

object DualCameraSessionManager {
    private var frontView: WeakReference<DualCameraView>? = null
    private var backView: WeakReference<DualCameraView>? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var backCamera: Camera? = null
    private var currentBackLens: String = "wide"
    private var isRunning = false

    fun register(view: DualCameraView, side: String, context: Context) {
        if (side == "front") frontView = WeakReference(view)
        else backView = WeakReference(view)

        if (cameraProvider == null) {
            val future = ProcessCameraProvider.getInstance(context)
            future.addListener({
                cameraProvider = future.get()
                startIfReady(context)
            }, ContextCompat.getMainExecutor(context))
        } else {
            startIfReady(context)
        }
    }

    fun unregister(view: DualCameraView) {
        if (frontView?.get() === view) frontView = null
        if (backView?.get() === view) backView = null
        stop()
    }

    fun setBackLens(lens: String, context: Context) {
        if (lens == currentBackLens) return
        currentBackLens = lens
        if (isRunning) {
            stop()
            startIfReady(context)
        }
    }

    private fun startIfReady(context: Context) {
        val front = frontView?.get() ?: return
        val back = backView?.get() ?: return
        val provider = cameraProvider ?: return
        val lifecycleOwner = context as? LifecycleOwner ?: return

        try {
            provider.unbindAll()

            val backPreviewUseCase = Preview.Builder().build()
                .also { it.surfaceProvider = back.getPreviewView().surfaceProvider }

            val frontPreviewUseCase = Preview.Builder().build()
                .also { it.surfaceProvider = front.getPreviewView().surfaceProvider }

            val backSelector = CameraSelector.Builder()
                .requireLensFacing(CameraSelector.LENS_FACING_BACK).build()
            val frontSelector = CameraSelector.Builder()
                .requireLensFacing(CameraSelector.LENS_FACING_FRONT).build()

            backCamera = provider.bindToLifecycle(lifecycleOwner, backSelector, backPreviewUseCase)
            provider.bindToLifecycle(lifecycleOwner, frontSelector, frontPreviewUseCase)

            applyBackLensZoom()

            front.showPreview()
            back.showPreview()
            isRunning = true

        } catch (e: Exception) {
            front.showError("Failed to start cameras: ${e.message}")
            back.showError("Failed to start cameras: ${e.message}")
        }
    }

    private fun applyBackLensZoom() {
        val camera = backCamera ?: return
        val zoomState = camera.cameraInfo.zoomState.value ?: return
        val minZoom = zoomState.minZoomRatio
        val maxZoom = zoomState.maxZoomRatio

        val targetRatio = when (currentBackLens) {
            "ultraWide" -> minZoom
            "telephoto" -> minOf(maxZoom, 3.0f)
            else -> 1.0f
        }

        camera.cameraControl.setZoomRatio(targetRatio.coerceIn(minZoom, maxZoom))
    }

    private fun stop() {
        cameraProvider?.unbindAll()
        backCamera = null
        isRunning = false
    }
}