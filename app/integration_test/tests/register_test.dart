// UC 3.1.2 — Register Client
// UC 3.1.17 — Register Contractor
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UC 3.1.2 — Register Client', () {
    testWidgets('กด "ลงทะเบียน" → เห็นหน้าเลือก role', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('ลงทะเบียน'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('คุณต้องการใช้งานเป็น'), findsOneWidget);
    });

    testWidgets('เลือก "เกษตรกร" → เห็น role card selected', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('ลงทะเบียน'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('เกษตรกร'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('เกษตรกร'), findsOneWidget);
      expect(find.text('ถัดไป'), findsOneWidget);
    });

    testWidgets('กด "ถัดไป" → navigate ไปหน้า PhoneInput (register client)', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('ลงทะเบียน'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // เลือก client (default)
      await tester.tap(find.text('ถัดไป'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ต้องเห็นหน้ากรอกเบอร์โทร
      expect(find.text('กรอกหมายเลขโทรศัพท์'), findsOneWidget);
    });
  });

  group('UC 3.1.17 — Register Contractor', () {
    testWidgets('เลือก "ผู้รับจ้าง" → กด "ถัดไป" → PhoneInput register contractor', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('ลงทะเบียน'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('ผู้รับจ้าง (Contractor)'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('ถัดไป'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // PhoneInput register contractor — AppBar ต้องแสดง role
      expect(find.text('กรอกหมายเลขโทรศัพท์'), findsOneWidget);
    });
  });
}
