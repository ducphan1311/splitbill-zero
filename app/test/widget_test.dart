import 'package:flutter_test/flutter_test.dart';
import 'package:splitbill_zero_host/main.dart';

void main() {
  testWidgets('SplitBillZeroHostApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SplitBillZeroHostApp());
    expect(find.text('Quét Hóa Đơn Trực Tiếp'), findsOneWidget);
  });
}
