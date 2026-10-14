import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gram_tree/features/recipes/cooking_session.dart';
import 'package:gram_tree/recipes/recipe_snapshot.dart';
import 'package:gram_tree/ui_protocol/composition_provider.dart';
import 'package:gram_tree/ui_protocol/source_mark.dart';
import 'package:gram_tree/ui_protocol/component_registry.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';
import 'recipe_snapshot_test.dart' show recipeSnapshotFixture;

PageDescription cookingComposition(String detail) => PageDescription(
  cache: CacheInfo(ttlS: 0),
  compositionId: '7c9e6679-7425-40de-944b-e07fc1f90ae7',
  generatedAt: '2026-10-14T00:00:00Z',
  pageType: 'recipe_detail',
  protocol: '1.0',
  components: [
    scenarioSummary(detail),
    for (final type in ['food_safety', 'allergen_notice'])
      ComponentDescriptor(
        type: type,
        id: type,
        detail: ComponentDescriptorDetailEnum.brief,
        required_: true,
        reason: ComponentReason(code: 'required', text: '必显'),
        data: {'status': 'unknown', 'conclusion': '安全结果待检查'},
      ),
  ],
);

ComponentDescriptor failureReminder(String step, String placement) =>
    ComponentDescriptor(
      type: 'failure_reminder',
      id: 'scene:failure:recipe:dry:$step:$placement',
      detail: ComponentDescriptorDetailEnum.brief,
      reason: ComponentReason(code: 'last_failure', text: '上次记录肉柴'),
      data: {
        'conclusion': placement == 'before' ? '下一步注意火候' : '本步注意火候',
        'rule_id': 'dry',
        'problem': '上次肉柴',
        'advice': '变白立即盛出',
        'record_id': 'record',
        'record_date': '2026-10-12',
        'step_id': step,
        'placement': placement,
        'source': {
          'source_type': 'scenario_adjusted',
          'value': '变白立即盛出',
          'basis': {'text': '上次记录肉柴', 'citation': '2026-10-12 做过记录'},
        },
      },
    );

Future<CookingSessionStore> sessionStore(TestEnv env) async {
  final detail = recipeSnapshotFixture('frozen-v1');
  detail.version.snapshot.steps!.clear();
  detail.version.snapshot.steps!.addAll([
    RecipeStep(
      id: 'heat',
      action: '加热',
      instruction: '加热至变白',
      doneness: '表面变白',
      why: '避免长时间加热使肉变柴',
      durationSeconds: 60,
    ),
    RecipeStep(id: 'serve', instruction: '盛出'),
  ]);
  final store = CookingSessionStore(env.local, accountId: env.server.user.id);
  await store.write(
    CookingSession(
      id: 'session',
      startedAt: DateTime.utc(2026, 10, 14),
      stepIndex: 0,
      snapshot: FrozenRecipeSnapshot(
        detail: detail,
        capturedAt: DateTime.utc(2026, 10, 14),
        inputs: const {},
        render: null,
        dependencies: const {},
      ),
    ),
  );
  return store;
}

ComponentDescriptor scenarioSummary(String detail) => ComponentDescriptor(
  type: 'scenario_summary',
  id: 'scene:detail',
  detail: ComponentDescriptorDetailEnum.values.firstWhere(
    (value) => value.value == detail,
  ),
  reason: ComponentReason(code: 'page_switch', text: '本页临时选择'),
  data: {
    'conclusion': '本页步骤详略',
    'source': {
      'source_type': 'scenario_adjusted',
      'value': detail,
      'basis': {'text': '本页临时选择，不改默认设置'},
    },
  },
  actions: [
    for (final value in ['brief', 'detailed', 'auto'])
      ActionDescriptor(
        intent: 'set_scenario_detail',
        params: {'detail': value},
      ),
  ],
);

