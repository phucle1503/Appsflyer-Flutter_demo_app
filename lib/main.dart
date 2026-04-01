import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:af_flutter_sample/services/appsflyer_service.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/checkout_page.dart';
import 'pages/product_page.dart';
import 'pages/login_page.dart';
import 'pages/cart_page.dart';
import 'pages/test_page.dart';

@pragma('vm:entry-point')
void _onKilledStateNotificationClickedHandler(
  Map<String, dynamic> payload,
) async {
  debugPrint('🔗 [AppsFlyer Log] [KilledState] Payload: $payload');
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint(
    "🔗 [AppsFlyer Log] [FCM - firebaseMessagingBackgroundHandler] 📩 Nhận Push ở Background/Killed",
  );
  debugPrint(
      "🔗 [AppsFlyer Log] [FCM - firebaseMessagingBackgroundHandler] 📩 Data: ${message.data}");
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final appsFlyerService = AppsFlyerService();

  await appsFlyerService.init(
    onDeepLinkReceived: (value, fullData) {
      if (value != null) {
        Future.microtask(() => _handleAppsFlyerNavigation(value));
      }
    },
  );

  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    debugPrint(
      "🔗 [AppsFlyer Log] [FCM - initialMessage] 💀 Phát hiện App mở từ trạng thái Kill.",
    );
    debugPrint(
        "🔗 [AppsFlyer Log] [FCM - initialMessage] 📩 Data: ${initialMessage.data}");

    // debugPrint(
    //   "🔗 [AppsFlyer Log] [FCM - initialMessage] ⚡ Gọi handlePushNotification()",
    // );
    // appsFlyerService.handlePushNotification(initialMessage.data);
  }

  runApp(const MyApp());
}

void _handleAppsFlyerNavigation(String linkValue) async {
  int retry = 0;
  while (navigatorKey.currentState == null && retry < 10) {
    await Future.delayed(const Duration(milliseconds: 200));
    retry++;
  }

  final navState = navigatorKey.currentState;
  if (navState == null) {
    debugPrint(
      "🔗 [AppsFlyer Log] [_handleAppsFlyerNavigation] ⏳ Navigator chưa sẵn sàng, đợi frame tiếp theo...",
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAppsFlyerNavigation(linkValue);
    });
    return;
  }

  Widget? targetPage;

  switch (linkValue) {
    case 'cart_page':
      targetPage = const Cartpage();
      break;
    case 'checkout_page':
      targetPage = const Checkoutpage();
      break;
    case 'login_page':
      targetPage = const Loginpage();
      break;
    case 'product_page':
      targetPage = Productpage();
      break;
    case 'test_page':
      targetPage = const TestPage();
      break;
    default:
      if (linkValue.startsWith('http')) {
        _launchURL(linkValue);
      } else {
        debugPrint(
          '🔗 [AppsFlyer Log] ⚠️ Deeplink value "$linkValue" chưa được mapping.',
        );
      }
      AppsFlyerService().resetNavigationFlag();
      return;
  }

  if (targetPage != null) {
    AppsFlyerService().resetNavigationFlag();
    navState.push(MaterialPageRoute(builder: (_) => targetPage!));
  }
}

Future<void> _launchURL(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestATT();
    _setupFirebaseListeners();
    _getAndLogPushToken();
  }

  void _setupFirebaseListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        "🔗 [AppsFlyer Log] [FCM] onMessage - 📩 Nhận Push khi app Foreground",
      );
      debugPrint(
          "🔗 [AppsFlyer Log] [FCM] onMessage - 📩 Data: ${message.data}");

      if (Platform.isAndroid) {
        AppsFlyerService().performOnDeepLinking();
        debugPrint(
            "🔗 [AppsFlyer Log] [FCM] onMessage - ⚡ Gọi performOnDeepLinking()");
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
          "🔗 [AppsFlyer Log] [FCM] onMessageOpenedApp - ⚡ User click vào Push");

      debugPrint(
          "🔗 [AppsFlyer Log] [FCM] onMessageOpenedApp - ⚡ Gọi handlePushNotification()");
      AppsFlyerService().handlePushNotification(message.data);
    });
  }

  Future<void> _requestATT() async {
    if (Platform.isIOS) {
      await Future.delayed(const Duration(seconds: 2));

      var status = await AppTrackingTransparency.trackingAuthorizationStatus;

      if (status == TrackingStatus.notDetermined) {
        status = await AppTrackingTransparency.requestTrackingAuthorization();
      }

      if (status == TrackingStatus.authorized) {
        debugPrint(
          "🔗 [AppsFlyer Log] [ATT] ✅ User granted tracking permission",
        );

        final String idfa =
            await AppTrackingTransparency.getAdvertisingIdentifier();
        debugPrint("🔗 [AppsFlyer Log] [ATT] 🆔 IDFA: $idfa");
      } else {
        debugPrint(
          "🔗 [AppsFlyer Log] [ATT] ❌ User denied or restricted permission (Status: $status)",
        );
      }
    }
  }

  Future<void> _getAndLogPushToken() async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔗 [FCM] 🔔 User đã cấp quyền Push');

        String? token = await FirebaseMessaging.instance.getToken();

        if (token != null) {
          debugPrint('🔗 [FCM] 🔔 FCM TOKEN: $token');
        }
      } else {
        debugPrint(
          '🔗 [FCM] 🔔 User chưa cấp quyền Push',
        );
      }
    } catch (e) {
      debugPrint('🔗 [FCM] 🔔 Lỗi khi lấy Token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'AppsFlyer Demo App',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const TestPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
