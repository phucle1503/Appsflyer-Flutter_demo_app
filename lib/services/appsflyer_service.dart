import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class AppsFlyerService {
  static final AppsFlyerService _instance = AppsFlyerService._internal();

  factory AppsFlyerService() => _instance;

  late AppsflyerSdk _appsflyerSdk;
  bool _isInitialized = false;
  bool _hasNavigated = false;

  AppsFlyerService._internal();

  AppsflyerSdk get sdk {
    if (!_isInitialized) {
      debugPrint(
          "🔗 [AppsFlyer Log] ⚠️Cảnh báo: Truy cập SDK khi chưa init xong. Đang trả về instance tạm thời.");
      // throw Exception(
      //     "🔗 [AppsFlyer Log] AppsFlyerService not initialized. Call init() first.");
    }
    return _appsflyerSdk;
  }

  Future<void> init({
    required Function(String? deepLinkValue, Map<String, dynamic>? fullData)
        onDeepLinkReceived,
  }) async {
    if (_isInitialized) return;

    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: "cYmtVpJCBSET23rRv4GWXa",
      appId: "013022026",
      showDebug: true,
      timeToWaitForATTUserAuthorization: 5,
      manualStart: true,
    );

    _appsflyerSdk = AppsflyerSdk(options);

    // 1. -------- Deferred Deep Linking (Conversion Data) --------
    _appsflyerSdk?.onInstallConversionData((res) {
      debugPrint(
        "🔗 [AppsFlyer Log] 1. Conversion Data (Full): ${jsonEncode(res)}",
      );

      final Map<String, dynamic> data = res['payload'] ?? res;
      final String? linkValue = data['deep_link_value']?.toString();

      if ((data['is_first_launch'] == true ||
              data['is_first_launch'] == "true") &&
          !_hasNavigated) {
        debugPrint("🔗 [AppsFlyer Log] 1. Conversion Data : is_first_launch");

        if (linkValue != null && linkValue.isNotEmpty) {
          _hasNavigated = true;
          debugPrint(
            "🔗 [AppsFlyer Log] 1. Conversion Data Deep Link Value: $linkValue",
          );

          onDeepLinkReceived(linkValue, data);
          debugPrint(
            "🔗 [AppsFlyer Log] 1. Conversion Data : called onDeeplinkReceived()",
          );
        } else {
          debugPrint(
            "🔗 [AppsFlyer Log] 1. Conversion Data Deep Link Value: null",
          );
        }
      }
    });

    // 2. -------- Direct Deep Linking (Legacy) --------
    _appsflyerSdk?.onAppOpenAttribution((res) {
      debugPrint("🔗 [AppsFlyer Log] 2. DDL (Full): ${jsonEncode(res)}");

      if (_hasNavigated) return; // Bỏ qua nếu đã điều hướng

      final Map<String, dynamic> data = res['payload'] ?? res;
      final String? linkValue = data['deep_link_value']?.toString() ??
          data['deep_link_value']?.toString();

      debugPrint("🔗 [AppsFlyer Log] 2. DDL Deep Link Value: $linkValue");

      if (linkValue != null) {
        onDeepLinkReceived(linkValue, data);
        debugPrint("🔗 [AppsFlyer Log] 2. DDL: called onDeeplinkReceived()");
      }
    });

    // 3. -------- Unified Deep Linking (Khuyên dùng) --------
    _appsflyerSdk?.onDeepLinking((DeepLinkResult dp) {
      debugPrint("🔗 [AppsFlyer Log] 3. UDL Status: ${dp.status}");

      if (dp.status == Status.FOUND && !_hasNavigated) {
        final String? deepLinkValue = dp.deepLink?.deepLinkValue;
        final Map<String, dynamic>? data = dp.deepLink?.clickEvent;

        if (deepLinkValue != null) {
          _hasNavigated = true;
          debugPrint(
              "🔗 [AppsFlyer Log] 3. UDL Deep Link Value: $deepLinkValue");
          onDeepLinkReceived(deepLinkValue, data);
          debugPrint("🔗 [AppsFlyer Log] 3. UDL: called onDeeplinkReceived()");
        }
      } else if (dp.status == Status.ERROR) {
        debugPrint("🔗 [AppsFlyer Log] 3. UDL Status: Error -> ${dp.error}");
      } else if (dp.status == Status.NOT_FOUND) {
        debugPrint("🔗 [AppsFlyer Log] 3. UDL Status: Deep link not found");
      } else if (dp.status == Status.PARSE_ERROR) {
        debugPrint("🔗 [AppsFlyer Log] 3. UDL Status: Parse Error");
      } else {
        debugPrint("🔗 [AppsFlyer Log] 3. UDL Status: Deep link not found");
      }

      // switch (dp.status) {
      //   case Status.FOUND:
      //     final String? deepLinkValue = dp.deepLink?.deepLinkValue;
      //     final Map<String, dynamic>? data = dp.deepLink?.clickEvent;

      //     debugPrint("🔗 [AppsFlyer Log] 3. UDL (Full): ${dp.toString()}");
      //     debugPrint(
      //       "🔗 [AppsFlyer Log] 3. UDL Click Event: ${jsonEncode(data)}",
      //     );
      //     debugPrint(
      //       "🔗 [AppsFlyer Log] 3. UDL Deep Link Value: $deepLinkValue",
      //     );

      //     onDeepLinkReceived(deepLinkValue, data);
      //     debugPrint("🔗 [AppsFlyer Log] 3. UDL: called onDeeplinkReceived()");
      //     break;
      //   case Status.NOT_FOUND:
      //     debugPrint("🔗 [AppsFlyer Log] 3. UDL Status: Deep link not found.");
      //     break;
      //   case Status.ERROR:
      //     debugPrint("🔗 [AppsFlyer Log] 3. UDL Status: Error -> ${dp.error}");
      //     break;
      //   case Status.PARSE_ERROR:
      //     debugPrint("🔗 [AppsFlyer Log] 3. UDL Status: Parse Error");
      //     break;
      // }
    });

    await _appsflyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    _appsflyerSdk.startSDK(
      onSuccess: () {
        debugPrint(
            "🔗 [AppsFlyer Log] ✅ AppsFlyer SDK initialized successfully.");
        _isInitialized = true;
        ;
      },
      onError: (int errorCode, String errorMessage) {
        debugPrint(
          "🔗 [AppsFlyer Log] ❌ AppsFlyer SDK init error: $errorCode - $errorMessage",
        );
      },
    );
    // _isInitialized = true;
  }

  void resetNavigationFlag() {
    _hasNavigated = false;
    debugPrint("🔗 [AppsFlyer Log] Navigation flag reset.");
  }
}
