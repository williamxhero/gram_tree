import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/features/recipes/cooking_session.dart';

import 'helpers.dart';
import 'scenario_cooking_test.dart' show sessionStore, testApp, revealCooking;

void main() {
  testWidgets(
    'actual ingredient quantity and step duration remain exact after reopening',
    (tester) async {
      final env = TestEnv.signedIn(offline: true);
      final store = await sessionStore(env);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...env.overrides,
            cookingSessionStoreProvider.overrideWithValue(store),
          ],
          child: testApp(const CookingPage(sessionId: 'session')),
        ),
      );
      await tester.pumpAndSettle();
      await revealCooking(tester, find.text('记录临时调整'));
      await tester.tap(find.text('记录临时调整'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('文字备注'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('实际食材用量').last);
      await tester.pumpAndSettle();
      expect(find.text('实际用量（原单位）'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '27.5');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.text('记录临时调整'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('文字备注'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('本步实际时长').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '-1');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('请填写范围内的非负数值'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(find.byType(TextField), '90');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      final saved = (await CookingSessionStore(
        env.local,
        accountId: env.server.user.id,
      ).read('session'))!;
      expect(saved.adjustments, hasLength(2));
      final ingredient =
          saved.snapshot.detail.version.snapshot.ingredients!.first;
      expect(saved.adjustments[0]['ingredient_id'], ingredient.id);
      expect(saved.adjustments[0]['quantity'], 27.5);
      expect(saved.adjustments[0]['unit'], ingredient.unit);
      expect(saved.adjustments[1]['step_id'], 'heat');
      expect(saved.adjustments[1]['fields'], {'duration_seconds': 90});
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'free text warns about exact save and cancel persists no adjustment',
    (tester) async {
      final env = TestEnv.signedIn(offline: true);
      final store = await sessionStore(env);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...env.overrides,
            cookingSessionStoreProvider.overrideWithValue(store),
          ],
          child: testApp(const CookingPage(sessionId: 'session')),
        ),
      );
      await tester.pumpAndSettle();
      await revealCooking(tester, find.text('记录临时调整'));
      await tester.tap(find.text('记录临时调整'));
      await tester.pumpAndSettle();
      expect(find.text('文字备注会完整保留；要从记录保存精确做法，请填写实际用量或时长。'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '少放一点盐');
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect((await store.read('session'))!.adjustments, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
