import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/bill_item.dart';

class BackendApiService {
  // Configurable Backend API URL (default to Render production or local dev)
  static String get baseUrl {
    const envUrl = String.fromEnvironment('BACKEND_API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:3088';
    }
    // Default fallback when deployed on free cloud container
    return 'https://splitbill-zero-server.onrender.com';
  }

  /// Send receipt image bytes to Backend OCR Engine (macOS Vision / Edge ML Kit)
  static Future<List<BillItem>> recognizeReceiptImage(Uint8List imageBytes, String filename) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/ocr'));
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['items'] != null) {
          final List list = data['items'];
          return list.map((item) => BillItem(
            id: item['id'] ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
            name: item['name'] ?? 'Món',
            price: (item['price'] as num?)?.toDouble() ?? 0.0,
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          )).toList();
        }
      }
    } catch (e) {
      debugPrint('Backend OCR error: $e');
    }
    return [];
  }

  /// Create room on Backend
  static Future<bool> createRoom({
    required String roomId,
    required String hostName,
    required String hostBankBin,
    required String hostAccountNumber,
    required List<BillItem> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roomId': roomId,
          'hostName': hostName,
          'hostBankBin': hostBankBin,
          'hostAccountNumber': hostAccountNumber,
          'items': items.map((e) => e.toJson()).toList(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetch live room snapshot from Backend
  static Future<Map<String, dynamic>?> getRoomSnapshot(String roomId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/rooms/$roomId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }
}
