// import 'dart:io';
// import 'package:af_flutter_sample/pages/checkout_page.dart';
// import 'package:af_flutter_sample/pages/product_page.dart';
// import 'package:flutter/material.dart';
// import 'package:appsflyer_sdk/appsflyer_sdk.dart';
// import 'package:flutter/services.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:af_flutter_sample/services/push_service.dart';
// import 'pages/login_page.dart';
// import 'pages/cart_page.dart';
// import 'pages/test_page.dart';
// import 'package:af_flutter_sample/services/appsflyer_service.dart';

// @pragma('vm:entry-point')
// void _onKilledStateNotificationClickedHandler(
//     Map<String, dynamic> payload) async {
//   debugPrint('[KilledState] Payload: $payload');
// }

// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await AppsFlyerService().init(
//     onDeepLinkReceived: (value, fullData) { 
//       debugPrint("🔗 [AppsFlyer Deeplink] DeepLink value: $value");
//       debugPrint("🔗 [AppsFlyer Deeplink] DeepLink data: $fullData");

//       if (value != null) {
//         // Vì _navigateByDeepLink nằm trong State của MyApp, 
//         // bạn có thể dùng navigatorKey để điều hướng trực tiếp hoặc xử lý string
//         _handleUnifiedNavigation(value);
//       }
//     },
//   );
//   runApp(const MyApp());
// }

// void _handleUnifiedNavigation(String link) {
//   final currentState = navigatorKey.currentState;
//   if (currentState == null) {
//     debugPrint("❌ Navigator State is null");
//     return;
//   }

//   debugPrint("🚀 Processing Navigation for: $link");

//   // 1. Nếu link là một URI (ví dụ abc://cart hoặc https://...)
//   if (link.contains("://")) {
//     final uri = Uri.parse(link);
    
//     // Xử lý Scheme nội bộ abc://
//     if (uri.scheme == 'abc') {
//       _navigateToPageByPath(uri.path);
//       return;
//     }
//     // Xử lý link web ngoài
//     _launchExternalUrl(uri);
//     return;
//   }
//   // 2. Nếu link là Deep Link Value thuần túy từ AppsFlyer Dashboard
//   // (Ví dụ: "cart_page", "product_page",...)
//   _navigateToPageByPath("/$link");
// }

// /// Chuyển đổi path/value thành Page tương ứng
// void _navigateToPageByPath(String path) {
//   // Chuẩn hóa path để switch case chính xác
//   final cleanPath = path.startsWith('/') ? path : '/$path';
  
//   Widget? targetPage;

//   switch (cleanPath) {
//     case '/cart_page':
//     case '/cart':
//       targetPage = const Cartpage();
//       break;
//     case '/checkout_page':
//     case '/checkout':
//       targetPage = const Checkoutpage();
//       break;
//     case '/login_page':
//     case '/login':
//       targetPage = const Loginpage();
//       break;
//     case '/product_page':
//     case '/product':
//       targetPage = Productpage();
//       break;
//     case '/test_page':
//     case '/test':
//       targetPage = const TestPage();
//       break;
//     default:
//       debugPrint('⚠️ Không tìm thấy trang phù hợp cho path: $cleanPath');
//       return;
//   }
//   if (targetPage != null) {
//     navigatorKey.currentState?.push(
//       MaterialPageRoute(builder: (_) => targetPage!),
//     );
//   }
// }

// Future<void> _launchExternalUrl(Uri uri) async {
//   if (await canLaunchUrl(uri)) {
//     await launchUrl(uri, mode: LaunchMode.externalApplication);
//   }
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   static const platform = MethodChannel('deeplink_channel');

//   @override
//   void initState() {
//     super.initState();


//     if (Platform.isAndroid) {
//       // _checkLaunchFromNotification();
//       // platform.setMethodCallHandler(_handleRuntimeDeeplink);
//     }

//   }

//   void _handleDeepLinkString(String? wzrkDl) {
//     if (wzrkDl == null) return;

//     debugPrint('[wzrk_dl] $wzrkDl');
//     _navigateByDeepLink(wzrkDl);
//   }

//   /* -------------------- DeepLink Navigator -------------------- */
//   void _navigateByDeepLink(String link) async {
//     final uri = Uri.parse(link);

//     if (uri.scheme == 'abc') {
//       switch (uri.path) {
//         case '/cart':
//           _pushIfPossible(const Cartpage());
//           break;
//         case '/login':
//           _pushIfPossible(const Loginpage());
//           break;
//         case '/product':
//           _pushIfPossible(Productpage());
//           break;
//         case '/checkout':
//           _pushIfPossible(const Checkoutpage());
//           break;
//         default:
//           debugPrint('[DeepLink] Không tìm thấy path: ${uri.path}');
//       }
//       return;
//     }

//     if (uri.scheme == 'http' || uri.scheme == 'https') {
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri, mode: LaunchMode.externalApplication);
//       }
//     }
//   }

//   void _pushIfPossible(Widget page) {
//     final ctx = navigatorKey.currentContext;
//     debugPrint('[NavigatorContext] $ctx');
//     debugPrint('[NavigatorState] ${navigatorKey.currentState}');

//     if (ctx != null) {
//       Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));
//     }
//   }

//   /* -------------------- UI -------------------- */
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       title: 'AppsFlyer Demo App',
//       theme: ThemeData(primarySwatch: Colors.red),
//       home: const TestPage(),
//     );
//   }
// }

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
void _onKilledStateNotificationClickedHandler(Map<String, dynamic> payload) async {
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
void _handleAppsFlyerNavigation(String linkValue) {
  final navState = navigatorKey.currentState;
  if (navState == null) {
    debugPrint("⏳ Navigator chưa sẵn sàng, đang thử lại...");
    Future.delayed(const Duration(milliseconds: 500), () => _handleAppsFlyerNavigation(linkValue));
    return;
  }

  Widget? targetPage;

  // Logic mapping trực tiếp từ Deeplink Value trên Dashboard vào Page
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
        debugPrint('⚠️ Deeplink value "$linkValue" chưa được cấu hình trang.');
      }
      return;
  }

  if (targetPage != null) {
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
    // Giữ nguyên initState để bạn tiếp tục phát triển các logic OS khác nếu cần
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