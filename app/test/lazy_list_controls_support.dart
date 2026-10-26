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
  bool isHitTestable(Finder finder) {
    try {
      return finder.hitTestable().evaluate().isNotEmpty;
    } on StateError {
      // A caller may pass `.first` while the route is still being built. The
      // first-finder itself throws before it can report an empty result.
      return false;
    }
  }

  Future<void> search(Offset offset, int attempts) async {
    for (var i = 0; i < attempts; i++) {
      if (isHitTestable(target)) return;
      // Route changes and asynchronous composition can briefly leave the
      // caller's scrollable finder empty. Wait for it instead of letting
      // WidgetController.drag call `.first` on an empty finder.
      if (isHitTestable(scrollable)) {
        await tester.drag(scrollable, offset);
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  await search(const Offset(0, 500), 12);
  await search(const Offset(0, -200), 45);
  expect(
    target.hitTestable(),
    findsOneWidget,
    reason: 'Timed out revealing lazy control $target',
  );
}
