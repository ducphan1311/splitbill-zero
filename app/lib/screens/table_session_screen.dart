import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bill_item.dart';
import '../theme/app_theme.dart';

class TableSessionScreen extends StatefulWidget {
  final String roomId;
  final List<BillItem> items;

  const TableSessionScreen({
    super.key,
    required this.roomId,
    required this.items,
  });

  @override
  State<TableSessionScreen> createState() => _TableSessionScreenState();
}

class _TableSessionScreenState extends State<TableSessionScreen> {
  late List<DiningGuest> guests;

  @override
  void initState() {
    super.initState();
    // Default simulated dining guests matching Figma Screen 02
    guests = [
      DiningGuest(id: '1', name: 'Phan Minh Đức', isHost: true, claimedItemIds: ['item_hotpot']),
      DiningGuest(id: '2', name: 'Trần Hải Nam', claimedItemIds: ['item_tea', 'item_water']),
      DiningGuest(id: '3', name: 'Nguyễn Thùy Linh', claimedItemIds: []),
    ];
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
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: g.isHost ? AppColors.amberGold : AppColors.electricCyan,
                        child: Text(g.name[0], style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.name, style: const TextStyle(color: AppColors.textPureWhite, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              g.claimedItemIds.isNotEmpty ? 'Đã chọn ${g.claimedItemIds.length} món' : 'Đang lướt menu chọn món...',
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
                            color: AppColors.cyanGlow.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.electricCyan.withValues(alpha: 0.4)),
                          ),
                          child: const Text('CHỌN...', style: TextStyle(color: AppColors.electricCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
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
                    backgroundColor: AppColors.electricCyan,
                    shadowColor: AppColors.cyanGlow,
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã chốt bàn! Đang tính toán ma trận chia tiền và tạo VietQR...'),
                        backgroundColor: AppColors.emeraldGreen,
                      ),
                    );
                  },
                  child: const Text(
                    'Khóa Bàn & Tiến Hành Chia Tiền →',
                    style: TextStyle(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Status Warning Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.amberBadge,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.amberGold.withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Text(
                    '⏳ Chờ Linh hoàn tất chọn món (1 người đang chọn)',
                    style: TextStyle(color: AppColors.amberGold, fontSize: 12, fontWeight: FontWeight.w500),
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
