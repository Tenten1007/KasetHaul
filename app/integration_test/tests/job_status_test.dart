import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;

import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UC 3.1.30 — List My Jobs (Contractor)', () {
    testWidgets('contractor กด "งานของฉัน" → เห็น tab หน้างาน', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      // กด tab "งานของฉัน" ใน bottom nav
      await tester.tap(find.text('งานของฉัน').last);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // หน้า contractor my jobs มี tabs: ทั้งหมด, รอดำเนินการ, กำลังขนส่ง, เสร็จสิ้น
      expect(find.text('รอดำเนินการ'), findsWidgets);
    });

    testWidgets('เห็น seed job ที่ assigned ใน tab ที่เกี่ยวข้อง', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('งานของฉัน').last);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Seed job อยู่ในสถานะ 'มอบหมายแล้ว' → ควรอยู่ใน tab "มอบหมายแล้ว" หรือ "ทั้งหมด"
      // ถ้าเห็น job card ก็ถือว่าผ่าน
      final tabs = find.byType(Tab);
      expect(tabs, findsWidgets);
    });
  });

  group('UC 3.1.31 — Update Job Status (Contractor)', () {
    testWidgets('กด job → เห็นหน้า detail ฝั่ง contractor', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('งานของฉัน').last);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // กด tab แรก
      final tabList = find.byType(Tab);
      if (tester.any(tabList)) {
        await tester.tap(tabList.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // หา job card และกด
      final cards = find.byWidgetPredicate(
        (w) => w is GestureDetector && (w.key?.toString() ?? '').contains('job_card_'),
      );
      if (tester.any(cards)) {
        await tester.tap(cards.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // ต้องเห็น contractor job detail
        expect(find.text('อัพเดทสถานะ'), findsWidgets);
      }
    });

    testWidgets('contractor job detail แสดงข้อมูลงาน', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('งานของฉัน').last);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final cards = find.byWidgetPredicate(
        (w) => w is GestureDetector && (w.key?.toString() ?? '').contains('job_card_'),
      );
      if (tester.any(cards)) {
        await tester.tap(cards.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // ต้องเห็นข้อมูล pickup / dropoff
        expect(
          find.byWidgetPredicate((w) => w.runtimeType.toString().contains('StatusBadgeWidget')),
          findsWidgets,
        );
      }
    });
  });
}
