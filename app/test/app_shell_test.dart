import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Page tests for the app shell. They only look at what is on screen and what
/// happens after a tap.

void main() {
  testWidgets('bottom bar has five entries with ＋ as the center button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester);

    for (final label in tabLabels) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    final plus = find.byKey(const ValueKey('primary-create-button'));
    expect(plus, findsOneWidget);
    expect(
      find.descendant(of: plus, matching: find.byIcon(Icons.add)),
      findsOneWidget,
    );

    // ＋ sits in the middle, between 发现 and 记录.
    final plusX = tester.getCenter(plus).dx;
    expect(plusX, greaterThan(tester.getCenter(find.text('发现')).dx));
    expect(plusX, lessThan(tester.getCenter(find.text('记录')).dx));
    expect(plusX, closeTo(tester.view.physicalSize.width / 3 / 2, 1));
    semantics.dispose();
  });

  testWidgets('app opens on 今天 with its empty state', (tester) async {
    await pumpApp(tester);
    expect(find.text(emptyTitles[0]).hitTestable(), findsOneWidget);
    expect(find.text('添加第一道菜谱'), findsOneWidget);
  });

  testWidgets('tapping each entry shows its empty state', (tester) async {
    await pumpApp(tester);
    for (final i in [1, 2, 3, 4, 0]) {
      await tapTab(tester, i);
      expect(
        find.text(emptyTitles[i]).hitTestable(),
        findsOneWidget,
        reason: tabLabels[i],
      );
      for (final other in emptyTitles.where((t) => t != emptyTitles[i])) {
        expect(find.text(other), findsNothing);
      }
    }
  });

  testWidgets('the action on 今天 opens the ＋ page', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('添加第一道菜谱'));
    await tester.pumpAndSettle();
    expect(find.text(emptyTitles[2]).hitTestable(), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('follows system ${brightness.name} mode', (tester) async {
      await pumpApp(tester, brightness: brightness);
      for (var i = 0; i < tabLabels.length; i++) {
        await tapTab(tester, i);
        final title = find.text(emptyTitles[i]).hitTestable();
        expect(title, findsOneWidget);
        expect(Theme.of(tester.element(title)).brightness, brightness);
        expect(tester.takeException(), isNull);
      }
    });
  }

  for (final textScale in [2.0, 3.0]) {
    for (final size in const [Size(360, 780), Size(320, 568)]) {
      for (final brightness in Brightness.values) {
        final name =
            '${size.width.toInt()}x${size.height.toInt()} ${brightness.name}';
        testWidgets('text scale $textScale, $name: no overflow or truncation', (
          tester,
        ) async {
          await pumpApp(
            tester,
            brightness: brightness,
            textScale: textScale,
            size: size,
          );
          for (var i = 0; i < tabLabels.length; i++) {
            await tapTab(tester, i);
            expect(tester.takeException(), isNull);
            expect(find.text(emptyTitles[i]).hitTestable(), findsOneWidget);
            // Bottom-bar labels stay fully visible.
            for (final label in tabLabels.where((l) => l != '新建')) {
              final box = tester.renderObject<RenderParagraph>(
                find.text(label),
              );
              expect(box.didExceedMaxLines, isFalse, reason: label);
              expect(
                box.size.width,
                greaterThanOrEqualTo(box.getMaxIntrinsicWidth(double.infinity)),
                reason: label,
              );
            }
          }
        });
      }
    }
  }
}
