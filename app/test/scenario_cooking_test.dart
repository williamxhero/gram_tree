import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gram_tree/app/app.dart';
import 'package:gram_tree/app/router.dart';
import 'package:gram_tree/features/me/taste_profile_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gram_tree/features/recipes/cooking_session.dart';
import 'package:gram_tree/recipes/recipe_snapshot.dart';
import 'package:gram_tree/ui_protocol/source_mark.dart';
import 'package:gram_tree/ui_protocol/component_registry.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'cooking_controls_support.dart';
import 'helpers.dart';
import 'allergies_page_test.dart' show allergyFixture;
import 'taste_profile_page_test.dart'
    show installProfile, profileFixture, chooseSalty;
import 'recipe_snapshot_test.dart' show recipeSnapshotFixture;

PageDescription cookingComposition(String detail) => PageDescription(
  cache: CacheInfo(ttlS: 0, dependsOn: const {}),
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
        actions: const [],
        reason: ComponentReason(code: 'required', text: '必显'),
        data: {
          'status': 'unknown',
          'conclusion': '安全结果待检查',
          'basis': '尚无安全检查结果',
          'result': null,
        },
      ),
  ],
);

ComponentDescriptor failureReminder(String step, String placement) =>
    ComponentDescriptor(
      type: 'failure_reminder',
      id: 'scene:failure:recipe:dry:$step:$placement',
      detail: ComponentDescriptorDetailEnum.brief,
      actions: const [],
      reason: ComponentReason(code: 'last_failure', text: '上次记录肉柴'),
      data: {
        'conclusion': placement == 'before' ? '下一步注意火候' : '本步注意火候',
        'rule_id': 'dry',
        'problem': '上次肉柴',
        'advice': '变白立即盛出',
        'record_id': '33333333-3333-4333-8333-333333333333',
        'record_date': '2026-10-12',
        'step_id': step,
        'placement': placement,
        'source': {
          'source_type': 'scenario_adjusted',
          'value': '变白立即盛出',
          'basis': {
            'reason_code': 'last_failure',
            'text': '上次记录肉柴',
            'citation': '2026-10-12 做过记录',
          },
        },
      },
    );

