import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert'; 

class AppsFlyerService {
  static final AppsFlyerService _instance = AppsFlyerService._internal();

  factory AppsFlyerService() => _instance;

  late AppsflyerSdk _appsflyerSdk;
  bool _isInitialized = false;

  AppsFlyerService._internal();

  AppsflyerSdk get sdk {
    if (!_isInitialized) {
      throw Exception("AppsFlyerService not initialized. Call init() first.");
    }
    return _appsflyerSdk;
  }

  Future<void> init({
    required Function(String? deepLinkValue, Map<String, dynamic>? fullData) onDeepLinkReceived,
  }) async {
    if (_isInitialized) return;

    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: "cYmtVpJCBSET23rRv4GWXa",
      appId: "013022026",
      showDebug: true,
      timeToWaitForATTUserAuthorization: 15,
      manualStart: true,
    );

    _appsflyerSdk = AppsflyerSdk(options);

    // 1. -------- Deferred Deep Linking (Conversion Data) --------
    // Dành cho trường hợp người dùng mới cài app lần đầu từ link quảng cáo
    // _appsflyerSdk?.onInstallConversionData((res) {
    //   debugPrint("📦 Conversion Data (Deferred): ${jsonEncode(res)}");
      
    //   // Nếu là lần đầu cài đặt (is_first_launch = true), 
    //   // bạn có thể lấy deep_link_value từ đây nếu Unified Deep Linking không bắt được
    //   if (res['payload']['is_first_launch'] == true) {
    //     final linkValue = res['payload']['deep_link_value'];
    //     if (linkValue != null) {
    //        onDeepLinkReceived(linkValue, res['payload']);
    //     }
    //   }
    // });

    // 2. -------- Direct Deep Linking (Legacy) --------
    // Xử lý các link cũ hoặc khi không dùng Unified Deep Linking
    // _appsflyerSdk?.onAppOpenAttribution((res) {
    //   debugPrint("🔗 Direct Deep Link (Legacy): ${jsonEncode(res)}");
    //   final linkValue = res['payload']['link']; // Thường nằm trong key 'link' hoặc 'base_url'
    //   onDeepLinkReceived(linkValue, res['payload']);
    // });

    // 3. -------- Unified Deep Linking (Khuyên dùng) --------
    // Gộp cả 2 trường hợp trên, hỗ trợ OneLink tốt nhất
    _appsflyerSdk?.onDeepLinking((DeepLinkResult dp) {
      switch (dp.status) {
        case Status.FOUND:
          final deepLinkValue = dp.deepLink?.deepLinkValue;
          final mediaSource = dp.deepLink?.mediaSource;
          debugPrint("🔗 [AppsFlyer Deeplink] Deep link Value: $deepLinkValue");
          debugPrint("🔗 [AppsFlyer Deeplink] Meida Source: $mediaSource");

          // Trả về cả giá trị rút gọn và toàn bộ object để bạn xử lý logic phức tạp (nếu cần)
          onDeepLinkReceived(deepLinkValue, dp.deepLink?.clickEvent);
          break;
        case Status.NOT_FOUND:
          debugPrint("🔗 [AppsFlyer Deeplink] UDL Deep link not found.");
          break;
        case Status.ERROR:
          debugPrint("🔗 [AppsFlyer Deeplink] UDL Error: ${dp.error}");
          break;
        case Status.PARSE_ERROR:
          debugPrint("🔗 [AppsFlyer Deeplink] UDL Parse Error");
          break;
      }
    });

    await _appsflyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: false,
      registerOnDeepLinkingCallback: true,
    );

    _appsflyerSdk.startSDK(
      onSuccess: () {
        debugPrint("✅ AppsFlyer SDK initialized successfully.");
      },
      onError: (int errorCode, String errorMessage) {
        debugPrint("❌ AppsFlyer SDK init error: $errorCode - $errorMessage");
      },
    );
    _isInitialized = true;

  }
}
