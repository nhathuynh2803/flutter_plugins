import Flutter
import UIKit

public class SecureStorageHelperPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Register all feature plugins
    SecureStorageFeature.register(with: registrar)
    CameraFeature.register(with: registrar)
    ContactsFeature.register(with: registrar)
    QuickActionsFeature.register(with: registrar)

    // Keep the main channel for backward compatibility
    let channel = FlutterMethodChannel(
      name: "secure_storage_helper", binaryMessenger: registrar.messenger())
    let instance = SecureStorageHelperPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
