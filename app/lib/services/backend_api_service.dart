import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bill_item.dart';

class BackendApiService {
  // Local host URL when testing locally (supports iOS Simulator / Android Emulator / macOS)
  static String baseUrl = 'http://localhost:3088';

  /// Create room on Backend
  static Future<bool> createRoom({
    required String roomId,
    required String hostName,
    required List<BillItem> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roomId': roomId,
          'hostName': hostName,
          'hostBankBin': '970432',
          'hostAccountNumber': '0395828955',
          'items': items.map((e) => e.toJson()).toList(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      // In offline / fallback mode, log error and proceed
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
