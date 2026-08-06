// E2E — UC 3.1.14 Top-Up: กรอกจำนวนเงิน กด "ดำเนินการ" ครบ flow
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;

import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E UC 3.1.14 — Wallet Top-Up (full flow)', () {
    testWidgets('กรอกจำนวน 500 บาท → ดำเนินการเติมเงิน → เห็น success', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ─── กด tab กระเป๋าเงิน ───
      final walletTab = find.text('กระเป๋าเงิน');
      if (tester.any(walletTab)) {
        await tester.tap(walletTab.first);
      } else {
        await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
      }
      await waitForWidget(tester, find.text('ยอดที่ใช้ได้'),
          timeout: const Duration(seconds: 10));

      // ─── กดปุ่มเติมเงิน ───
      await tester.tap(find.text('+ เติมเงิน'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ─── อยู่บน TopUpPage ───
      final amountField = find.byKey(const Key('field_amount'));
      await waitForWidget(tester, amountField,
          timeout: const Duration(seconds: 5));

      // ลบค่าเดิมแล้วกรอก 500
      await tester.tap(amountField);
      await tester.pumpAndSettle();
      await tester.enterText(amountField, '500');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ─── กด "ดำเนินการเติมเงิน" ───
      final nextBtn = find.byKey(const Key('btn_next_step'));
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ─── ตรวจสอบ: เห็น confirmation หรือ success ───
      final successIndicator = find.byWidgetPredicate((w) =>
          w is Text &&
          (w.data?.contains('สรุป') == true ||
              w.data?.contains('ยืนยัน') == true ||
              w.data?.contains('เติมเงินสำเร็จ') == true ||
              w.data?.contains('500') == true));
      expect(successIndicator, findsWidgets);
    });

    testWidgets('กรอกจำนวนต่ำกว่า 100 บาท → ปุ่มยังไม่ active', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final walletTab = find.text('กระเป๋าเงิน');
      if (tester.any(walletTab)) {
        await tester.tap(walletTab.first);
      } else {
        await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
      }
      await waitForWidget(tester, find.text('ยอดที่ใช้ได้'),
          timeout: const Duration(seconds: 10));

      await tester.tap(find.text('+ เติมเงิน'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final amountField = find.byKey(const Key('field_amount'));
      await waitForWidget(tester, amountField,
          timeout: const Duration(seconds: 5));

      await tester.tap(amountField);
      await tester.enterText(amountField, '50'); // ต่ำกว่า 100
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ปุ่มควร disabled (onPressed == null)
      final nextBtnWidget =
          tester.widget<ElevatedButton>(find.byKey(const Key('btn_next_step')));
      expect(nextBtnWidget.onPressed, isNull,
          reason: 'ปุ่มควร disabled เมื่อกรอกน้อยกว่า 100 บาท');
    });
  });
}
