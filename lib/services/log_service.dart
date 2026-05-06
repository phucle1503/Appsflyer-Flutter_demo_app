import 'dart:convert';
import 'package:http/http.dart' as http;

class LogService {
  static const String _googleSheetUrl = 
      "https://script.google.com/macros/s/AKfycby22BlwuzgETh1AAG-to-6KTHK8HPPcpkHEFYUJnGUsuyAGJAocJfq2CvdhSkvXbGVa/exec";

  static Future<void> sendLogToGoogleSheet({String method = "", dynamic data}) async {
    try {
      // Tạo timestamp tương tự ISO8601 trong Swift
      String timestamp = DateTime.now().toUtc().toIso8601String();

      // Tạo payload
      Map<String, dynamic> payload = {
        "method": method,
        "data": data,
        "timestamp": timestamp,
      };

      // Gửi request POST
      final response = await http.post(
        Uri.parse(_googleSheetUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        // Lưu ý: Google Apps Script thường trả về redirect (302) 
        // nhưng thư viện http sẽ tự động handle hoặc trả về 200 nếu thành công
        print("✅ [LogAPI] Gửi log thành công");
      } else {
        print("❌ [LogAPI] Lỗi server: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ [LogAPI] Request error: $e");
    }
  }
}