import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test account constants
const kClientPhone = '0894561232';
const kContractorPhone = '0891234567';

/// รอ widget ปรากฏโดย pump ซ้ำทุก 500ms จนครบ timeout
Future<void> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 500));
    if (tester.any(finder)) return;
  }
  throw TestFailure('Widget not found within ${timeout.inSeconds}s: $finder');
}

/// Login เป็น Client ผ่าน debug buttons
/// ต้องเริ่มที่หน้า RoleSelectPage (มีปุ่ม "เข้าสู่ระบบ")
Future<void> loginAsClient(WidgetTester tester) async {
  // กด "เข้าสู่ระบบ" บน RoleSelectPage
  await tester.tap(find.text('เข้าสู่ระบบ').first);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // PhoneInputPage: กดปุ่ม debug client
  await tester.tap(find.byKey(const Key('debug_pick_client')));
  await tester.pumpAndSettle(const Duration(seconds: 1));

  // กดส่ง OTP
  await tester.tap(find.byKey(const Key('btn_send_otp')));
  // รอ OTP sent state (Firebase signIn call)
  await waitForWidget(tester, find.byKey(const Key('btn_fill_test_otp')),
      timeout: const Duration(seconds: 40));

  // OtpVerifyPage: กดปุ่ม debug fill + submit 123456
  await tester.tap(find.byKey(const Key('btn_fill_test_otp')));
  await tester.pump(const Duration(milliseconds: 500));

  // รอ Firebase Auth verify + Firestore lookup + navigate → ClientHomePage
  await waitForWidget(tester, find.text('งานขนส่งของฉัน'),
      timeout: const Duration(seconds: 60));
  expect(find.text('งานขนส่งของฉัน'), findsOneWidget);
}

/// Login เป็น Contractor ผ่าน debug buttons
Future<void> loginAsContractor(WidgetTester tester) async {
  await tester.tap(find.text('เข้าสู่ระบบ').first);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  await tester.tap(find.byKey(const Key('debug_pick_contractor')));
  await tester.pumpAndSettle(const Duration(seconds: 1));

  await tester.tap(find.byKey(const Key('btn_send_otp')));
  await waitForWidget(tester, find.byKey(const Key('btn_fill_test_otp')),
      timeout: const Duration(seconds: 40));

  await tester.tap(find.byKey(const Key('btn_fill_test_otp')));
  await tester.pump(const Duration(milliseconds: 500));

  // รอ navigate → ContractorHomePage (เพิ่ม timeout สำหรับ slow emulator)
  await waitForWidget(tester, find.text('ค้นหางาน'),
      timeout: const Duration(seconds: 90));
  expect(find.text('ค้นหางาน'), findsWidgets);
}

/// Logout จาก client home — กด "โปรไฟล์" → scroll หาปุ่ม "ออกจากระบบ"
Future<void> logoutFromClientHome(WidgetTester tester) async {
  await tester.tap(find.text('โปรไฟล์').last);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  await tester.scrollUntilVisible(
    find.text('ออกจากระบบ'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('ออกจากระบบ'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  final confirmBtn = find.text('ออกจากระบบ').last;
  if (tester.any(confirmBtn)) {
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

/// Logout จาก contractor home
Future<void> logoutFromContractorHome(WidgetTester tester) async {
  await tester.tap(find.text('โปรไฟล์').last);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  await tester.scrollUntilVisible(
    find.text('ออกจากระบบ'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('ออกจากระบบ'));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  final confirmBtn = find.text('ออกจากระบบ').last;
  if (tester.any(confirmBtn)) {
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
