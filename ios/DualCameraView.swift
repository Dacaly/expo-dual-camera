import ExpoModulesCore
import UIKit
import AVFoundation

public class DualCameraView: ExpoView {

    // MARK: - Properties

    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var side: String = "back"
    private var errorLabel: UILabel?

    // MARK: - Initialization

    public required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
        backgroundColor = .black
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            DualCameraSessionManager.shared.register(self, side: side)
        } else {
            DualCameraSessionManager.shared.unregister(self)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        errorLabel?.frame = bounds
    }

    // MARK: - Prop Setters

    func setSide(_ newSide: String) {
        guard newSide != side else { return }
        let wasAttached = window != nil
        if wasAttached {
            DualCameraSessionManager.shared.unregister(self)
        }
        side = newSide
        if wasAttached {
            DualCameraSessionManager.shared.register(self, side: side)
        }
    }

    func setLens(_ lens: String) {
        DualCameraSessionManager.shared.setBackLens(lens)
    }

    // MARK: - Preview Management

    func attachPreview(_ layer: AVCaptureVideoPreviewLayer) {
        previewLayer?.removeFromSuperlayer()
        layer.frame = bounds
        layer.videoGravity = .resizeAspectFill
        self.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
        errorLabel?.isHidden = true
    }

    func detachPreview() {
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
    }

    // MARK: - Error Handling

    func showError(_ message: String) {
        if errorLabel == nil {
            let label = UILabel()
            label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 14, weight: .medium)
            addSubview(label)
            errorLabel = label
        }
        errorLabel?.text = message
        errorLabel?.frame = bounds
        errorLabel?.isHidden = false
    }

    // MARK: - Cleanup

    deinit {
        DualCameraSessionManager.shared.unregister(self)
    }
}