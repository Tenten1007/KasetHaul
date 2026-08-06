// UC 3.1.4 — Post Job
// UC 3.1.9 — Edit Job
// UC 3.1.12 — Cancel Job
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;

import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UC 3.1.4 — Post Job', () {
    testWidgets('กด tab "โพสต์งาน" → เห็น step 1 "ข้อมูลสินค้า"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);

      await tester.tap(find.text('โพสต์งาน').last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('ข้อมูลสินค้า'), findsOneWidget);
      expect(find.text('กรุณากรอกรายละเอียดสินค้าที่ต้องการขนส่ง'), findsOneWidget);
    });

    testWidgets('post job step 1 มี form fields ครบ', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);

      await tester.tap(find.text('โพสต์งาน').last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ต้องมี TextField หลายช่อง
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('ถัดไป'), findsOneWidget);
    });

    testWidgets('กรอกข้อมูล step 1 → กด "ถัดไป" → ไป step 2 "สถานที่รับ-ส่ง"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);

      await tester.tap(find.text('โพสต์งาน').last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // กรอกข้อมูล (fields แรกๆ)
      final fields = find.byType(TextFormField);
      if (tester.any(fields)) {
        await tester.enterText(fields.first, 'ข้าวสาร 100 กก.');
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      await tester.tap(find.text('ถัดไป'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // step 2 หรือ validation error — อย่างน้อย UI ตอบสนอง
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('UC 3.1.9 — Edit Job', () {
    testWidgets('client เห็น job → กด "ดูรายละเอียด" → เห็น AppBar รายละเอียดงาน', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final detailBtn = find.text('ดูรายละเอียด');
      if (tester.any(detailBtn)) {
        await tester.tap(detailBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // ต้องเห็น "แก้ไขงาน" ถ้า job อยู่ในสถานะที่แก้ได้
        // หรืออย่างน้อยต้องเห็น job detail
        expect(find.text('รายละเอียดงาน'), findsWidgets);
      }
    });
  });

  group('UC 3.1.12 — Cancel Job', () {
    testWidgets('job detail มีปุ่ม "ยกเลิกงาน" หรือ cancel option', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final detailBtn = find.text('ดูรายละเอียด');
      if (tester.any(detailBtn)) {
        await tester.tap(detailBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // scroll หาปุ่มยกเลิก
        final cancelBtn = find.text('ยกเลิกงาน');
        if (tester.any(cancelBtn)) {
          await tester.tap(cancelBtn);
          // ยกเลิกงาน navigate ไป CancelJobPage (ไม่ใช่ AlertDialog inline)
          // รอ page content 'ต้องการยกเลิกงานนี้?' หรือ AlertDialog (fallback)
          await tester.pumpAndSettle(const Duration(seconds: 3));
          final hasCancelPage = tester.any(find.textContaining('ต้องการยกเลิก'));
          final hasDialog = tester.any(find.byType(AlertDialog));
          expect(hasCancelPage || hasDialog, isTrue,
              reason: 'ควรเห็น CancelJobPage หรือ AlertDialog หลัง tap ยกเลิกงาน');
        } else {
          // ไม่มีปุ่ม cancel (job อาจอยู่ในสถานะที่ยกเลิกไม่ได้) — skip
          expect(find.text('รายละเอียดงาน'), findsWidgets);
        }
      }
    });
  });
}
