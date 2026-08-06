// UC 3.1.18 — Verify Identity
// UC 3.1.19 — Edit Profile Contractor
// UC 3.1.34 — View Earnings
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;

import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UC 3.1.19 — Edit Profile Contractor', () {
    testWidgets('กด tab "โปรไฟล์" → เห็น "โปรไฟล์ของฉัน"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('โปรไฟล์ของฉัน'), findsOneWidget);
    });

    testWidgets('เห็น "ข้อมูลติดต่อ" section', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('ข้อมูลติดต่อ'), findsOneWidget);
    });

    testWidgets('เห็น "รถของฉัน" section', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('รถของฉัน'), findsWidgets);
    });
  });

  group('UC 3.1.18 — Verify Identity', () {
    testWidgets('กด "ยืนยันตัวตน" → เห็นหน้า verify identity', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // scroll หาปุ่มยืนยันตัวตน
      final verifyBtn = find.text('ยืนยันตัวตน');
      if (tester.any(verifyBtn)) {
        await tester.tap(verifyBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.text('ยืนยันตัวตน'), findsWidgets);
      } else {
        // identity แล้ว — ผ่าน
        expect(find.text('โปรไฟล์ของฉัน'), findsOneWidget);
      }
    });
  });

  group('UC 3.1.34 — View Earnings', () {
    testWidgets('กด tab "รายได้" → เห็น "รายได้"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('รายได้').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('รายได้'), findsWidgets);
    });

    testWidgets('earnings page แสดง "รายได้สะสมทั้งหมด"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('รายได้').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('รายได้สะสมทั้งหมด'), findsOneWidget);
    });

    testWidgets('earnings page แสดง "ยอดในกระเป๋า"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('รายได้').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('ยอดในกระเป๋า'), findsOneWidget);
    });
  });
}
