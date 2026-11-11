import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bill_item.dart';
import '../services/backend_api_service.dart';
import '../theme/app_theme.dart';

class TableSessionScreen extends StatefulWidget {
  final String roomId;
  final List<BillItem> items;
  final String hostName;
  final String hostBankBin;
  final String hostAccountNumber;

  const TableSessionScreen({
    super.key,
    required this.roomId,
    required this.items,
    this.hostName = 'Phan Minh Đức',
    this.hostBankBin = '970432',
    this.hostAccountNumber = '0395828955',
  });

  @override
  State<TableSessionScreen> createState() => _TableSessionScreenState();
}

class _TableSessionScreenState extends State<TableSessionScreen> {
  List<DiningGuest> guests = [];
  Timer? _pollingTimer;
  String _roomStatus = 'OPEN';
  bool _isLoadingGuests = true;

  @override
  void initState() {
    super.initState();
    // Initialize host as first member
    guests = [
      DiningGuest(
        id: 'host',
        name: widget.hostName,
        isHost: true,
        claimedItemIds: [],
      ),
    ];
    _fetchLiveRoomState();
    // Poll backend every 2.5 seconds to sync members and claims in real-time
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _fetchLiveRoomState();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveRoomState() async {
    try {
      final snapshot = await BackendApiService.getRoomSnapshot(widget.roomId);
      if (snapshot != null && mounted) {
        final Map<String, dynamic> rawGuests = snapshot['guests'] ?? {};
        final status = snapshot['status'] ?? 'OPEN';

        final List<DiningGuest> updatedGuests = [];

        // Parse all guests from Backend
        bool hostFound = false;
        rawGuests.forEach((key, val) {
          if (val is Map<String, dynamic>) {
            final isHost = val['isHost'] == true || key == 'host';
            if (isHost) hostFound = true;
            final claimedList = (val['claimedItemIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
            updatedGuests.add(DiningGuest(
              id: val['guestId'] ?? key,
              name: val['guestName'] ?? 'Khách',
              isHost: isHost,
              claimedItemIds: claimedList,
            ));
          }
        });

        if (!hostFound) {
          updatedGuests.insert(
            0,
            DiningGuest(
              id: 'host',
              name: widget.hostName,
              isHost: true,
              claimedItemIds: [],
            ),
          );
        }

        setState(() {
          guests = updatedGuests;
          _roomStatus = status;
          _isLoadingGuests = false;
        });
      }
    } catch (_) {}
  }

  String get tableUrl =>
      '${const String.fromEnvironment('WEB_BASE_URL', defaultValue: 'https://splitbill-zero.vercel.app')}/room/${widget.roomId}';

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: tableUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép link bàn vào bộ nhớ tạm!'),
        backgroundColor: AppColors.electricCyan,
      ),
    );
  }

