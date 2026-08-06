// E2E — UC 3.1.4 Post Job: กรอก form ครบ 4 ขั้นตอน → โพสต์งานจริง
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;

import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E UC 3.1.4 — Post Job (full form fill)', () {
    testWidgets('กรอก form ครบ 4 steps → โพสต์งานสำเร็จ', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ─── Navigate to Post Job tab ───
      final postJobTab = find.text('โพสต์งาน');
      if (!tester.any(postJobTab)) {
        // Try bottom nav icon
        await tester.tap(find.byIcon(Icons.add_circle_outline));
      } else {
        await tester.tap(postJobTab.first);
      }
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ─── STEP 1: ข้อมูลสินค้า ───
      expect(find.text('ข้อมูลสินค้า'), findsWidgets);

      // ชื่องาน
      await tester.enterText(
          find.byKey(const Key('field_job_title')), 'ขนส่งผักสด E2E Test');
      await tester.pumpAndSettle();

      // ประเภทสินค้า dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('ผักสด').last);
      await tester.pumpAndSettle();

      // น้ำหนัก
      await tester.enterText(find.byKey(const Key('field_weight')), '1000');
      await tester.pumpAndSettle();

      // ประเภทรถ dropdown (load จาก Firestore) — รอสักครู่แล้วลองเลือก
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ประเภทรถ — รอ Firestore โหลด truck types
      // post_job_page.dart auto-select ตัวแรกใน kDebugMode ทันทีที่โหลดเสร็จ
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // กด ถัดไป (Step 0 → Step 1)
      await tester.ensureVisible(find.byKey(const Key('btn_step1_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_step1_next')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ─── STEP 1: สถานที่รับ-ส่ง ───
      expect(tester.any(find.textContaining('สถานที่')), isTrue,
          reason: 'ควรอยู่ step 1 สถานที่รับ-ส่ง');

      await tester.enterText(
          find.byKey(const Key('field_pickup_address')), '123 ถนนทดสอบ เชียงใหม่');
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('field_dropoff_address')), '456 ถนนทดสอบ เชียงราย');
      await tester.pumpAndSettle();

      // กด ถัดไป (Step 1 → Step 2) — scroll ลงก่อนเพราะปุ่มอาจอยู่นอกหน้าจอ
      await tester.ensureVisible(find.byKey(const Key('btn_step2_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_step2_next')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ─── STEP 3: กำหนดการและราคา ───
      expect(find.text('กำหนดการและราคา'), findsWidgets);

      // เลือกวันที่รับ (Date Picker)
      await tester.tap(find.text('เลือกวันที่').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // ตกลง/OK บน date picker dialog
      final okDateBtn = find.text('OK');
      final okDateBtnTh = find.text('ตกลง');
      if (tester.any(okDateBtn)) {
        await tester.tap(okDateBtn.first);
      } else if (tester.any(okDateBtnTh)) {
        await tester.tap(okDateBtnTh.first);
      }
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // เลือกเวลารับ (Time Picker)
      await tester.tap(find.text('เลือกเวลา').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      final okTimeBtn = find.text('OK');
      final okTimeBtnTh = find.text('ตกลง');
      if (tester.any(okTimeBtn)) {
        await tester.tap(okTimeBtn.first);
      } else if (tester.any(okTimeBtnTh)) {
        await tester.tap(okTimeBtnTh.first);
      }
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // เลือกวันที่ส่ง (Date Picker)
      final remainingDateTile = find.text('เลือกวันที่');
      if (tester.any(remainingDateTile)) {
        await tester.tap(remainingDateTile.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        if (tester.any(okDateBtn)) {
          await tester.tap(okDateBtn.first);
        } else if (tester.any(okDateBtnTh)) {
          await tester.tap(okDateBtnTh.first);
        }
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // เลือกเวลาส่ง (Time Picker)
      final remainingTimeTile = find.text('เลือกเวลา');
      if (tester.any(remainingTimeTile)) {
        await tester.tap(remainingTimeTile.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        if (tester.any(okTimeBtn)) {
          await tester.tap(okTimeBtn.first);
        } else if (tester.any(okTimeBtnTh)) {
          await tester.tap(okTimeBtnTh.first);
        }
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // งบประมาณ
      await tester.enterText(find.byKey(const Key('field_budget')), '5000');
      await tester.pumpAndSettle();

      // กด "ตรวจสอบและโพสต์" — ensureVisible เพราะอาจนอกหน้าจอ
      await tester.ensureVisible(find.byKey(const Key('btn_step3_next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_step3_next')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ─── STEP 4: ยืนยัน ───
      await tester.ensureVisible(find.byKey(const Key('btn_post_job')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_post_job')));
      await waitForWidget(tester, find.text('โพสต์งานสำเร็จ!'),
          timeout: const Duration(seconds: 20));

      expect(find.text('โพสต์งานสำเร็จ!'), findsOneWidget);
    });
  });
}
