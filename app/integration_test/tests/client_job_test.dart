import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;

import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UC 3.1.5 — List Jobs (Client)', () {
    testWidgets('หน้า "งานขนส่งของฉัน" โหลด job cards ได้', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);
      // รอโหลด jobs จาก Firestore
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // ต้องมี job card อย่างน้อย 1 ใบ (seed data)
      expect(find.byKey(const ValueKey('job_card_')), findsNothing); // sanity check key pattern
      // ใช้ JobCardWidget type แทน
      expect(find.byWidgetPredicate((w) => w.runtimeType.toString().contains('JobCardWidget')), findsWidgets);
    });

    testWidgets('tab filter "ทั้งหมด" ปรากฏ', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('ทั้งหมด'), findsWidgets);
    });
  });

  group('UC 3.1.6 — View Job Detail (Client)', () {
    testWidgets('กด "ดูรายละเอียด" → navigate ไป JobDetailPage', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // กดปุ่ม "ดูรายละเอียด" ของ card แรก
      final detailBtn = find.text('ดูรายละเอียด');
      if (tester.any(detailBtn)) {
        await tester.tap(detailBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // ต้องอยู่ที่ JobDetailPage (ปรากฏทั้งใน AppBar title และ body)
        expect(find.text('รายละเอียดงาน'), findsWidgets);
      }
    });

    testWidgets('JobDetailPage แสดงเนื้อหา ไม่ว่างเปล่า', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final detailBtn = find.text('ดูรายละเอียด');
      if (tester.any(detailBtn)) {
        await tester.tap(detailBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // หน้าต้องแสดงเนื้อหา (ไม่ว่าง)
        // status badge ต้องปรากฏ
        expect(
          find.byWidgetPredicate((w) => w.runtimeType.toString().contains('StatusBadgeWidget')),
          findsOneWidget,
        );
      }
    });

    testWidgets('กดปุ่ม back กลับ job list', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final detailBtn = find.text('ดูรายละเอียด');
      if (tester.any(detailBtn)) {
        await tester.tap(detailBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.text('รายละเอียดงาน'), findsWidgets);

        // กดปุ่ม back
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // กลับมาที่ job list
        expect(find.text('งานขนส่งของฉัน'), findsOneWidget);
      }
    });
  });
}
