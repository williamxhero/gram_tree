import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> revealLazyListControl(
  WidgetTester tester,
  Finder target, {
  required Finder scrollable,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  if (tester.testTextInput.isRegistered) tester.testTextInput.hide();
  await tester.pump();
  for (var i = 0; i < 12 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(scrollable, const Offset(0, 500));
    await tester.pump(const Duration(milliseconds: 100));
  }
  for (var i = 0; i < 45 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(scrollable, const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(target.last.hitTestable(), findsOneWidget);
}
