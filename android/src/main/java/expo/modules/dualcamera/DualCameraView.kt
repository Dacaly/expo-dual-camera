package expo.modules.dualcamera

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class DualCameraView(context: Context) : FrameLayout(context) {

    private val frontPreview: PreviewView
    private val backPreview: PreviewView
    private val errorView: TextView

    private var cameraProvider: ProcessCameraProvider? = null
    private val cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    private var frontFrameMap: Map<String, Int>? = null
    private var backFrameMap: Map<String, Int>? = null
    private var frontGravity: String = "resizeAspectFill"
    private var backGravity: String = "resizeAspectFill"

    private var isCameraRunning = false
    private var permissionGranted = false

    init {
        backPreview = PreviewView(context).apply {
            id = View.generateViewId()
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
            implementationMode = PreviewView.ImplementationMode.PERFORMANCE
            scaleType = PreviewView.ScaleType.FILL_CENTER
        }

        frontPreview = PreviewView(context).apply {
            id = View.generateViewId()
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
            implementationMode = PreviewView.ImplementationMode.PERFORMANCE
            scaleType = PreviewView.ScaleType.FILL_CENTER
        }

        errorView = TextView(context).apply {
            text = "Camera unavailable"
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.BLACK)
            gravity = Gravity.CENTER
            visibility = View.GONE
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
        }

        addView(backPreview, 0)
        addView(frontPreview, 1)
        addView(errorView, 2)

        initializeCameraProvider()
    }

    private fun initializeCameraProvider() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()
            if (permissionGranted && isCameraRunning) {
                bindCameraUseCases()
            }
        }, ContextCompat.getMainExecutor(context))
    }

    @SuppressLint("UnsafeOptInUsageError")
    private fun bindCameraUseCases() {
        val provider = cameraProvider ?: return

        try {
            provider.unbindAll()

            val backPreviewUseCase = Preview.Builder()
                .build()
                .also { it.surfaceProvider = backPreview.surfaceProvider }

            val frontPreviewUseCase = Preview.Builder()
                .build()
                .also { it.surfaceProvider = frontPreview.surfaceProvider }

            val backCameraSelector = CameraSelector.Builder()
                .requireLensFacing(CameraSelector.LENS_FACING_BACK)
                .build()

            val frontCameraSelector = CameraSelector.Builder()
                .requireLensFacing(CameraSelector.LENS_FACING_FRONT)
                .build()

            val lifecycleOwner = context as? LifecycleOwner ?: return

            provider.bindToLifecycle(
                lifecycleOwner,
                backCameraSelector,
                backPreviewUseCase
            )

            provider.bindToLifecycle(
                lifecycleOwner,
                frontCameraSelector,
                frontPreviewUseCase
            )

            errorView.visibility = View.GONE
            frontPreview.visibility = View.VISIBLE
            backPreview.visibility = View.VISIBLE

        } catch (e: Exception) {
            showError("Failed to start cameras: ${e.message}")
        }
    }

    private fun showError(message: String) {
        errorView.text = message
        errorView.visibility = View.VISIBLE
        frontPreview.visibility = View.GONE
        backPreview.visibility = View.GONE
    }

    fun updateProps() {
        frontFrameMap?.let { map ->
            val x = map["x"] ?: 0
            val y = map["y"] ?: 0
            val width = map["width"] ?: LayoutParams.MATCH_PARENT
            val height = map["height"] ?: LayoutParams.MATCH_PARENT

            frontPreview.layoutParams = LayoutParams(width, height).apply {
                leftMargin = x
                topMargin = y
            }
        }

        backFrameMap?.let { map ->
            val x = map["x"] ?: 0
            val y = map["y"] ?: 0
            val width = map["width"] ?: LayoutParams.MATCH_PARENT
            val height = map["height"] ?: LayoutParams.MATCH_PARENT

            backPreview.layoutParams = LayoutParams(width, height).apply {
                leftMargin = x
                topMargin = y
            }
        }

        frontPreview.scaleType = when (frontGravity) {
            "resize" -> PreviewView.ScaleType.FIT_CENTER
            "resizeAspect" -> PreviewView.ScaleType.FIT_CENTER
            "resizeAspectFill" -> PreviewView.ScaleType.FILL_CENTER
            else -> PreviewView.ScaleType.FIT_CENTER
        }

        backPreview.scaleType = when (backGravity) {
            "resize" -> PreviewView.ScaleType.FIT_CENTER
            "resizeAspect" -> PreviewView.ScaleType.FIT_CENTER
            "resizeAspectFill" -> PreviewView.ScaleType.FILL_CENTER
            else -> PreviewView.ScaleType.FIT_CENTER
        }
    }

    fun setFrontFrame(frame: Map<String, Int>) {
        frontFrameMap = frame
        updateProps()
    }

    fun setBackFrame(frame: Map<String, Int>) {
        backFrameMap = frame
        updateProps()
    }

    fun setFrontGravity(gravity: String) {
        frontGravity = gravity
        updateProps()
    }

    fun setBackGravity(gravity: String) {
        backGravity = gravity
        updateProps()
    }

    fun setPermissionGranted(granted: Boolean) {
        permissionGranted = granted
        if (granted && isCameraRunning) {
            bindCameraUseCases()
        }
    }

    fun startCameras() {
        isCameraRunning = true
        if (permissionGranted) {
            bindCameraUseCases()
        }
    }

    fun stopCameras() {
        isCameraRunning = false
        cameraProvider?.unbindAll()
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        stopCameras()
        cameraExecutor.shutdown()
    }
}