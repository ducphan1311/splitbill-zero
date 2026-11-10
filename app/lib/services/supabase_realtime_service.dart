import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bill_item.dart';

class SupabaseRealtimeService {
  static SupabaseClient? _client;
  static RealtimeChannel? _roomChannel;

  /// Initialize Supabase with Project URL & Anon Key
  /// Supports both Supabase Cloud and local Supabase instance
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,
      ),
    );
    _client = Supabase.instance.client;
  }

  /// Broadcast updated room state or item additions
  static void joinRoom({
    required String roomId,
    required Function(Map<String, dynamic> payload) onRoomUpdate,
  }) {
    if (_client == null) return;

    _roomChannel = _client!.channel('room:$roomId');

    _roomChannel!
        .onBroadcast(
          event: 'table_state',
          callback: (payload) {
            onRoomUpdate(payload);
          },
        )
        .subscribe();
  }

  /// Broadcast new bill items to all dining guests
  static Future<void> broadcastTableUpdate({
    required String roomId,
    required List<BillItem> items,
  }) async {
    if (_roomChannel == null) return;

    await _roomChannel!.sendBroadcastMessage(
      event: 'table_state',
      payload: {
        'roomId': roomId,
        'items': items.map((e) => e.toJson()).toList(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> leaveRoom() async {
    if (_roomChannel != null && _client != null) {
      await _client!.removeChannel(_roomChannel!);
      _roomChannel = null;
    }
  }
}
