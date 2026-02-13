// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:class_timer/main.dart';

void main() {
  testWidgets('Onboarding screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ClassTimerPro(initialRoute: '/'));

    // Verify that onboarding starts with the first page.
    expect(find.text('Import Effortlessly'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
  });
}
