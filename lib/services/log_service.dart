import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class LogService {
  static const String _googleSheetUrl = 
      "https://script.google.com/macros/s/AKfycbxNr27dvVo17RzeUWN8hzip6RdIIBCNLvdfW-F84ZBozQGlSwSYKezqnvKg5oUkbeFd/exec";

  static Future<void> sendLogToGoogleSheet({
    String method = "", 
    dynamic data, 
    String? afId, 
  }) async {
    try {
      String timestamp = DateTime.now().toUtc().toIso8601String();
      Map<String, dynamic> payload = {
        "method": method,
        "appsflyer_id": afId ?? "N/A", 
        "data": data ?? {},
        "timestamp": timestamp,
      };

      String jsonBody = jsonEncode(payload);
      debugPrint("🚀 [LogService] Đang gửi JSON đến Google Sheet: $jsonBody");

      final response = await http.post(
        Uri.parse(_googleSheetUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        print("✅ [LogService] Gửi log thành công");
      } else {
        print("❌ [LogService] Lỗi server: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ [LogService] Request error: $e");
    }
  }
}