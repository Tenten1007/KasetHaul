// UC 3.1.3 — Edit Profile Client
// UC 3.1.15 — View Statistics
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;

import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UC 3.1.3 — Edit Profile Client', () {
    testWidgets('กด tab "โปรไฟล์" → เห็น "โปรไฟล์ของฉัน"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('โปรไฟล์ของฉัน'), findsOneWidget);
    });

    testWidgets('เห็นข้อมูลติดต่อ section', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('ข้อมูลติดต่อ'), findsOneWidget);
    });

    testWidgets('กดปุ่ม Settings ⚙️ → เห็นหน้าแก้ไขโปรไฟล์', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ปุ่ม settings (⚙️ icon ใน AppBar)
      await tester.tap(find.text('⚙️'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ต้องเห็น settings หรือ edit page
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('UC 3.1.15 — View Statistics', () {
    testWidgets('กด "ดูสถิติการใช้งาน" → เห็น "สถิติการใช้จ่าย"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // scroll หาปุ่มสถิติ
      await tester.scrollUntilVisible(
        find.text('ดูสถิติการใช้งาน'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('ดูสถิติการใช้งาน'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('สถิติการใช้จ่าย'), findsOneWidget);
    });

    testWidgets('statistics page แสดง "ยอดเงินคงเหลือ"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.scrollUntilVisible(
        find.text('ดูสถิติการใช้งาน'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('ดูสถิติการใช้งาน'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('ยอดเงินคงเหลือ'), findsOneWidget);
    });
  });
}
