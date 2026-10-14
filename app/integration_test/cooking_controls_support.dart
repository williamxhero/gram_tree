import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> revealCookingControl(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  if (tester.testTextInput.isRegistered) tester.testTextInput.hide();
  final scrollable = find
      .descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      )
      .first;
  // Safety composition can grow after navigation. Re-evaluate visible controls
  // after each gesture instead of ensureVisible on a child that may be unmounted.
  for (var i = 0; i < 12 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(scrollable, const Offset(0, 500));
    await tester.pump(const Duration(milliseconds: 100));
  }
  for (var i = 0; i < 45 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(scrollable, const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(target.hitTestable(), findsOneWidget);
}