  void _shareTable() {
    SharePlus.instance.share(
      ShareParams(
        text: 'Mời bạn vào bàn chia tiền ăn uống #${widget.roomId} qua link: $tableUrl (Không cần cài app, mở trực tiếp bằng Camera hoặc trình duyệt web)',
        subject: 'SplitBill Zero - Bàn #${widget.roomId}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oledCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Bàn Ăn Trực Tiếp', style: AppStyles.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPureWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Room Tag Pill
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.emeraldBadge,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '● LIVE TABLE #${widget.roomId}',
                  style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),

              const Text('Mời Bạn Bè Vào Bàn', style: AppStyles.displayLarge),
              const SizedBox(height: 6),
              const Text('Không cần cài app • Quét bằng Camera / Zalo / Web', style: AppStyles.bodyMedium),
              const SizedBox(height: 18),

              // QR Outer Bezel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.slateCardSubtle,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Column(
                  children: [
                    // QR Code Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: QrImageView(
                        data: tableUrl,
                        version: QrVersions.auto,
                        size: 150.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Actions (Copy Link & Share)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _copyLink,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.electricCyan.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.electricCyan.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.link, size: 16, color: AppColors.electricCyan),
                                  SizedBox(width: 6),
                                  Text('Sao chép link', style: TextStyle(color: AppColors.electricCyan, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: _shareTable,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.emeraldGreen.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.share_outlined, size: 16, color: AppColors.emeraldGreen),
                                  SizedBox(width: 6),
                                  Text('Chia sẻ bàn', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section Header: Joined Guests
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'THÀNH VIÊN ĐÃ THAM GIA (${guests.length} ONLINE)',
                  style: AppStyles.caption.copyWith(letterSpacing: 1.1, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),

              // Guests List
              ...guests.map((g) {
                // Find names of dishes claimed by this guest
                final claimedDishNames = widget.items
                    .where((dish) => g.claimedItemIds.contains(dish.id))
                    .map((dish) => dish.name)
                    .toList();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.slateCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: g.isHost ? AppColors.amberGold.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: g.isHost ? AppColors.amberGold : AppColors.electricCyan,
                            child: Text(g.name.isNotEmpty ? g.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.name, style: const TextStyle(color: AppColors.textPureWhite, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  g.claimedItemIds.isNotEmpty
                                      ? 'Đã chọn ${g.claimedItemIds.length} món'
                                      : 'Đang lướt menu chọn món...',
                                  style: AppStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          if (g.isHost)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.amberBadge,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.amberGold.withValues(alpha: 0.4)),
                              ),
                              child: const Text('HOST 👑', style: TextStyle(color: AppColors.amberGold, fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: g.claimedItemIds.isNotEmpty
                                    ? AppColors.emeraldBadge
                                    : AppColors.cyanGlow.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: g.claimedItemIds.isNotEmpty
                                      ? AppColors.emeraldGreen.withValues(alpha: 0.4)
                                      : AppColors.electricCyan.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                g.claimedItemIds.isNotEmpty ? 'ĐÃ CHỌN ✓' : 'ĐANG CHỌN...',
                                style: TextStyle(
                                  color: g.claimedItemIds.isNotEmpty ? AppColors.emeraldGreen : AppColors.electricCyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (claimedDishNames.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: claimedDishNames.map((dishName) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.oledCanvas,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                              ),
                              child: Text(
                                dishName,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Lock Table & Calculate Split Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _roomStatus == 'LOCKED' ? Colors.white.withValues(alpha: 0.1) : AppColors.electricCyan,
                    foregroundColor: _roomStatus == 'LOCKED' ? AppColors.textMuted : AppColors.textDark,
                    shadowColor: AppColors.cyanGlow,
                    elevation: _roomStatus == 'LOCKED' ? 0 : 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (_roomStatus == 'LOCKED') {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Bàn đã được khóa trước đó.'),
                          backgroundColor: AppColors.electricCyan,
                        ),
                      );
                      return;
                    }
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Đang gửi lệnh khóa bàn & chốt danh sách để mở thanh toán...'),
                        backgroundColor: AppColors.amberGold,
                      ),
                    );
                    final success = await BackendApiService.lockRoom(widget.roomId);
                    if (!mounted) return;
                    if (success) {
                      setState(() {
                        _roomStatus = 'LOCKED';
                      });
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('🔒 Đã chốt bàn! Mọi người trên web hiện đã có thể bấm Thanh Toán VietQR.'),
                          backgroundColor: AppColors.emeraldGreen,
                        ),
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _roomStatus == 'LOCKED' ? Icons.lock_outline : Icons.lock_open_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _roomStatus == 'LOCKED'
                            ? 'BÀN ĐÃ KHÓA (MỌI NGƯỜI ĐANG THANH TOÁN)'
                            : 'Chốt Món & Mở Khóa Thanh Toán Cho Cả Bàn 🚀',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Host Bank Info Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slateCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.amberGold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TÀI KHOẢN NHẬN TIỀN CỦA HOST', style: AppStyles.caption.copyWith(fontSize: 10)),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.hostName} • STK: ${widget.hostAccountNumber} (BIN: ${widget.hostBankBin})',
                            style: const TextStyle(color: AppColors.textPureWhite, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Status Warning Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _roomStatus == 'LOCKED'
                      ? AppColors.emeraldBadge
                      : AppColors.amberBadge,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _roomStatus == 'LOCKED'
                        ? AppColors.emeraldGreen.withValues(alpha: 0.3)
                        : AppColors.amberGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    _roomStatus == 'LOCKED'
                        ? '🔒 Bàn đã khóa! Khách đang thanh toán VietQR chuyển khoản'
                        : _isLoadingGuests
                            ? '⚡ Đang đồng bộ trạng thái bàn realtime...'
                            : guests.length > 1
                                ? '● ${guests.length - 1} khách đang mở link và chọn món trên web'
                                : '📱 Hãy gửi link hoặc đưa mã QR cho bạn bè quét để chọn món!',
                    style: TextStyle(
                      color: _roomStatus == 'LOCKED' ? AppColors.emeraldGreen : AppColors.amberGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
