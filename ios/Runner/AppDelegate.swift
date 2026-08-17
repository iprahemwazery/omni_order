import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // قناة معرّف الجهاز: identifierForVendor هو معرّف مستقر لكل تطبيق على الجهاز.
    let channel = FlutterMethodChannel(
      name: "omni_order/device_id",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { call, result in
      if call.method == "getDeviceId" {
        if let id = UIDevice.current.identifierForVendor?.uuidString {
          result(id)
        } else {
          result(FlutterError(code: "UNAVAILABLE", message: "identifierForVendor unavailable", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
