package expo.modules.dualcamera

import android.content.Context
import android.view.View
import androidx.camera.view.PreviewView
import expo.modules.kotlin.views.ViewManager
import expo.modules.kotlin.types.Map
import expo.modules.kotlin.types.String

class DualCameraViewManager : ViewManager<PreviewView>() {

    override fun getName() = "ExpoDualCamera"

    override fun getExportedViewTypeDefinitions() = listOf(
        ViewTypeDefinition(
            name = "frontFrame",
            propType = ViewPropType("Map"),
            setter = { view, value ->
                (view as? DualCameraView)?.setFrontFrame(value as Map<String, Int>)
            }
        ),
        ViewTypeDefinition(
            name = "backFrame",
            propType = ViewPropType("Map"),
            setter = { view, value ->
                (view as? DualCameraView)?.setBackFrame(value as Map<String, Int>)
            }
        ),
        ViewTypeDefinition(
            name = "frontGravity",
            propType = ViewPropType("String"),
            setter = { view, value ->
                (view as? DualCameraView)?.setFrontGravity(value as String)
            }
        ),
        ViewTypeDefinition(
            name = "backGravity",
            propType = ViewPropType("String"),
            setter = { view, value ->
                (view as? DualCameraView)?.setBackGravity(value as String)
            }
        )
    )

    override fun createViewInstance(context: Context): PreviewView {
        return PreviewView(context).apply {
            implementationMode = PreviewView.ImplementationMode.PERFORMANCE
        }
    }

    override fun onViewDidUpdateProps(view: PreviewView) {
        // Props are handled via setters
    }

    override fun onStartViewNativeCycle(view: PreviewView) {
        (view as? DualCameraView)?.startCameras()
    }

    override fun onStopViewNativeCycle(view: PreviewView) {
        (view as? DualCameraView)?.stopCameras()
    }
}