import 'dart:io';
import 'package:af_flutter_sample/pages/checkout_page.dart';
import 'package:af_flutter_sample/pages/product_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pages/login_page.dart';
import 'pages/cart_page.dart';
import 'pages/test_page.dart';
import 'package:af_flutter_sample/services/appsflyer_service.dart';

@pragma('vm:entry-point')
void _onKilledStateNotificationClickedHandler(
    Map<String, dynamic> payload) async {
  debugPrint('[KilledState] Payload: $payload');
}

// GlobalKey giúp điều hướng từ bất cứ đâu mà không cần BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppsFlyerService().init(
    onDeepLinkReceived: (value, fullData) {
      debugPrint("🔗 [AppsFlyer Deeplink] DeepLink value: $value");

      if (value != null) {
        // Đợi 1 frame để chắc chắn Navigator đã mount xong (quan trọng cho Cold Start)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleAppsFlyerNavigation(value);
        });
      }
    },
  );
  runApp(const MyApp());
}

/// Hàm điều hướng dành riêng cho AppsFlyer Deep Link Value
void _handleAppsFlyerNavigation(String linkValue) async {
  var navState = navigatorKey.currentState;
  int retryCount = 0;

  while (navState == null && retryCount < 10) {
    await Future.delayed(const Duration(milliseconds: 500));
    navState = navigatorKey.currentState;
    retryCount++;
    debugPrint("🔗 [AppsFlyer Log] ⏳ Đang đợi Navigator... lần $retryCount");
  }

  if (navState == null) {
    debugPrint("🔗 [AppsFlyer Log] ❌ Không thể tìm thấy Navigator sau 5 giây.");
    AppsFlyerService().resetNavigationFlag();
    return;
  }

  debugPrint("🔗 [AppsFlyer Log] 🚀 Bắt đầu Push trang: $linkValue");

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
      // Nếu linkValue là một URL đầy đủ (ví dụ: https://...)
      if (linkValue.startsWith('http')) {
        _launchURL(linkValue);
      } else {
        debugPrint(
            '🔗 [AppsFlyer Log] ⚠️ Deeplink value "$linkValue" chưa được mapping.');
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
  static const platform = MethodChannel('deeplink_channel');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Rất quan trọng
      title: 'AppsFlyer Demo App',
      theme: ThemeData(primarySwatch: Colors.red),
      home: const TestPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
