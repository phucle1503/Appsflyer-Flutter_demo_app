import Flutter
import UIKit
import CleverTapSDK
import clevertap_plugin

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    CleverTap.autoIntegrate()
    CleverTapPlugin.sharedInstance()?.applicationDidLaunch(options: launchOptions)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
