import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;

import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UC 3.1.25 — Search Jobs (Contractor)', () {
    testWidgets('contractor เห็นหน้า "ค้นหางาน" หลัง login', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // หน้า SearchJobsPage ต้องเป็น default
      expect(find.text('ค้นหางาน'), findsWidgets);
    });

    testWidgets('search field ปรากฏและรับ input ได้', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ค้นหา search field
      final searchField = find.byKey(const Key('search_field'));
      expect(searchField, findsOneWidget);

      // กรอกข้อความ
      await tester.enterText(searchField, 'ข้าว');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // verify input
      expect(find.text('ข้าว'), findsOneWidget);
    });

    testWidgets('search hint text ปรากฏ', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('ค้นหางาน, สินค้า, สถานที่...'), findsOneWidget);
    });
  });

  group('UC 3.1.26 — View Job Detail (Contractor)', () {
    testWidgets('contractor กด job card → เห็น detail page', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // หา job card ฝั่ง contractor (มีปุ่ม "ดูรายละเอียด" หรือ card ที่ tap ได้)
      final jobCards = find.byWidgetPredicate(
        (w) => w is GestureDetector && (w.key?.toString() ?? '').contains('job_card_'),
      );

      if (tester.any(jobCards)) {
        await tester.tap(jobCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        // ต้องเห็น detail page
        expect(find.text('รายละเอียดงาน'), findsOneWidget);
      }
    });
  });
}
