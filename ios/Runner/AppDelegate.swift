import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var printerChannelHandler: IOSPrinterChannelHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    printerChannelHandler = IOSPrinterChannelHandler(messenger: controller.binaryMessenger)
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