Future<CookingSessionStore> sessionStore(
  TestEnv env, {
  Map<String, dynamic> inputs = const {},
  RecipeSafetyResult? safety,
  RecipeDerived? derived,
  List<RecipeStep>? steps,
  int stepIndex = 0,
  String sessionId = 'session',
}) async {
  final source = recipeSnapshotFixture('frozen-v1');
  final detail = source.copyWith(
    version: source.version.copyWith(
      safety: safety,
      derived: derived ?? source.version.derived,
    ),
  );
  detail.version.snapshot.steps!.clear();
  detail.version.snapshot.steps!.addAll(
    steps ??
        [
          RecipeStep(
            id: 'heat',
            action: '加热',
            instruction: '加热至变白',
            doneness: '表面变白',
            why: '避免长时间加热使肉变柴',
            durationSeconds: 60,
          ),
          RecipeStep(id: 'serve', instruction: '盛出'),
        ],
  );
  final store = CookingSessionStore(env.local, accountId: env.server.user.id);
  await store.write(
    CookingSession(
      id: sessionId,
      startedAt: DateTime.utc(2026, 10, 14),
      stepIndex: stepIndex,
      snapshot: FrozenRecipeSnapshot(
        detail: detail,
        capturedAt: DateTime.utc(2026, 10, 14),
        inputs: inputs,
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
    'steps_collapsed': detail == 'brief',
    'layout': 'phone',
    'source': {
      'source_type': 'scenario_adjusted',
      'value': detail,
      'basis': {
        'reason_code': 'page_switch',
        'text': '本页临时选择，不改默认设置',
        'citation': '本页临时选择',
      },
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
  testWidgets('preparation controls remain reachable below long safety cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final env = TestEnv.signedIn();
    final store = await sessionStore(
      env,
      stepIndex: -1,
      steps: [RecipeStep(id: 'prep', instruction: '切好食材')],
    );
    final composition = cookingComposition('detailed').toJson();
    for (final component in composition['components'] as List) {
      if (component['type'] == 'food_safety') {
        (component['data'] as Map)['conclusion'] = List.filled(
          12,
          '安全检查尚未完成，处理生鸡肉后请清洗双手和接触面。',
        ).join('\n');
      }
    }
    env.server.on('POST', '/v1/ui/compositions', (_) => (200, composition));
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
    // Waiting alone cannot mount lazy children below the safety section.
    expect(find.text('先准备食材'), findsNothing);
    await revealCookingControl(tester, find.text('先准备食材'));
    expect(find.text('先准备食材').hitTestable(), findsOneWidget);
    await revealCookingControl(tester, find.text('开始第一步'));
    await tester.tap(find.text('开始第一步').hitTestable());
    await tester.pumpAndSettle();
    await revealCookingControl(
      tester,
      find.byKey(const ValueKey('cooking-action')),
    );
    expect(find.text('切好食材'), findsWidgets);
    expect(find.text('步骤 1 / 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'cooking detail switch expands rationale without changing execution',
    (tester) async {
      final env = TestEnv.signedIn();
      final store = await sessionStore(
        env,
        inputs: const {'scale_mode': 'servings', 'target_servings': 3},
      );
      env.server.on(
        'POST',
        '/v1/ui/compositions',
        (request) => (
          200,
          cookingComposition(
            (request.body as Map)['detail_override'] as String? ?? 'detailed',
          ).toJson(),
        ),
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
      expect(
        env.server.calls('POST', '/v1/ui/compositions').where((call) {
          final body = call.body as Map;
          final personalization = body['personalization'] as Map?;
          return body['detail_override'] == 'brief' &&
              personalization?['target_servings'] == 3;
        }),
        isNotEmpty,
      );
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
      env.server.on(
        'POST',
        '/v1/ui/compositions',
        (_) => (200, description.toJson()),
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

  for (final fixture in [
    (
      view: 'original',
      inputs: <String, dynamic>{
        'personalized_view': 'original',
        'scale_mode': 'servings',
        'target_servings': 3,
      },
      expected: <String, dynamic>{
        'version_id': 'frozen-v1',
        'confirm_allergy_risk': false,
        'diner_member_ids': <String>[],
        'target_servings': 3,
      },
    ),
    (
      view: 'personalized',
      inputs: <String, dynamic>{
        'personalized_view': 'personalized',
        'before_change_id': 'frozen-change',
        'scale_mode': 'servings',
        'target_servings': 3,
      },
      expected: <String, dynamic>{
        'version_id': 'frozen-v1',
        'confirm_allergy_risk': false,
        'diner_member_ids': <String>[],
        'target_servings': 3,
      },
    ),
    (
      view: 'personalized',
      inputs: <String, dynamic>{
        'personalized_view': 'personalized',
        'scale_mode': 'mold',
        'target_mold': {'shape': 'round', 'diameter': 18, 'unit': 'cm'},
      },
      expected: <String, dynamic>{
        'version_id': 'frozen-v1',
        'confirm_allergy_risk': false,
        'diner_member_ids': <String>[],
        'target_mold': {'shape': 'round', 'diameter': 18, 'unit': 'cm'},
      },
    ),
  ]) {
    testWidgets(
      'composition failure retains frozen ${fixture.view} ${fixture.inputs['scale_mode']} inputs and mandatory safety',
      (tester) async {
        final env = TestEnv.signedIn();
        final store = await sessionStore(env, inputs: fixture.inputs);
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
          expect(request['personalization'], fixture.expected);
          expect(
            request['personalization_view'] ?? 'personalized',
            fixture.view,
          );
          expect(
            request['before_change_id'],
            fixture.inputs['before_change_id'],
          );
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
  }

  for (final inputs in [
    <String, dynamic>{
      'personalized_view': 'original',
      'scale_mode': 'servings',
      'target_servings': 3,
      'before_change_id': 'frozen-change',
    },
    <String, dynamic>{
      'personalized_view': 'personalized',
      'scale_mode': 'mold',
      'target_mold': {'shape': 'round', 'diameter': 18, 'unit': 'cm'},
      'before_change_id': 'frozen-change',
    },
  ]) {
    testWidgets(
      'mounted cooking revokes private scene without changing frozen ${inputs['scale_mode']} inputs',
      (tester) async {
        var withdrawn = false;
        var restored = false;
        var saltyLevel = 2;
        final withdrawal = Completer<void>();
        final refreshedScene = Completer<void>();
        addTearDown(() {
          if (!withdrawal.isCompleted) withdrawal.complete();
          if (!refreshedScene.isCompleted) refreshedScene.complete();
        });
        final env = TestEnv.signedIn();
        final store = await sessionStore(
          env,
          inputs: inputs,
          safety: inputs['scale_mode'] == 'servings'
              ? RecipeSafetyResult(
                  checkedAt: '2026-10-14T00:00:00Z',
                  rulesVersion: 'frozen-safety-v1',
                  allergens: const ['花生'],
                  findings: [
                    RecipeSafetyFinding(
                      basis: '食品安全规则',
                      message: '鸡肉必须熟透',
                      ruleId: 'poultry',
                      severity: RecipeSafetyFindingSeverityEnum.warning,
                    ),
                  ],
                )
              : null,
          derived: RecipeDerived(
            activeTimeSeconds: 0,
            totalTimeSeconds: 0,
            allergens: const ['花生'],
          ),
        );
        installProfile(
          env.server,
          () => profileFixture(saltyLevel: saltyLevel, manual: saltyLevel != 2),
        );
        env.server.on('PATCH', '/v1/me/taste-profile', (_) {
          saltyLevel = 1;
          return (200, profileFixture(saltyLevel: 1, manual: true).toJson());
        });
        env.server.on(
          'GET',
          '/v1/me/taste-profile/allergies',
          (_) => (
            200,
            allergyFixture(
                  consentId: withdrawn && !restored
                      ? null
                      : '33333333-3333-4333-8333-333333333333',
                  selected: withdrawn && !restored ? const [] : const ['花生'],
                )
                .copyWith(
                  authorizationVersion: restored
                      ? 3
                      : withdrawn
                      ? 2
                      : 1,
                )
                .toJson(),
          ),
        );
        env.server.on('POST', '/v1/me/consents', (request) async {
          final records = (request.body as Map)['records'] as List;
          if (records.any(
            (record) =>
                record['kind'] == 'sensitive_personal_info' &&
                record['action'] == 'withdraw',
          )) {
            withdrawn = true;
            await withdrawal.future;
          }
          if (records.any(
            (record) =>
                record['kind'] == 'sensitive_personal_info' &&
                record['action'] == 'agree',
          )) {
            restored = true;
          }
          return (204, null);
        });
        env.server.on('POST', '/v1/ui/compositions', (request) async {
          final body = request.body as Map;
          if (body['recipe_id'] != 'recipe') {
            return FakeServer.error(500, 'server_error', '组合不可用');
          }
          if (withdrawn && !restored) {
            await refreshedScene.future;
            return FakeServer.error(500, 'server_error', '组合不可用');
          }
          final page = cookingComposition(
            body['detail_override'] as String? ?? 'detailed',
          );
          final allergen = page.components!.firstWhere(
            (c) => c.type == 'allergen_notice',
          );
          final personalSafety = {
            'status': 'available',
            'alerts': [
              {
                'person': restored ? '新授权成员' : '小禾',
                'kind': 'allergy',
                'target': '花生',
                'ingredient': '鸡肉',
                'replacement': false,
              },
            ],
            'unknown_ingredients': <String>[],
            'incomplete': false,
          };
          page.components![page.components!.indexOf(allergen)] = allergen
              .copyWith(
                data: <String, dynamic>{
                  ...allergen.data as Map,
                  'personal_safety': personalSafety,
                },
              );
          return (200, page.toJson());
        });
        Iterable<Recorded> cookingRequests() => env.server
            .calls('POST', '/v1/ui/compositions')
            .where((request) => (request.body as Map)['recipe_id'] == 'recipe');
        Finder key(String value) => find.byKey(ValueKey(value));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...env.overrides,
              cookingSessionStoreProvider.overrideWithValue(store),
            ],
            child: const GramTreeApp(),
          ),
        );
        await tester.pumpAndSettle();
        final router = ProviderScope.containerOf(
          tester.element(find.byType(Scaffold).first),
        ).read(routerProvider);
        router.push('/cooking/session');
        await tester.pumpAndSettle();
        expect(find.text('过敏提醒：小禾，花生（鸡肉）'), findsOneWidget);
        await revealCooking(tester, find.text('过敏提醒：小禾，花生（鸡肉）'));
        final initialRequest = Map<String, dynamic>.from(
          cookingRequests().last.body as Map,
        );
        final initialRequestCount = cookingRequests().length;
        router.push(TasteProfilePage.path);
        await tester.pumpAndSettle();
        expect(find.byType(TasteProfilePage), findsOneWidget);
        await chooseSalty(tester);
        expect(saltyLevel, 1);
        expect(
          cookingRequests().length,
          initialRequestCount,
          reason: '可变口味不得刷新冻结的做菜请求',
        );
        // The public withdrawal control lives in settings, not the taste editor.
        router.push('/me/settings');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          key('sensitive-withdraw'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.ensureVisible(key('sensitive-withdraw'));
        await tester.pumpAndSettle();
        await tester.tap(key('sensitive-withdraw').hitTestable());
        await tester.pumpAndSettle();
        await tester.tap(key('sensitive-withdraw-confirm').hitTestable());
        await tester.pumpAndSettle();
        expect(withdrawn, isTrue);
        expect(find.byType(CookingPage, skipOffstage: false), findsOneWidget);
        expect(
          find.text('过敏提醒：小禾，花生（鸡肉）', skipOffstage: false),
          findsNothing,
          reason: '撤回尚未确认时也必须移除挂载 cooking 中的私密卡',
        );
        withdrawal.complete();
        await tester.pumpAndSettle();
        expect(find.text('敏感同意已撤回，过敏、家庭成员及私密历史已删除'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        router.pop();
        await tester.pumpAndSettle();
        await revealCooking(
          tester,
          key('recipe-food-safety-card'),
          upward: true,
        );
        expect(key('recipe-allergen-card'), findsOneWidget);
        expect(
          find.text('过敏提醒：小禾，花生（鸡肉）'),
          findsNothing,
          reason: '新组合未返回时不得显示 retained AsyncValue 的授权姓名/过敏',
        );
        expect(cookingRequests().length, greaterThan(initialRequestCount));
        refreshedScene.complete();
        await tester.pumpAndSettle();
        expect(key('recipe-food-safety-card'), findsOneWidget);
        expect(key('recipe-allergen-card'), findsOneWidget);
        expect(find.text('过敏提醒：小禾，花生（鸡肉）'), findsNothing);
        expect(
          find.text('过敏原：花生'),
          findsOneWidget,
          reason: 'frozen safety/result 或 legacyDerived 的通用过敏原仍应显示，而非个人提醒',
        );
        if (inputs['scale_mode'] == 'servings') {
          expect(find.text('鸡肉必须熟透'), findsOneWidget);
        }
        expect(find.text('步骤 1 / 2'), findsOneWidget);
        // Public re-consent and reopening cooking can load a legal, fresh
        // header; recovery must not permanently suppress generic safety.
        router.push(TasteProfilePage.path);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          key('allergies-edit'),
          250,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 30,
        );
        await tester.ensureVisible(key('allergies-edit'));
        await tester.pumpAndSettle();
        await tester.tap(key('allergies-edit').hitTestable());
        await tester.pumpAndSettle();
        await tester.tap(key('allergies-agree').hitTestable());
        await tester.pumpAndSettle();
        expect(restored, isTrue);
        await tester.tap(find.text('取消').hitTestable());
        await tester.pumpAndSettle();
        router.pop();
        await tester.pumpAndSettle();
        // Failed composition has no summary controls. Remount via the public
        // cooking route to request the same immutable key after reauthorization.
        router.pop();
        await tester.pumpAndSettle();
        router.push('/cooking/session');
        await tester.pumpAndSettle();
        await revealCooking(tester, find.text('过敏提醒：新授权成员，花生（鸡肉）'));
        expect(find.text('过敏提醒：小禾，花生（鸡肉）'), findsNothing);
        for (final request in cookingRequests()) {
          expect(
            request.body,
            initialRequest,
            reason: '敏感授权变化只刷新 header，冻结 key 和 inputs 必须完全相同',
          );
        }
        expect(
          env.server.calls('POST', '/v1/recipes/recipe/personalized'),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final useFling in [false, true]) {
    testWidgets(
      'forward ${useFling ? 'left fling' : 'button'} completes current prerequisite before entering dependent step',
      (tester) async {
        final env = TestEnv.signedIn();
        const sessionId = '44444444-4444-4444-8444-444444444444';
        final store = await sessionStore(
          env,
          sessionId: sessionId,
          steps: [
            RecipeStep(id: 'prep', instruction: '切好食材'),
            RecipeStep(
              id: 'cook',
              instruction: '下锅加热',
              dependsOn: const ['prep'],
            ),
            RecipeStep(
              id: 'serve',
              instruction: '装盘上桌',
              dependsOn: const ['prep', 'cook'],
            ),
          ],
        );
        env.server.on(
          'POST',
          '/v1/ui/compositions',
          (_) => (200, cookingComposition('brief').toJson()),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...env.overrides,
              cookingSessionStoreProvider.overrideWithValue(store),
            ],
            child: testApp(const CookingPage(sessionId: sessionId)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('步骤 1 / 3'), findsOneWidget);
        Future<void> forward() async {
          if (useFling) {
            // A drag without velocity does not trigger the cooking fling path.
            await tester.fling(
              find.byType(ListView).first,
              const Offset(-400, 0),
              1000,
            );
          } else {
            await revealCooking(tester, find.text('下一步'));
            await tester.tap(find.text('下一步').hitTestable());
          }
          await tester.pumpAndSettle();
        }

        await forward();
        expect(find.text('步骤 2 / 3'), findsOneWidget);
        expect(find.text('下锅加热'), findsOneWidget);
        expect(find.text('请先完成前置步骤，再继续。'), findsNothing);
        await revealCooking(tester, find.text('上一步'));
        await tester.tap(find.text('上一步').hitTestable());
        await tester.pumpAndSettle();
        expect(find.text('步骤 1 / 3'), findsOneWidget);
        await forward();
        expect(find.text('步骤 2 / 3'), findsOneWidget);
        await forward();
        expect(find.text('步骤 3 / 3'), findsOneWidget);
        expect(find.text('装盘上桌'), findsOneWidget);
        await revealCooking(tester, find.text('完成'));
        await tester.tap(find.text('完成').hitTestable());
        await tester.pumpAndSettle();
        expect(find.text('已完成 汤'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('forward cannot satisfy another unfinished prerequisite', (
    tester,
  ) async {
    final env = TestEnv.signedIn();
    final store = await sessionStore(
      env,
      stepIndex: 1,
      steps: [
        RecipeStep(id: 'prep', instruction: '切好食材'),
        RecipeStep(id: 'cook', instruction: '下锅加热', dependsOn: const ['prep']),
        RecipeStep(
          id: 'serve',
          instruction: '装盘上桌',
          dependsOn: const ['prep', 'cook'],
        ),
      ],
    );
    env.server.on(
      'POST',
      '/v1/ui/compositions',
      (_) => (200, cookingComposition('brief').toJson()),
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
    await revealCooking(tester, find.text('下一步'));
    await tester.tap(find.text('下一步').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('步骤 2 / 3'), findsOneWidget);
    expect(find.text('装盘上桌'), findsNothing);
    expect(find.text('请先完成前置步骤，再继续。'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('backward navigation never completes the step being left', (
    tester,
  ) async {
    final env = TestEnv.signedIn();
    // An acyclic dependency need not follow display order: assembling needs
    // cooking. A restored cook step is still unfinished until moving forward.
    final store = await sessionStore(
      env,
      stepIndex: 1,
      steps: [
        RecipeStep(
          id: 'assemble',
          instruction: '组装成品',
          dependsOn: const ['cook'],
        ),
        RecipeStep(id: 'cook', instruction: '下锅加热'),
      ],
    );
    env.server.on(
      'POST',
      '/v1/ui/compositions',
      (_) => (200, cookingComposition('brief').toJson()),
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
    await revealCooking(tester, find.text('上一步'));
    await tester.tap(find.text('上一步').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('步骤 1 / 2'), findsOneWidget);
    await tester.fling(find.byType(ListView).first, const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('先准备食材'), findsOneWidget);
    await revealCooking(tester, find.text('开始第一步'));
    await tester.tap(find.text('开始第一步').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('先准备食材'), findsOneWidget);
    expect(find.text('组装成品'), findsNothing);
    expect(find.text('请先完成前置步骤，再继续。'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

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
