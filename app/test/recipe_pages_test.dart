import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  testWidgets('create tab opens the structured recipe editor', (tester) async {
    await pumpApp(tester);
    await tapTab(tester, 2);
    expect(find.byKey(const ValueKey('create-recipe-entry')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recipe-dish-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('save-recipe-button')), findsOneWidget);
  });

  testWidgets(
    'editor shows a visible validation result for an empty dish name',
    (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('primary-create-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recipe-save-error')), findsOneWidget);
      expect(find.text('请先填写菜名'), findsOneWidget);
    },
  );
}
