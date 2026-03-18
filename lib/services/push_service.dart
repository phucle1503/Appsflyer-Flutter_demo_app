import 'dart:convert';
import 'dart:io';

import 'package:af_flutter_sample/pages/product_page.dart';
// import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../pages/cart_page.dart';
import '../pages/login_page.dart';

class PushService {
  PushService._internal();
  static final PushService _instance = PushService._internal();
  factory PushService() => _instance;

  // final CleverTapPlugin _ct = CleverTapPlugin();

  Future<void> init() async {
    await Firebase.initializeApp();
    await FirebaseMessaging.instance.requestPermission();

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      // CleverTapPlugin.setPushToken(token);
      debugPrint('[FCM token] $token');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      // CleverTapPlugin.setPushToken(newToken);
      debugPrint('[FCM token refresh] $newToken');
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage m) {
      debugPrint('[FCM onMessage] ${m.data}');
      // CleverTapPlugin.createNotification(jsonEncode(m.data));
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage m) {
      debugPrint('[FCM onMessageOpenedApp] ${m.data}');
      _handleNotificationClick(m.data);
    });

    // _ct.setCleverTapPushClickedPayloadReceivedHandler(
    //     pushClickedPayloadReceived);
    FirebaseMessaging.onBackgroundMessage(_onBackground);

    // _configureCleverTapChannel();
  }

  /* ---------------- HANDLER PUSH CLICK (từ CT callback) ------------- */
  void pushClickedPayloadReceived(Map<String, dynamic> payload) {
    debugPrint('[CT Push Clicked] Notification payload  $payload');
    _handleNotificationClick(payload);
  }

  /* -------------------- COMMON CLICK HANDLER ------------------------ */
  void _handleNotificationClick(Map<String, dynamic> payload) {
    final link = payload['wzrk_dl'] as String?;
    if (link == null) return;
    debugPrint('[Navigate] wzrk_dl = $link');
    _navigateByDeepLink(link);
  }

  /* --------------------- NAVIGATION LOGIC --------------------------- */
  void _navigateByDeepLink(String link) async {
    final uri = Uri.parse(link);
    debugPrint('[DeepLink] URI = $uri');
    debugPrint('[DeepLink] host=${uri.host}, path=${uri.path}');

    if (uri.scheme == 'abc') {
      final path =
          uri.host.isNotEmpty ? uri.host : uri.path.replaceFirst('/', '');

      switch (path) {
        case 'cart':
          _pushIfPossible(const Cartpage());
          return;
        case 'login':
          _pushIfPossible(const Loginpage());
          return;
        case 'product':
          _pushIfPossible(Productpage());
          return;
        default:
          debugPrint('[DeepLink] Không tìm thấy path: $path');
          return;
      }
    }

    if (['http', 'https'].contains(uri.scheme) && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _pushIfPossible(Widget page) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));
    } else {
      debugPrint('[Navigator] Context not ready, cannot push');
    }
  }

  /* ------------- BACKGROUND ISOLATE HANDLER ------------------------- */
  static Future<void> _onBackground(RemoteMessage msg) async {
    debugPrint('[FCM BG isolate] ${msg.data}');
  }

  /* ----------------- NOTIFICATION CHANNEL --------------------------- */
  // void _configureCleverTapChannel() {
  //   if (Platform.isAndroid) {
  //     CleverTapPlugin.createNotificationChannelWithSound('Flutter Test',
  //         'Flutter Test', 'Flutter Test', 3, true, 'sound1.mp3');
  //     CleverTapPlugin.createNotificationChannelWithSound('Custom_Channel',
  //         'Custom_Channel', 'Custom_Channel', 3, true, 'lmao.mp3');
  //   }
  //   CleverTapPlugin.setDebugLevel(4);
  // }
}
