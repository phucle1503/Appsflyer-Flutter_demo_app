import Flutter
import UIKit
import AppsFlyerLib

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    GeneratedPluginRegistrant.register(with: self)

    // 1. Đăng ký quyền thông báo với Apple
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
    }
    application.registerForRemoteNotifications()

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
        NSLog("🔗 [AppsFlyer Log] [AppDelegate] Cold Start Payload: %@", remoteNotification.description)
        
        // Thêm một chút delay nhỏ (0.5s) để đảm bảo SDK đã nhận App Key và khởi tạo xong
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            AppsFlyerLib.shared().handlePushNotification(remoteNotification)
            NSLog("🔗 [AppsFlyer Log] [AppDelegate] Delayed handlePushNotification executed")
        }
    }
    
    return result
  }

  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         didReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        NSLog("🔗 [AppsFlyer Log] [AppDelegate] User Clicked Notification: \(userInfo)")
        
        // Gửi payload cho AppsFlyer để đo lường Re-engagement
        AppsFlyerLib.shared().handlePushNotification(userInfo)
        
        // Gọi completionHandler của hệ thống
        completionHandler()
        
        // Vẫn gọi super để Flutter plugin (nếu có) có thể xử lý tiếp
        super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  // 2. Gửi Device Token về cho AppsFlyer (để tracking uninstall và push)
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    AppsFlyerLib.shared().registerUninstall(deviceToken)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    NSLog("🔗 [AppsFlyer Log] [AppDelegate] APNS Token: \(tokenString)")

  }

  // 3. Xử lý Payload khi nhận Push Notification (Đo lường Re-engagement)
  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    
    NSLog("🔗 [AppsFlyer Log] [AppDelegate] userInfo: \(userInfo)")
    
    // AppsFlyer đọc dữ liệu từ thông báo này
    AppsFlyerLib.shared().handlePushNotification(userInfo)
    
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }

  // --- PHẦN ĐÃ CÓ CỦA BẠN (GIỮ NGUYÊN) ---

  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
      AppsFlyerAttribution.shared()!.continueUserActivity(userActivity, restorationHandler: nil)
      return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      AppsFlyerAttribution.shared()!.handleOpenUrl(url, options: options)
      return super.application(app, open: url, options: options)
  }
}