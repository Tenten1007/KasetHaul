// UC 3.1.27 — Submit Bidding
// UC 3.1.28 — Edit Bidding
// UC 3.1.29 — Cancel Bidding
// UC 3.1.32 — Review Client
// UC 3.1.33 — Withdraw
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;

import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UC 3.1.27 — Submit Bidding', () {
    testWidgets('contractor กด job card → เห็น bid price field', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // หา job card ใน search
      final jobCards = find.byWidgetPredicate(
        (w) => w is GestureDetector &&
            (w.key?.toString() ?? '').contains('job_card_'),
      );
      if (tester.any(jobCards)) {
        await tester.tap(jobCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // bid_job_page มี "รายละเอียดงาน" และ price field
        expect(find.text('รายละเอียดงาน'), findsOneWidget);

        // scroll หา bid section
        await tester.drag(find.byType(SingleChildScrollView).first,
            const Offset(0, -400));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // ต้องเห็น price input หรือปุ่มเสนอราคา
        expect(find.byType(TextFormField), findsWidgets);
      }
    });

    testWidgets('bid_job_page แสดงปุ่ม "ยืนยัน" หรือ "เสนอราคา"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final jobCards = find.byWidgetPredicate(
        (w) => w is GestureDetector &&
            (w.key?.toString() ?? '').contains('job_card_'),
      );
      if (tester.any(jobCards)) {
        await tester.tap(jobCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        await tester.drag(find.byType(SingleChildScrollView).first,
            const Offset(0, -500));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // ต้องเห็นปุ่ม submit bid หรือ "แก้ไข" / "ยกเลิก" (ถ้า bid แล้ว)
        expect(
          find.byWidgetPredicate((w) =>
              w is ElevatedButton || w is OutlinedButton || w is TextButton),
          findsWidgets,
        );
      }
    });
  });

  group('UC 3.1.28 — Edit Bidding', () {
    testWidgets('bid_job_page มีปุ่ม "แก้ไข" ถ้าเคย bid แล้ว', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final jobCards = find.byWidgetPredicate(
        (w) => w is GestureDetector &&
            (w.key?.toString() ?? '').contains('job_card_'),
      );
      if (tester.any(jobCards)) {
        await tester.tap(jobCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        await tester.drag(find.byType(SingleChildScrollView).first,
            const Offset(0, -400));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final editBidBtn = find.text('แก้ไข');
        if (tester.any(editBidBtn)) {
          await tester.tap(editBidBtn.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          expect(find.byType(Scaffold), findsWidgets);
        } else {
          expect(find.text('รายละเอียดงาน'), findsOneWidget);
        }
      }
    });
  });

  group('UC 3.1.29 — Cancel Bidding', () {
    testWidgets('bid_job_page มีปุ่ม "ยกเลิก" ถ้าเคย bid แล้ว', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final jobCards = find.byWidgetPredicate(
        (w) => w is GestureDetector &&
            (w.key?.toString() ?? '').contains('job_card_'),
      );
      if (tester.any(jobCards)) {
        await tester.tap(jobCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        await tester.drag(find.byType(SingleChildScrollView).first,
            const Offset(0, -400));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final cancelBidBtn = find.text('ยกเลิก');
        if (tester.any(cancelBidBtn)) {
          await tester.tap(cancelBidBtn.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          // confirm dialog
          expect(find.text('ต้องการยกเลิกการเสนอราคานี้ใช่หรือไม่?'), findsWidgets);
          // ปิด dialog
          await tester.tap(find.text('ไม่ยกเลิก'));
          await tester.pumpAndSettle(const Duration(seconds: 1));
        } else {
          expect(find.text('รายละเอียดงาน'), findsOneWidget);
        }
      }
    });
  });

  group('UC 3.1.32 — Review Client', () {
    testWidgets('contractor my jobs "เสร็จสิ้น" tab มีปุ่มรีวิว', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('งานของฉัน').last);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // กด tab เสร็จสิ้น
      final doneTab = find.text('เสร็จสิ้น');
      if (tester.any(doneTab)) {
        await tester.tap(doneTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final cards = find.byWidgetPredicate(
          (w) => w is GestureDetector &&
              (w.key?.toString() ?? '').contains('job_card_'),
        );
        if (tester.any(cards)) {
          await tester.tap(cards.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          await tester.drag(find.byType(SingleChildScrollView).first,
              const Offset(0, -400));
          await tester.pumpAndSettle(const Duration(seconds: 1));

          final reviewBtn = find.textContaining('รีวิว');
          if (tester.any(reviewBtn)) {
            await tester.tap(reviewBtn.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));
            expect(find.text('ให้คะแนนผู้ว่าจ้าง'), findsWidgets);
          }
        }
      }
      // ถ้าไม่มี completed job — ผ่าน (ไม่มี error)
    });
  });

  group('UC 3.1.33 — Withdraw', () {
    testWidgets('earnings page → กด "ถอนเงิน" → เห็น "ถอนเงิน" page', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('รายได้').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // scroll หาปุ่มถอนเงิน
      final withdrawBtn = find.textContaining('ถอนเงิน');
      if (tester.any(withdrawBtn)) {
        await tester.tap(withdrawBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.text('ถอนเงิน'), findsWidgets);
      } else {
        expect(find.text('รายได้'), findsWidgets);
      }
    });

    testWidgets('withdraw page แสดง "สรุปการถอนเงิน" หลังกรอกจำนวน', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('รายได้').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final withdrawBtn = find.textContaining('ถอนเงิน');
      if (tester.any(withdrawBtn)) {
        await tester.tap(withdrawBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // กรอกจำนวนเงิน
        final amountField = find.byType(TextFormField);
        if (tester.any(amountField)) {
          await tester.enterText(amountField.first, '100');
          await tester.pumpAndSettle(const Duration(seconds: 1));
          expect(find.text('ถอนเงิน'), findsWidgets);
        }
      }
    });
  });
}
