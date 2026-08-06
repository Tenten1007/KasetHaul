import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app/main.dart' as app;

import '../helpers/app_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UC 3.1.1 — Login Client', () {
    testWidgets('login client สำเร็จ → เห็นหน้า "งานขนส่งของฉัน"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);

      expect(find.text('งานขนส่งของฉัน'), findsOneWidget);
    });

    testWidgets('login client → bottom nav ครบ 4 ปุ่ม', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsClient(tester);

      expect(find.text('งานของฉัน'), findsWidgets);
      expect(find.text('กระเป๋าเงิน'), findsWidgets);
      expect(find.text('โปรไฟล์'), findsWidgets);
    });
  });

  group('UC 3.1.16 — Login Contractor', () {
    testWidgets('login contractor สำเร็จ → เห็น "ค้นหางาน"', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      expect(find.text('ค้นหางาน'), findsWidgets);
    });

    testWidgets('login contractor → bottom nav ครบ 4 แท็บ', (tester) async {
      await app.initializeApp();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await loginAsContractor(tester);

      expect(find.text('ค้นหางาน'), findsWidgets);
      expect(find.text('งานของฉัน'), findsWidgets);
      expect(find.text('โปรไฟล์'), findsWidgets);
    });
  });
}
