package expo.dualcamera;

import expo.modules.core.interfaces.Package;
import expo.modules.core.interfaces.ModuleDefinition;
import expo.modules.core.view.ViewManager;
import java.util.ArrayList;
import java.util.List;

public class DualCameraPackage implements Package {
  @Override
  public List<ModuleDefinition> getModuleDefinitions() {
    List<ModuleDefinition> modules = new ArrayList<>();
    modules.add(DualCameraModule::definition);
    return modules;
  }

  @Override
  public List<ViewManager> getViewManagers() {
    List<ViewManager> viewManagers = new ArrayList<>();
    viewManagers.add(new DualCameraViewManager());
    return viewManagers;
  }
}
