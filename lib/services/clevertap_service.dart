import 'package:clevertap_plugin/clevertap_plugin.dart';

class CleverTapService {
  // Khởi tạo mẫu Singleton
  static final CleverTapService _instance = CleverTapService._internal();
  factory CleverTapService() => _instance;
  CleverTapService._internal();

  /// Hàm khởi tạo cấu hình ban đầu cho CleverTap
  void initialize() {
    // Bật log debug để bạn dễ dàng theo dõi dữ liệu trên console khi dev
    CleverTapPlugin.setDebugLevel(3);

    // Đăng ký các callback xử lý sự kiện từ CleverTap (ví dụ: nhận thông báo đẩy)
    // _registerCallbacks();
  }

  /// Đăng ký các cổng lắng nghe sự kiện từ SDK
//   void _registerCallbacks() {
//     // Lắng nghe khi người dùng tương tác, nhấn vào thông báo Push
//     CleverTapPlugin.onPushNotificationClicked((Map<String, dynamic> payload) {
//       print("🔗 [CleverTap Service] Người dùng nhấn Push Notification: $payload");
//       // Xử lý logic điều hướng (Deep link) hoặc tracking nội bộ của bạn tại đây
//     });

//     // Lắng nghe khi có thông báo App Inbox mới (Nếu bạn có dùng App Inbox)
//     CleverTapPlugin.onCleverTapInboxDidInitialize(() {
//       print("🔗 [CleverTap Service] App Inbox đã khởi tạo xong");
//     });
//   }

  /// Định danh User (Profile) khi họ đăng nhập thành công
  void onUserLogin(String userId,
      {String? name, String? email, String? phone}) {
    var profile = {
      'Identity': userId,
      if (name != null) 'Name': name,
      if (email != null) 'Email': email,
      if (phone != null) 'Phone': phone,
    };
    CleverTapPlugin.onUserLogin(profile);
    print("🔗 [CleverTap Service] Đã định danh User: $userId");
  }

  /// Log một sự kiện thông thường (Ví dụ: xem sản phẩm, click banner)
  void logEvent(String eventName, [Map<String, dynamic>? properties]) {
    CleverTapPlugin.recordEvent(eventName, properties ?? {});
    print(
        "🔗 [CleverTap Service] Ghi nhận Event: $eventName với data: $properties");
  }

  /// Log sự kiện mua hàng (Charged Event) đặc biệt của CleverTap
//   void logChargedEvent(Map<String, dynamic> chargeDetails, List<Map<String, dynamic>> items) {
//     CleverTapPlugin.recordChargedEvent(chargeDetails, items);
//     print("🔗 [CleverTap Service] Ghi nhận Charged Event thành công");
//   }

  /// Cập nhật Token thông báo khi có thay đổi từ Firebase / APNS
  void setPushToken(String token) {
    CleverTapPlugin.setPushToken(token);
  }

  /// Lấy CleverTap ID của thiết bị hiện tại
  Future<String?> getCleverTapID() async {
    try {
      String? clevertapId = await CleverTapPlugin.getCleverTapID();
      print("🔗 [CleverTap Service] Lấy CleverTap ID thành công: $clevertapId");
      return clevertapId;
    } catch (error) {
      print("🔗 [CleverTap Service] Lỗi khi lấy CleverTap ID: $error");
      return null; // Trả về null nếu xảy ra lỗi để tránh crash app
    }
  }
}
