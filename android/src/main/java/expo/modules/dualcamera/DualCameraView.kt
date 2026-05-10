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

    fun setCameraConfig(side: String, config: Map<String, Any>) {
        val x = (config["x"] as? Number)?.toInt() ?: 0
        val y = (config["y"] as? Number)?.toInt() ?: 0
        val w = (config["width"] as? Number)?.toInt() ?: LayoutParams.MATCH_PARENT
        val h = (config["height"] as? Number)?.toInt() ?: LayoutParams.MATCH_PARENT
        val zIndex = (config["zIndex"] as? Number)?.toFloat() ?: 0f
        val borderRadius = (config["borderRadius"] as? Number)?.toFloat() ?: 0f
        val objectFit = config["objectFit"] as? String ?: "cover"

        val scaleType = when (objectFit) {
            "contain" -> PreviewView.ScaleType.FIT_CENTER
            "fill" -> PreviewView.ScaleType.FIT_CENTER
            else -> PreviewView.ScaleType.FILL_CENTER
        }

        val preview = if (side == "front") frontPreview else backPreview

        preview.layoutParams = LayoutParams(w, h).apply {
            leftMargin = x
            topMargin = y
        }
        preview.scaleType = scaleType
        preview.translationZ = zIndex
        preview.clipToOutline = borderRadius > 0
        if (borderRadius > 0) {
            preview.outlineProvider = object : android.view.ViewOutlineProvider() {
                override fun getOutline(view: android.view.View, outline: android.graphics.Outline) {
                    outline.setRoundRect(0, 0, view.width, view.height, borderRadius)
                }
            }
        }
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