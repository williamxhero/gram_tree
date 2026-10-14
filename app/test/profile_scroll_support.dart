import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> revealProfileTarget(
  WidgetTester tester,
  Finder finder, {
  double delta = 300,
}) async {
  final scrollables = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
  final profile = find.byKey(const ValueKey('taste-profile-content'));
  final profileScrollables = find.descendant(
    of: profile,
    matching: scrollables,
  );
  ScrollPosition? currentPosition() {
    final candidates = profileScrollables.evaluate().isNotEmpty
        ? profileScrollables
        : scrollables;
    if (candidates.evaluate().isEmpty) return null;
    return tester.state<ScrollableState>(candidates.first).position;
  }

  for (var i = 0; i < 300 && currentPosition() == null; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(currentPosition(), isNotNull);
  final step = delta.abs().clamp(100.0, 500.0).toDouble();
  // Reset each search, but never retain a position across a pump: saving can
  // replace the entire profile list while its asynchronous refresh completes.
  currentPosition()!.jumpTo(currentPosition()!.minScrollExtent);
  await tester.pumpAndSettle();
  for (var i = 0; i < 300; i++) {
    if (finder.evaluate().isNotEmpty) {
      await Scrollable.ensureVisible(
        tester.element(finder),
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
      await tester.pumpAndSettle();
      if (finder.hitTestable().evaluate().isNotEmpty) break;
    } else {
      final position = currentPosition();
      // A refresh may briefly render no list at all. The next frame must
      // resolve its replacement rather than touching a disposed position.
      if (position != null) {
        position.jumpTo(
          (position.pixels + step).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  expect(finder, findsOneWidget);
  expect(finder.hitTestable(), findsOneWidget);
}
