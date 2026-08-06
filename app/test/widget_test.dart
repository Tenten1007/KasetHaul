import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('KasetHaul app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KasetHaulApp());
    expect(find.text('KasetHaul'), findsWidgets);
  });
}
