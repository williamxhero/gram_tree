import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/features/me/settings_page.dart';

import 'lazy_list_controls_support.dart';

// Shared with installed integration tests; kept under test/ so Chrome page
// tests can exercise the same navigation without imports outside their root.
Future<void> settle(WidgetTester tester) =>
    tester.pumpAndSettle(const Duration(milliseconds: 200));

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await settle(tester);
  await tester.tap(find.text(text).last);
  await settle(tester);
}

Future<void> revealConstraintsTestControl(
  WidgetTester tester,
  Finder finder,
) async {
  // A save can replace the profile list with a loading indicator. Reacquire the
  // active route's list with bounded gestures instead of reading an empty first.
  final dialog = find.byType(AlertDialog);
  final surface = dialog.evaluate().isEmpty
      ? find.byType(Scaffold).last
      : dialog.last;
  await revealLazyListControl(
    tester,
    find.descendant(of: surface, matching: finder),
    scrollable: find
        .descendant(
          of: surface,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          ),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> tapPortabilitySettingsItem(
  WidgetTester tester,
  String text,
) async {
  // A built entry can still sit behind an asynchronous export SnackBar. Discover
  // an actually tappable entry with bounded gestures in this route's lazy list.
  final target = find.descendant(
    of: find.byType(SettingsPage),
    matching: find.text(text),
  );
  await revealLazyListControl(
    tester,
    target,
    scrollable: find.descendant(
      of: find.byType(SettingsPage),
      matching: find.byType(Scrollable),
    ),
  );
  await tester.tap(target.hitTestable());
  await settle(tester);
}
