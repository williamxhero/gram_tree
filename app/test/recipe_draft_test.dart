import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('unsaved editor draft recovers after app restart', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('primary-create-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('recipe-dish-name')),
      '重启后仍在的菜',
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      env.local.values.keys.any((key) => key.contains('recipe_draft:v1:')),
      isTrue,
    );

    await restartApp(tester, env);
    await tester.tap(find.byKey(const ValueKey('primary-create-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
    await tester.pumpAndSettle();

    expect(find.text('恢复未保存修改？'), findsOneWidget);
    await tester.tap(find.text('恢复'));
    await tester.pumpAndSettle();
    expect(find.text('重启后仍在的菜'), findsOneWidget);
  });

  testWidgets('discarding an editor draft prevents a later restore', (
    tester,
  ) async {
    final env = await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('primary-create-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('recipe-dish-name')),
      '放弃的菜',
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tapVisible(
      tester,
      find.byKey(const ValueKey('discard-recipe-draft')),
    );
    await tester.tap(find.byKey(const ValueKey('primary-create-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
    await tester.pumpAndSettle();

    expect(find.text('恢复未保存修改？'), findsNothing);
    expect(
      env.local.values.keys.any((key) => key.contains('recipe_draft:v1:')),
      isFalse,
    );
  });
}
