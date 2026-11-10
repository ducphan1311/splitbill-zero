import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill_item.dart';
import '../theme/app_theme.dart';
import 'table_session_screen.dart';

class EditBillItemsScreen extends StatefulWidget {
  final List<BillItem> initialItems;
  final VoidCallback? onBackToScan;

  const EditBillItemsScreen({
    super.key,
    required this.initialItems,
    this.onBackToScan,
  });

  @override
  State<EditBillItemsScreen> createState() => _EditBillItemsScreenState();
}

class _EditBillItemsScreenState extends State<EditBillItemsScreen> {
  late List<BillItem> items;
  final currencyFormat = NumberFormat("#,##0", "vi_VN");

  @override
  void initState() {
    super.initState();
    items = List.from(widget.initialItems);
  }

  double get totalSum => items.fold(0, (sum, item) => sum + item.totalPrice);

  void _incrementQty(int index) {
    setState(() {
      items[index].quantity++;
    });
  }

  void _decrementQty(int index) {
    setState(() {
      if (items[index].quantity > 1) {
        items[index].quantity--;
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _addNewCustomItem() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.slateCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String name = '';
        double price = 0;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thêm món ngoài hóa đơn',
                style: AppStyles.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                style: const TextStyle(color: AppColors.textPureWhite),
                decoration: InputDecoration(
                  labelText: 'Tên món (vd: Khăn lạnh, Bia thêm)',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cyanBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.electricCyan),
                  ),
                ),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 12),
              TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPureWhite),
                decoration: InputDecoration(
                  labelText: 'Giá tiền (VNĐ)',
                  labelStyle: const TextStyle(color: AppColors.textMuted),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cyanBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.electricCyan),
                  ),
                ),
                onChanged: (val) => price = double.tryParse(val) ?? 0,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricCyan,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (name.isNotEmpty && price > 0) {
                      setState(() {
                        items.add(BillItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: name,
                          price: price,
                          quantity: 1,
                        ));
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Thêm vào bàn', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oledCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Chi Tiết Món Sau Quét AI', style: AppStyles.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPureWhite),
          onPressed: widget.onBackToScan ?? () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cyanGlow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.electricCyan.withValues(alpha: 0.4)),
              ),
              child: const Text(
                '✏️ CHỈNH SỬA & KIỂM TRA MÓN (HOST)',
                style: TextStyle(color: AppColors.electricCyan, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const Text(
              'Chạm để sửa tên, giá hoặc thêm món ngoài hóa đơn',
              style: AppStyles.bodyMedium,
            ),
            const SizedBox(height: 12),

            // Items List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.slateCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cyanBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${index + 1}. ${item.name}', style: const TextStyle(color: AppColors.textPureWhite, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('${currencyFormat.format(item.price)} đ', style: const TextStyle(color: AppColors.amberGold, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        // Qty Controller
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18, color: AppColors.electricCyan),
                                onPressed: () => _decrementQty(index),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                              ),
                              Text('${item.quantity}', style: const TextStyle(color: AppColors.textPureWhite, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18, color: AppColors.electricCyan),
                                onPressed: () => _incrementQty(index),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.rubyRed, size: 20),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Add Custom Item Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: AppColors.electricCyan, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: AppColors.electricCyan.withValues(alpha: 0.08),
                ),
                onPressed: _addNewCustomItem,
                child: const Text('+  Thêm món ngoài hóa đơn', style: TextStyle(color: AppColors.electricCyan, fontWeight: FontWeight.w600)),
              ),
            ),

            // Total Summary Box
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1322),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tổng tiền sau điều chỉnh:', style: AppStyles.caption),
                      SizedBox(height: 4),
                      Text('✓ Khớp hóa đơn gốc', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text('${currencyFormat.format(totalSum)} đ', style: const TextStyle(color: AppColors.amberGold, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Bottom CTA Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricCyan,
                        elevation: 8,
                        shadowColor: AppColors.cyanGlow,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TableSessionScreen(
                              roomId: 'VN-8842',
                              items: items,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Lưu Món & Tạo Bàn Chia Tiền →',
                        style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
