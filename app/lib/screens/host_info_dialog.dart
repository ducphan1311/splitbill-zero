import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bill_item.dart';
import '../services/backend_api_service.dart';
import '../theme/app_theme.dart';
import 'table_session_screen.dart';

class BankInfo {
  final String bin;
  final String shortName;
  final String name;

  const BankInfo({required this.bin, required this.shortName, required this.name});
}

const List<BankInfo> popularBanks = [
  BankInfo(bin: '970432', shortName: 'VPBank', name: 'VPBank (Việt Nam Thịnh Vượng)'),
  BankInfo(bin: '970436', shortName: 'Vietcombank', name: 'Vietcombank (VCB)'),
  BankInfo(bin: '970407', shortName: 'Techcombank', name: 'Techcombank (TCB)'),
  BankInfo(bin: '970422', shortName: 'MBBank', name: 'MBBank (Quân Đội)'),
  BankInfo(bin: '970416', shortName: 'ACB', name: 'ACB (Á Châu)'),
  BankInfo(bin: '970423', shortName: 'TPBank', name: 'TPBank (Tiên Phong)'),
  BankInfo(bin: '970415', shortName: 'VietinBank', name: 'VietinBank (Công Thương)'),
  BankInfo(bin: '970418', shortName: 'BIDV', name: 'BIDV (Đầu tư & Phát triển)'),
];

class HostInfoDialog extends StatefulWidget {
  final List<BillItem> items;

  const HostInfoDialog({super.key, required this.items});

  static Future<void> show(BuildContext context, List<BillItem> items) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HostInfoDialog(items: items),
    );
  }

  @override
  State<HostInfoDialog> createState() => _HostInfoDialogState();
}

class _HostInfoDialogState extends State<HostInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Phan Minh Đức');
  final _accountController = TextEditingController(text: '0395828955');
  BankInfo _selectedBank = popularBanks.first;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _submitAndCreateTable() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    // Generate dynamic Room ID (e.g., VN-4921)
    final randomDigits = 1000 + Random().nextInt(9000);
    final roomId = 'VN-$randomDigits';
    final hostName = _nameController.text.trim();
    final accountNumber = _accountController.text.trim();
    final bankBin = _selectedBank.bin;

    // Call Backend API to sync state
    try {
      await BackendApiService.createRoom(
        roomId: roomId,
        hostName: hostName,
        hostBankBin: bankBin,
        hostAccountNumber: accountNumber,
        items: widget.items,
      );
    } catch (e) {
      debugPrint('Sync room to backend failed: $e');
    }

    if (!mounted) return;
    setState(() => _isCreating = false);

    // Close bottom sheet
    Navigator.pop(context);

    // Navigate to TableSessionScreen with dynamic info
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TableSessionScreen(
          roomId: roomId,
          items: widget.items,
          hostName: hostName,
          hostBankBin: bankBin,
          hostAccountNumber: accountNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 12),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.slateCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.electricCyan, width: 2),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Thông Tin Nhận Tiền Của Host 👑', style: AppStyles.displayLarge),
                  const SizedBox(height: 4),
                  const Text(
                    'Để bạn bè trong bàn quét mã VietQR tự động điền STK & số tiền chính xác.',
                    style: AppStyles.bodyMedium,
                  ),
                  const SizedBox(height: 18),

                  // Host Name Input
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textPureWhite, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Họ và tên chủ bàn',
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.electricCyan),
                      filled: true,
                      fillColor: AppColors.oledCanvas,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tên chủ bàn' : null,
                  ),
                  const SizedBox(height: 12),

                  // Bank Dropdown Selector
                  DropdownButtonFormField<BankInfo>(
                    initialValue: _selectedBank,
                    dropdownColor: AppColors.slateCard,
                    style: const TextStyle(color: AppColors.textPureWhite),
                    decoration: InputDecoration(
                      labelText: 'Ngân hàng nhận tiền',
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.account_balance_outlined, color: AppColors.electricCyan),
                      filled: true,
                      fillColor: AppColors.oledCanvas,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    items: popularBanks.map((bank) {
                      return DropdownMenuItem(
                        value: bank,
                        child: Text('${bank.shortName} (${bank.name.split('(').last.replaceAll(')', '')})',
                            style: const TextStyle(fontSize: 14, color: AppColors.textPureWhite)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedBank = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Account Number Input
                  TextFormField(
                    controller: _accountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPureWhite, fontWeight: FontWeight.w700, letterSpacing: 1.1),
                    decoration: InputDecoration(
                      labelText: 'Số tài khoản / Số điện thoại nhận',
                      labelStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.credit_card, color: AppColors.amberGold),
                      filled: true,
                      fillColor: AppColors.oledCanvas,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập số tài khoản' : null,
                  ),
                  const SizedBox(height: 20),

                  // Confirm CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricCyan,
                        foregroundColor: AppColors.textDark,
                        elevation: 6,
                        shadowColor: AppColors.cyanGlow,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                      onPressed: _isCreating ? null : _submitAndCreateTable,
                      child: _isCreating
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                          : const Text('Xác Nhận & Khởi Tạo Bàn Ăn 🚀', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
