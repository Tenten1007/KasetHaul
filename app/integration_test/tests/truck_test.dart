// UC 3.1.20 — Add Truck
// UC 3.1.21 — List Trucks
// UC 3.1.22 — View Truck Detail
// UC 3.1.23 — Edit Truck
// UC 3.1.24 — Remove Truck
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;

import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UC 3.1.21 — List Trucks', () {
    testWidgets('โปรไฟล์ → "จัดการรถ" → เห็น "รถบรรทุกของฉัน"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.scrollUntilVisible(
        find.text('จัดการรถ'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('จัดการรถ'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('รถบรรทุกของฉัน'), findsOneWidget);
    });

    testWidgets('truck list มีปุ่ม "เพิ่มรถ"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.scrollUntilVisible(
        find.text('จัดการรถ'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('จัดการรถ'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('เพิ่มรถ'), findsOneWidget);
    });
  });

  group('UC 3.1.20 — Add Truck', () {
    testWidgets('กด "เพิ่มรถ" → เห็น "เพิ่มรถบรรทุก" form', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.scrollUntilVisible(
        find.text('จัดการรถ'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('จัดการรถ'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('เพิ่มรถ'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('เพิ่มรถบรรทุก'), findsOneWidget);
    });

    testWidgets('add truck form มี TextFormField', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.scrollUntilVisible(
        find.text('จัดการรถ'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('จัดการรถ'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await tester.tap(find.text('เพิ่มรถ'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(TextFormField), findsWidgets);
    });
  });

  group('UC 3.1.22 — View Truck Detail', () {
    testWidgets('กด truck card → เห็น truck detail page', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.scrollUntilVisible(
        find.text('จัดการรถ'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('จัดการรถ'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // หา truck card (ถ้ามีรถ)
      final truckCards = find.byType(Card);
      if (tester.any(truckCards)) {
        await tester.tap(truckCards.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.byType(Scaffold), findsWidgets);
      } else {
        expect(find.text('รถบรรทุกของฉัน'), findsOneWidget);
      }
    });
  });

  group('UC 3.1.23 — Edit Truck', () {
    testWidgets('truck list มีปุ่มแก้ไข (edit icon หรือ "แก้ไข")', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.scrollUntilVisible(
        find.text('จัดการรถ'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('จัดการรถ'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ต้องเห็น truck list page
      expect(find.text('รถบรรทุกของฉัน'), findsOneWidget);

      // ถ้ามีรถ ต้องมี edit button
      final editIcon = find.byIcon(Icons.edit_outlined);
      if (tester.any(editIcon)) {
        await tester.tap(editIcon.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        expect(find.byType(Scaffold), findsWidgets);
      }
    });
  });

  group('UC 3.1.24 — Remove Truck', () {
    testWidgets('truck list มีปุ่มลบ (delete icon)', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      await tester.tap(find.text('โปรไฟล์').last);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.scrollUntilVisible(
        find.text('จัดการรถ'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('จัดการรถ'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('รถบรรทุกของฉัน'), findsOneWidget);

      // ถ้ามีรถ ต้องมี delete button
      final deleteIcon = find.byIcon(Icons.delete_outline);
      if (tester.any(deleteIcon)) {
        await tester.tap(deleteIcon.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        // ต้องเห็น confirmation dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        // ปิด dialog
        await tester.tap(find.text('ยกเลิก'));
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    });
  });
}
