import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:io';

class AppsFlyerService {
  static final AppsFlyerService _instance = AppsFlyerService._internal();
  factory AppsFlyerService() => _instance;

  late AppsflyerSdk _appsflyerSdk;
  bool _isInitialized = false;
  bool _hasNavigated = false;
  bool _isProcessingPush = false; // Biến khóa mới
  String? _lastProcessedLink;
  DateTime? _lastNavigatedTime;
  Timer? _fallbackTimer;
  Map<String, dynamic>? _pendingPushPayload;
  Map<String, dynamic>? _currentForegroundPayload;

  static const platform = MethodChannel('aka.digital/appsflyer_bridge');

  late Function(String? deepLinkValue, Map<String, dynamic>? fullData)
      _onDeepLinkCallback;

  AppsFlyerService._internal();

  AppsflyerSdk get sdk {
    if (!_isInitialized) {
      debugPrint(
          "🔗 [AppsFlyer Log] ⚠️ Cảnh báo: Truy cập SDK khi chưa init xong. Đang trả về instance tạm thời.");
    }
    return _appsflyerSdk;
  }

  Future<void> init({
    required Function(String? deepLinkValue, Map<String, dynamic>? fullData)
        onDeepLinkReceived,
  }) async {
    if (_isInitialized) return;
    _onDeepLinkCallback = onDeepLinkReceived;

    // platform.setMethodCallHandler((MethodCall call) async {
    //   switch (call.method) {
    //     case "onNativePushClick":
    //       debugPrint(
    //           "🔗 [AppsFlyer Log] 🚩 Nhận tín hiệu từ Native: ${call.arguments}");

    //       if (_currentForegroundPayload != null) {
    //         handlePushNotification(_currentForegroundPayload!);
    //         debugPrint(
    //             "🔗 [AppsFlyer Log] 🚩 Gọi handlePushNotification với $_currentForegroundPayload");
    //       } else {
    //         _appsflyerSdk.performOnDeepLinking();
    //         debugPrint(
    //             "🔗 [AppsFlyer Log] 🚩 Gọi performOnDeepLinking với $_currentForegroundPayload");
    //       }
    //       break;

    //     default:
    //       debugPrint(
    //           "🔗 [AppsFlyer Log] 🚩 Không nhận được tín hiệu từ Native: ${call.method}");
    //   }
    // });

    final Completer<void> initCompleter = Completer<void>();

    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: "cYmtVpJCBSET23rRv4GWXa",
      appId: "013022026",
      showDebug: true,
      timeToWaitForATTUserAuthorization: 15,
      manualStart: true,
    );

    _appsflyerSdk = AppsflyerSdk(options);
    _appsflyerSdk.setResolveDeepLinkURLs(["af-flutter.onelink.me"]);
    _appsflyerSdk.addPushNotificationDeepLinkPath(["af_push_link"]);

    // 1. -------- Deferred Deep Linking (Conversion Data) --------
    _appsflyerSdk.onInstallConversionData((res) {
      debugPrint("🔗 [AppsFlyer Log] 1. Conversion Data Triggered.");
      debugPrint(
        "🔗 [AppsFlyer Log] 1. Conversion Data (Full): ${jsonEncode(res)}",
      );

      final Map<String, dynamic> data = res['payload'] ?? res;
      final String? linkValue = data['deep_link_value']?.toString();
      bool isFirstLaunch =
          data['is_first_launch'] == true || data['is_first_launch'] == "true";

      if (isFirstLaunch) {
        debugPrint("🔗 [AppsFlyer Log] 1. Nhận diện: Lần đầu mở App (Install)");
        _executeNavigation(
            linkValue, data, _onDeepLinkCallback, "ConversionData");
      }
    });

    // 2. -------- Direct Deep Linking (Legacy) --------
    _appsflyerSdk.onAppOpenAttribution((res) {
      debugPrint("🔗 [AppsFlyer Log] 2. DDL (Legacy) Triggered.");
      debugPrint("🔗 [AppsFlyer Log] 2. DDL (Full): ${jsonEncode(res)}");

      final Map<String, dynamic> data = res['payload'] ?? res;
      final String? linkValue = data['deep_link_value']?.toString();

      debugPrint("🔗 [AppsFlyer Log] 2. DDL Deep Link Value: $linkValue");
      _executeNavigation(linkValue, data, _onDeepLinkCallback, "DDL Legacy");
    });

    // 3. -------- Unified Deep Linking (UDL) --------
    _appsflyerSdk.onDeepLinking((DeepLinkResult dp) {
      debugPrint(
          "🔗 [AppsFlyer Log] 3. UDL Callback Triggered. Status: ${dp.status}");
      switch (dp.status) {
        case Status.FOUND:
          final String? deepLinkValue = dp.deepLink?.deepLinkValue;
          final Map<String, dynamic>? data = dp.deepLink?.clickEvent;
          debugPrint("🔗 [AppsFlyer Log] 3. UDL Data: $data");

          _executeNavigation(deepLinkValue, data, _onDeepLinkCallback, "UDL");
          break;

        case Status.ERROR:
          debugPrint("🔗 [AppsFlyer Log] 3. UDL Status: ERROR -> ${dp.error}");
          break;

        case Status.NOT_FOUND:
          debugPrint("🔗 [AppsFlyer Log] 3. UDL Status: NOT_FOUND.");
          break;

        case Status.PARSE_ERROR:
          debugPrint("🔗 [AppsFlyer Log] 3. UDL Status: PARSE_ERROR");
          break;

        default:
          debugPrint("🔗 [AppsFlyer Log] 3. UDL Status: (${dp.status})");
      }
    });

