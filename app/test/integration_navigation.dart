import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/features/me/settings_page.dart';

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

Future<void> tapPortabilitySettingsItem(
  WidgetTester tester,
  String text,
) async {
  // Phone viewports do not build distant settings entries until we scroll.
  // Use the settings list, not a scrollable retained by an underlying route.
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.descendant(
      of: find.byType(SettingsPage),
      matching: find.byType(Scrollable),
    ),
  );
  await tapText(tester, text);
}