Widget testApp(Widget child) => MaterialApp(
  theme: buildTheme(Brightness.light),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

Finder get cookingScroll => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

Future<void> revealCooking(
  WidgetTester tester,
  Finder target, {
  bool upward = false,
}) async {
  for (var i = 0; i < 20 && target.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(cookingScroll, Offset(0, upward ? 200 : -200));
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
}

void main() {
  testWidgets(
    'cooking detail switch expands rationale without changing execution',
    (tester) async {
      final env = TestEnv.signedIn();
      final store = await sessionStore(env);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...env.overrides,
            cookingSessionStoreProvider.overrideWithValue(store),
            scenarioCompositionProvider.overrideWith(
              (ref, key) async => CompositionReady(
                cookingComposition(key.detailOverride ?? 'detailed'),
              ),
            ),
          ],
          child: testApp(const CookingPage(sessionId: 'session')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('避免长时间加热使肉变柴'),
        200,
        scrollable: cookingScroll,
      );
      await tester.pumpAndSettle();
      expect(find.text('避免长时间加热使肉变柴').hitTestable(), findsOneWidget);
      expect(
        find.byKey(const ValueKey('recipe-food-safety-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('recipe-allergen-card')),
        findsOneWidget,
      );
      await revealCooking(
        tester,
        find.byKey(const ValueKey('scenario-detail-brief')),
        upward: true,
      );
      await tester.tap(find.byKey(const ValueKey('scenario-detail-brief')));
      await tester.pumpAndSettle();
      expect(find.text('避免长时间加热使肉变柴').hitTestable(), findsNothing);
      expect(find.text('成熟判断：表面变白'), findsNothing);
      expect(find.byKey(const ValueKey('cooking-action')), findsOneWidget);
      expect(find.text('步骤 1 / 2'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('计时 60 秒'),
        250,
        scrollable: cookingScroll,
      );
      await tester.tap(find.text('计时 60 秒'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('记录问题'),
        250,
        scrollable: cookingScroll,
      );
      await tester.tap(find.text('记录问题'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      await revealCooking(tester, find.text('记录临时调整'));
      await tester.tap(find.text('记录临时调整'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  少放一点盐  ');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('下一步'),
        250,
        scrollable: cookingScroll,
      );
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      expect(find.text('盛出'), findsWidgets);
      expect(find.text('步骤 2 / 2'), findsOneWidget);
      expect(env.server.calls('PUT', '/v1/ui/preferences'), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'server reminder appears at previous step end then target step, with evidence',
    (tester) async {
      final env = TestEnv.signedIn();
      final store = await sessionStore(env);
      final description = cookingComposition('brief');
      description.components!.addAll([
        failureReminder(
          'heat',
          'before',
        ), // No predecessor: never show during preparation.
        failureReminder('serve', 'before'),
        failureReminder('serve', 'at'),
      ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...env.overrides,
            cookingSessionStoreProvider.overrideWithValue(store),
            scenarioCompositionProvider.overrideWith(
              (ref, key) async => CompositionReady(description),
            ),
          ],
          child: testApp(const CookingPage(sessionId: 'session')),
        ),
      );
      await tester.pumpAndSettle();
      final before = find.byKey(
        const ValueKey('scene:failure:recipe:dry:serve:before'),
      );
      await revealCooking(tester, before);
      expect(
        find.byKey(const ValueKey('scene:failure:recipe:dry:heat:before')),
        findsNothing,
      );
      expect(find.text('本步注意火候'), findsNothing);
      expect(find.text('变白立即盛出'), findsOneWidget);
      expect(find.text('依据做过记录：2026-10-12'), findsOneWidget);
      final mark = find.descendant(
        of: before,
        matching: find.byType(SourceMark),
      );
      await tester.tap(mark);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
      expect(find.text('上次记录肉柴'), findsOneWidget);
      expect(find.text('2026-10-12 做过记录'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await revealCooking(tester, find.text('下一步'));
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      await revealCooking(tester, find.text('本步注意火候'), upward: true);
      expect(find.text('下一步注意火候'), findsNothing);
      expect(find.text('变白立即盛出'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('recipe-food-safety-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('recipe-allergen-card')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'composition failure retains standard cooking and mandatory safety',
    (tester) async {
      final env = TestEnv.signedIn();
      final store = await sessionStore(env);
      env.server.on(
        'POST',
        '/v1/ui/compositions',
        (_) => FakeServer.error(500, 'server_error', '组合不可用'),
      );
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
      expect(
        find.byKey(const ValueKey('recipe-food-safety-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('recipe-allergen-card')),
        findsOneWidget,
      );
      expect(find.text('本页步骤详略'), findsNothing);
      final requests = env.server.calls('POST', '/v1/ui/compositions');
      expect(requests, isNotEmpty);
      for (final call in requests) {
        final request = call.body as Map;
        expect(request['recipe_id'], 'recipe');
        expect(request['version_id'], 'frozen-v1');
        expect(request['page_type'], 'recipe_detail');
      }
      await revealCooking(tester, find.text('成熟判断：表面变白'));
      expect(find.text('避免长时间加热使肉变柴').hitTestable(), findsNothing);
      await revealCooking(tester, find.text('下一步'));
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      expect(find.text('步骤 2 / 2'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('scenario switches and source remain accessible in brief cards', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final actions = <ActionDescriptor>[];
    final env = TestEnv.signedIn();
    await tester.pumpWidget(
      ProviderScope(
        overrides: env.overrides,
        child: testApp(
          Scaffold(
            body: Builder(
              builder: (context) {
                final spec = defaultComponentRegistry['scenario_summary']!;
                return spec.builder(
                  context,
                  scenarioSummary('brief'),
                  spec.emptyState,
                  actions.add,
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('本页简洁'), findsOneWidget);
    expect(find.bySemanticsLabel('本页详细'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('来源.*按场景调整')), findsOneWidget);
    await tester.tap(find.text('本页详细'));
    expect(actions.single.params, {'detail': 'detailed'});
    semantics.dispose();
  });
}
