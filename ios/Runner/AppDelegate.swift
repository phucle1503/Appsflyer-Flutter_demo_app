import Flutter
import UIKit
// import CleverTapSDK
// import clevertap_plugin
import AppsFlyerLib 
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // CleverTap.autoIntegrate()
    // CleverTapPlugin.sharedInstance()?.applicationDidLaunch(options: launchOptions)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Xử lý Universal Links (https://yourbrand.onelink.me)
  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
      AppsFlyerAttribution.shared()!.continueUserActivity(userActivity, restorationHandler: nil)
      return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }

  // Xử lý URI Schemes (myapp://)
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      AppsFlyerAttribution.shared()!.handleOpenUrl(url, options: options)
      return super.application(app, open: url, options: options)
  }
}
