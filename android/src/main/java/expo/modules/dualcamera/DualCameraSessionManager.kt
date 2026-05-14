package expo.modules.dualcamera

import android.content.Context
import android.net.Uri
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import java.io.File
import java.lang.ref.WeakReference
import java.util.UUID

object DualCameraSessionManager {
    private var frontView: WeakReference<DualCameraView>? = null
    private var backView: WeakReference<DualCameraView>? = null
    private var cameraProvider: ProcessCameraProvider? = null

    private var frontCamera: Camera? = null
    private var backCamera: Camera? = null

    private var frontImageCapture: ImageCapture? = null
    private var backImageCapture: ImageCapture? = null

    private var currentBackLens: String = "wide"
    var isRunning = false
        private set
    private var isPaused = false

    // Store use cases and selectors for pause/resume
    private var lastContext: WeakReference<Context>? = null

    fun register(view: DualCameraView, side: String, context: Context) {
        if (side == "front") frontView = WeakReference(view)
        else backView = WeakReference(view)

        lastContext = WeakReference(context)

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

            // Preview use cases
            val backPreviewUseCase = Preview.Builder().build()
                .also { it.surfaceProvider = back.getPreviewView().surfaceProvider }
            val frontPreviewUseCase = Preview.Builder().build()
                .also { it.surfaceProvider = front.getPreviewView().surfaceProvider }

            // Image capture use cases
            val backCapture = ImageCapture.Builder()
                .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                .build()
            val frontCapture = ImageCapture.Builder()
                .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                .build()

            val backSelector = CameraSelector.Builder()
                .requireLensFacing(CameraSelector.LENS_FACING_BACK).build()
            val frontSelector = CameraSelector.Builder()
                .requireLensFacing(CameraSelector.LENS_FACING_FRONT).build()

            backCamera = provider.bindToLifecycle(
                lifecycleOwner, backSelector, backPreviewUseCase, backCapture
            )
            frontCamera = provider.bindToLifecycle(
                lifecycleOwner, frontSelector, frontPreviewUseCase, frontCapture
            )

            frontImageCapture = frontCapture
            backImageCapture = backCapture

            applyBackLensZoom()

            front.showPreview()
            back.showPreview()
            isRunning = true
            isPaused = false
            front.sessionDidStart()
            back.sessionDidStart()

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
        frontCamera = null
        backCamera = null
        frontImageCapture = null
        backImageCapture = null
        isRunning = false
        isPaused = false
    }

    // MARK: - Pause / Resume

    fun pause() {
        if (!isRunning || isPaused) return
        isPaused = true
        cameraProvider?.unbindAll()
    }

    fun resume() {
        if (!isPaused) return
        isPaused = false
        val context = lastContext?.get() ?: return
        startIfReady(context)
    }

    // MARK: - Photo Capture

    fun capturePhoto(side: String, context: Context, callback: (Result<String>) -> Unit) {
        if (!isRunning || isPaused) {
            callback(Result.failure(Exception("Camera session is not running")))
            return
        }

        val imageCapture = if (side == "front") frontImageCapture else backImageCapture
        if (imageCapture == null) {
            callback(Result.failure(Exception("Photo capture not available")))
            return
        }

        val file = File(context.cacheDir, "${UUID.randomUUID()}.jpg")
        val outputOptions = ImageCapture.OutputFileOptions.Builder(file).build()

        imageCapture.takePicture(
            outputOptions,
            ContextCompat.getMainExecutor(context),
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                    callback(Result.success(Uri.fromFile(file).toString()))
                }
                override fun onError(exception: ImageCaptureException) {
                    callback(Result.failure(exception))
                }
            }
        )
    }

    // MARK: - Torch

    fun setTorch(enabled: Boolean) {
        val camera = backCamera ?: throw Exception("Back camera not available")
        if (!camera.cameraInfo.hasFlashUnit()) {
            throw Exception("Torch is not available on this device")
        }
        camera.cameraControl.enableTorch(enabled)
    }

    // MARK: - Zoom

    fun setZoom(side: String, factor: Float) {
        val camera = if (side == "front") frontCamera else backCamera
        camera ?: return

        val zoomState = camera.cameraInfo.zoomState.value ?: return
        val clamped = factor.coerceIn(zoomState.minZoomRatio, zoomState.maxZoomRatio)
        camera.cameraControl.setZoomRatio(clamped)
    }
}
