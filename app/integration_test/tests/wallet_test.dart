import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;

import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UC 3.1.14 — Wallet & Deposit', () {
    testWidgets('กด tab "กระเป๋าเงิน" → เห็น wallet page', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);

      await tester.tap(find.text('กระเป๋าเงิน').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // AppBar title "กระเป๋าเงิน"
      expect(find.text('กระเป๋าเงิน'), findsWidgets);
    });

    testWidgets('wallet page แสดง "ยอดที่ใช้ได้"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);

      await tester.tap(find.text('กระเป๋าเงิน').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('ยอดที่ใช้ได้'), findsOneWidget);
    });

    testWidgets('กดปุ่ม "+ เติมเงิน" → navigate ไป TopUpPage', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);

      await tester.tap(find.text('กระเป๋าเงิน').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // กดปุ่มเติมเงิน
      await tester.tap(find.text('+ เติมเงิน'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ต้องเห็นหน้าเติมเงิน
      expect(find.text('เติมเงิน'), findsWidgets);
      expect(find.text('ระบุจำนวนเงินที่ต้องการเติม'), findsOneWidget);
    });

    testWidgets('top-up page: กรอกจำนวนเงิน → ปุ่ม "ดำเนินการเติมเงิน" active', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);

      await tester.tap(find.text('กระเป๋าเงิน').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.tap(find.text('+ เติมเงิน'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // กรอกจำนวนเงิน 500
      await tester.enterText(find.byKey(const Key('field_amount')), '500');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ปุ่ม "ดำเนินการเติมเงิน" ต้องปรากฏ
      expect(find.text('ดำเนินการเติมเงิน'), findsOneWidget);

      // กดปุ่ม next
      await tester.tap(find.byKey(const Key('btn_next_step')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 2: เห็นเลขบัญชีธนาคาร
      expect(find.text('ธนาคารกสิกรไทย'), findsOneWidget);
    });
  });
}
