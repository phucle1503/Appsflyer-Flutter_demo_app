import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

class AppsFlyerService {
  static final AppsFlyerService _instance = AppsFlyerService._internal();

  factory AppsFlyerService() => _instance;

  late AppsflyerSdk _sdk;
  bool _isInitialized = false;

  AppsFlyerService._internal();

  AppsflyerSdk get sdk {
    if (!_isInitialized) {
      throw Exception("AppsFlyerService not initialized. Call init() first.");
    }
    return _sdk;
  }

  Future<void> init({
    required Function(String?) onDeepLinkReceived,
  }) async {
    if (_isInitialized) return;

    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: "cYmtVpJCBSET23rRv4GWXa",
      appId: "13022026",
      showDebug: true,
      timeToWaitForATTUserAuthorization: 15,
      manualStart: true,
    );

    _sdk = AppsflyerSdk(options);

    // -------- Conversion Data --------
    _sdk.onInstallConversionData((res) {
      debugPrint("📦 Conversion Data: $res");
    });

    // -------- Unified Deep Linking --------
    _sdk.onDeepLinking((DeepLinkResult dp) {
      if (dp.status == Status.FOUND) {
        final deepLinkValue = dp.deepLink?.deepLinkValue;
        debugPrint("🔗 UDL FOUND: $deepLinkValue");

        if (deepLinkValue != null) {
          onDeepLinkReceived(deepLinkValue);
        }
      } else {
        debugPrint("🔗 UDL Status: ${dp.status}");
      }
    });

    await _sdk.initSdk(
      registerConversionDataCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    _sdk.startSDK(
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