    if (Platform.isAndroid) {
      _appsflyerSdk.performOnDeepLinking();
    }

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

        if (_pendingPushPayload != null) {
          debugPrint(
              "🔗 [AppsFlyer Log] 🚀 Xử lý Pending Push Payload. Gọi handlePushNotification()");
          handlePushNotification(_pendingPushPayload!);
          _pendingPushPayload = null;
        }
        if (!initCompleter.isCompleted) initCompleter.complete();
      },
      onError: (int errorCode, String errorMessage) {
        debugPrint(
          "🔗 [AppsFlyer Log] ❌ AppsFlyer SDK init error: $errorCode - $errorMessage",
        );
        _isInitialized = false;
        if (!initCompleter.isCompleted) initCompleter.complete();
      },
    );

    return initCompleter.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint(
            "🔗 [AppsFlyer Log] ⚠️ SDK Init Timeout (10s) - Tiếp tục chạy App.");
      },
    );
  }

  void _executeNavigation(String? value, Map<String, dynamic>? data,
      Function callback, String source) {
    if (value == null || value.isEmpty) {
      debugPrint(
          "🔗 [AppsFlyer Log] [_executeNavigation] ⚠️ $source: Không có deep_link_value để điều hướng.");
      return;
    }

    _fallbackTimer?.cancel();

    if (_hasNavigated) {
      debugPrint(
          "🔗 [AppsFlyer Log] [_executeNavigation] 🚫 $source: Bị chặn do _hasNavigated = true.");
      return;
    }

    final now = DateTime.now();
    if (_lastProcessedLink == value &&
        _lastNavigatedTime != null &&
        now.difference(_lastNavigatedTime!).inSeconds < 2) {
      debugPrint(
          "🔗 [AppsFlyer Log] [_executeNavigation]  ⚠️ Chặn trùng lặp từ $source: $value");
      return;
    }

    debugPrint(
        "🔗 [AppsFlyer Log] [_executeNavigation] 🚀 [$source] Chấp nhận điều hướng đến: $value");

    _lastProcessedLink = value;
    _lastNavigatedTime = now;
    _hasNavigated = true;
    _isProcessingPush = false;

    callback(value, data);
    debugPrint(
        "🔗 [AppsFlyer Log] [_executeNavigation] ✅ [$source] Đã thực thi onDeepLinkReceived() cho $value.");
  }

  void handlePushNotification(Map<String, dynamic> messageData) {
    if (_isProcessingPush || _hasNavigated) {
      debugPrint(
          "🔗 [AppsFlyer Log] [handlePushNotification] 🛡️ Chặn tín hiệu trùng lặp (Processing: $_isProcessingPush, Navigated: $_hasNavigated)");
      return;
    }

    _isProcessingPush = true;
    _currentForegroundPayload = messageData;
    _hasNavigated = false;
    _lastProcessedLink = null;

    if (!_isInitialized) {
      debugPrint(
          "🔗 [AppsFlyer Log] [handlePushNotification] ⏳ SDK chưa init, lưu payload chờ xử lý.");
      _pendingPushPayload = messageData;
      _isProcessingPush = false;
      return;
    }

    debugPrint(
        "🔗 [AppsFlyer Log] [handlePushNotification] ⚡ Bắt đầu xử lý luồng Push mới. Gọi sendPushNotificationData()");
    _appsflyerSdk.sendPushNotificationData(messageData);

    _fallbackTimer?.cancel();

    _fallbackTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!_hasNavigated) {
        // debugPrint(
        //     "🔗 [AppsFlyer Log] [handlePushNotification] ⚡ 1: Gọi performOnDeepLinking()");
        // _appsflyerSdk.performOnDeepLinking();
      }
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (!_hasNavigated) {
        // debugPrint(
        //     "🔗 [AppsFlyer Log] [handlePushNotification] ⚡ 2: Gọi performOnDeepLinking()");
        // _appsflyerSdk.performOnDeepLinking();
      }
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (!_hasNavigated) {
        // debugPrint(
        //     "🔗 [AppsFlyer Log] [handlePushNotification] ⚡ 3: Gọi _handleManualFallback()");
        // _handleManualFallback(messageData);
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        _isProcessingPush = false;
        debugPrint(
            "🔗 [AppsFlyer Log] [handlePushNotification] 🔓 Đã mở khóa _isProcessingPush.");
      });
    });
  }

  void _handleManualFallback(Map<String, dynamic> data) {
    final String? url = data['af_push_link']?.toString();
    if (url != null) {
      debugPrint(
          "🔗 [AppsFlyer Log] [_handleManualFallback] Tìm thấy giá trị af_push_link ");
      try {
        Uri uri = Uri.parse(url);
        String? value = uri.queryParameters['deep_link_value'];

        if (value != null) {
          debugPrint(
              "🔗 [AppsFlyer Log] [_handleManualFallback] Tìm thấy giá trị deep_link_value: $value");
          _executeNavigation(
              value, data, _onDeepLinkCallback, "ManualFallback");
        } else {
          debugPrint(
              "🔗 [AppsFlyer Log] [_handleManualFallback] Không tìm thấy giá trị deep_link_value");
        }
      } catch (e) {
        debugPrint(
            "🔗 [AppsFlyer Log] [_handleManualFallback]  Lỗi fallback: $e");
      }
    } else {
      debugPrint(
          "🔗 [AppsFlyer Log] [_handleManualFallback] Không tìm thấy giá trị af_push_link ");
    }
  }

  void resetNavigationFlag() {
    _hasNavigated = false;
    _lastProcessedLink = null;
  }
}
