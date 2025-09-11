import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    // Set a phone-like aspect ratio (~19.5:9). Choose a reasonable size for macOS.
    // Height prioritizes visibility while keeping a narrow width suitable for phone layout.
    let targetWidth: CGFloat = 420
    let targetHeight: CGFloat = 420 * (19.5 / 9.0)
    var windowFrame = self.frame
    windowFrame.size = NSSize(width: targetWidth, height: targetHeight)
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
