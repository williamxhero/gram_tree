import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:gram_tree/storage/local_store.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/fake_event_queue.dart';

import 'helpers.dart';

const _recipe = '22222222-2222-4222-8222-222222222222';
const _modification = '33333333-3333-4333-8333-333333333333';
const _request = '11111111-1111-4111-8111-111111111111';
const _instruction = '中火炒熟鸡肉，中心达到 74°C';

RecipeSnapshot _snapshot([String instruction = _instruction]) =>
    RecipeSnapshot.fromJson({
      'format_version': 1,
      'servings': 2,
      'ingredients': [
        {'id': 'chicken', 'display_name': '鸡肉', 'quantity': 300, 'unit': 'g'},
      ],
      'steps': [
        {
          'id': 'cook',
          'instruction': instruction,
          'duration_seconds': 300,
          'ingredient_ids': ['chicken'],
          'heat': '中火',
          'cookware': '炒锅',
        },
      ],
    });

RecipeSafetyResult _safety() => RecipeSafetyResult(
  allergens: [],
  allergensIncomplete: true,
  canSave: true,
  checkedAt: '2026-10-07T00:00:00+00:00',
  findings: [],
  highRisk: false,
  prohibitedClaims: [],
  replacementAllergens: [],
  rulesVersion: 'test-v1',
);

RecipeDetail _detail({String version = 'baseline'}) => RecipeDetail(
  author: RecipeAuthor(id: testUser().id, nickname: testUser().nickname),
  createdAt: '2026-10-07T00:00:00+00:00',
  updatedAt: '2026-10-07T00:00:00+00:00',
  dish: DishOut(id: 'dish', name: '炒鸡肉', aliases: []),
  id: _recipe,
  visibility: RecipeDetailVisibilityEnum.private,
  version: RecipeVersionOut(
    aiAssisted: false,
    changeNote: '',
    createdAt: '2026-10-07T00:00:00+00:00',
    derived: RecipeDerived(
      activeTimeSeconds: 300,
      totalTimeSeconds: 300,
      allergensIncomplete: true,
    ),
    editOperations: [],
    id: version,
    images: [],
    snapshot: _snapshot(),
    versionNumber: 1,
  ),
);

class _Fixture {
  late final TestEnv env;
  bool saved = false;
  String version = 'baseline';
  bool failProposal = false;
  bool failConfirmation = false;
  bool loseConfirmationResponse = false;
  bool numeric = false;
  Completer<void>? checkGate;
  Completer<void>? confirmationGate;
  List<Map<String, dynamic>> decisions = [];
  int revision = 0;

  _Fixture({MemoryLocalStore? local, FakeEventQueue? events}) {
    final base = TestEnv.signedIn(local: local);
    env = events == null
        ? base
        : TestEnv(
            server: base.server,
            local: base.local,
            secure: base.secure,
            eventQueue: events,
          );
    final status = AIStatus(available: true, remaining: 48);
    env.server.on(
      'GET',
      '/v1/ai/recipes/status',
      (_) => (200, status.toJson()),
    );
    env.server.on(
      'POST',
      '/v1/ai/recipes/requests',
      (_) => (
        200,
        RetrievalResult(
          intent: RecipeIntent(dishName: '炒鸡肉'),
          questions: [],
          recipes: [],
          requestId: _request,
          status: status,
          text: '炒鸡肉',
        ).toJson(),
      ),
    );
    env.server.on(
      'POST',
      '/v1/ai/recipes/requests/$_request/generate',
      (_) => (
        200,
        GenerationResult(
          requestId: _request,
          status: status,
          safety: _safety(),
          draft: GeneratedDraft(
            cuisine: '家常',
            rationale: '一般经验',
            recipe: RecipeCreate(
              dishName: '炒鸡肉',
              snapshot: _snapshot(),
              aiAssisted: true,
            ),
          ),
        ).toJson(),
      ),
    );
    env.server.on(
      'GET',
      '/v1/recipes/$_recipe',
      (_) => (200, _detail(version: version).toJson()),
    );
    env.server.on(
      'GET',
      '/v1/recipes/$_recipe/versions/baseline',
      (_) => (200, _detail().toJson()),
    );
    env.server.on(
      'GET',
      '/v1/ai/recipes/modifications/status',
      (_) => (200, status.toJson()),
    );
    env.server.on(
      'POST',
      '/v1/ai/recipes/change-explanation',
      (_) => (
        200,
        ChangeExplanationResult(
          changeNote: '自动说明：只澄清本次操作',
          tags: ['澄清'],
          changesFingerprint: 'checked-operations',
          source_: ChangeExplanationResultSource_Enum.aiEstimated,
          status: AIStatus(
            available: false,
            remaining: 0,
            reason: 'daily_quota',
          ),
        ).toJson(),
      ),
    );
    env.server.on('POST', '/v1/ai/recipes/modifications', (_) {
      if (failProposal) return FakeServer.error(503, 'unavailable', '模型请求超时');
      return (200, preview());
    });
    env.server.on(
      'POST',
      '/v1/ai/recipes/modifications/$_modification/decisions',
      (r) async {
        if (saved) {
          return FakeServer.error(409, 'modification_already_saved', '修改已保存');
        }
        final supplied = [
          for (final d in (r.body as Map)['decisions'] as List)
            Map<String, dynamic>.from(d as Map),
        ];
        await checkGate?.future;
        decisions = supplied;
        revision++;
        return (200, preview());
      },
    );
    env.server.on(
      'POST',
      '/v1/ai/recipes/modifications/$_modification/confirm',
      (_) async {
        if (failConfirmation) {
          return FakeServer.error(503, 'unavailable', '保存失败');
        }
        saved = true;
        if (confirmationGate != null) {
          version = 'saved';
          await confirmationGate!.future;
        }
        if (loseConfirmationResponse) {
          loseConfirmationResponse = false;
          return FakeServer.error(503, 'unavailable', '保存响应丢失');
        }
        return (201, _detail(version: 'saved').toJson());
      },
    );
  }

  Map<String, dynamic> preview() => ModificationPreview.fromJson({
    'id': _modification,
    'revision': revision,
    'intent': {'category': 'text', 'parameters': {}, 'confidence': 0.95},
    'operations': [
      for (final (id, field, after, dependencies) in [
        (
          'clarify',
          numeric ? 'duration_seconds' : 'instruction',
          numeric ? 240 : '翻炒至中心达到 74°C。',
          <String>[],
        ),
        ('remind', 'notes', '温度计测量中心。', ['clarify']),
      ])
        {
          'operation_id': id,
          'type': numeric && id == 'clarify'
              ? 'change_step_duration'
              : 'change_step_field',
          'id': 'cook',
          'field': field,
          'before': field == 'duration_seconds'
              ? 300
              : field == 'instruction'
              ? _instruction
              : null,
          'after': after,
          'scope': ['steps:cook'],
          'intent': '写清楚步骤',
          'reason': '只澄清文字',
          'risk': '仍需实际验证',
          'confidence': 0.95,
          'depends_on': dependencies,
        },
    ],
    'decisions': [
      for (final id in ['clarify', 'remind'])
        {
          'operation_id': id,
          'decision': 'pending',
          'blocked_by': <String>[],
          ...?decisions.where((d) => d['operation_id'] == id).firstOrNull,
        },
    ],
    'snapshot':
        (numeric
                ? _snapshot().copyWith(
                    steps: [
                      _snapshot().steps!.first.copyWith(
                        durationSeconds:
                            decisions
                                    .where(
                                      (d) => d['operation_id'] == 'clarify',
                                    )
                                    .firstOrNull?['after']
                                as int? ??
                            300,
                      ),
                    ],
                  )
                : _snapshot(
                    decisions
                                .where((d) => d['operation_id'] == 'clarify')
                                .firstOrNull?['after']
                            as String? ??
                        _instruction,
                  ))
            .toJson(),
    'safety': _safety().toJson(),
    'reproducibility': {
      'rules_version': 'test-v1',
      'state': 'reproducible',
      'required_field_count': 1,
      'concrete_field_count': 1,
      'field_completeness': 1.0,
      'remaining_count': 0,
      'problems': [],
    },
    'status': AIStatus(available: true, remaining: 48).toJson(),
    'warnings': [],
  }).toJson();
}

Future<void> _route(
  WidgetTester tester,
  String path, {
  bool settle = true,
}) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
}

Future<void> _reveal(
  WidgetTester tester,
  String key, {
  bool settle = true,
}) async {
  final scrollable = find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .first;
  for (var i = 0; i < 8; i++) {
    await tester.drag(scrollable, const Offset(0, 600));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.scrollUntilVisible(
    find.byKey(ValueKey(key)),
    250,
    scrollable: scrollable,
    maxScrolls: 60,
  );
  await Scrollable.ensureVisible(
    tester.element(find.byKey(ValueKey(key))),
    alignment: 0.5,
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  await _reveal(tester, key);
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<void> _selected(
  WidgetTester tester,
  _Fixture fixture, {
  bool generated = false,
  Size size = const Size(360, 780),
}) async {
  await pumpApp(tester, env: fixture.env, size: size);
  await _route(
    tester,
    generated ? '/recipes/one-line' : '/recipes/$_recipe/edit',
  );
  if (generated) {
    await tester.enterText(find.byKey(const ValueKey('one-line-input')), '炒鸡肉');
    await _tap(tester, 'one-line-search');
    await _tap(tester, 'ai-design-new');
    await _tap(tester, 'ai-skip-questions');
    await _reveal(tester, 'text-edit-input');
  }
  await tester.enterText(
    find.byKey(const ValueKey('text-edit-input')),
    '写清楚步骤',
  );
  await _tap(tester, 'text-edit-preview');
  await _tap(tester, 'text-edit-modify-clarify');
  await _reveal(tester, 'text-edit-after-clarify');
  await tester.enterText(
    find.byKey(const ValueKey('text-edit-after-clarify')),
    fixture.numeric ? '180' : '我确认的文字：中心达到 74°C。',
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
  await _tap(tester, 'text-edit-reject-remind');
}

class _DelayedRemoveStore extends MemoryLocalStore {
  _DelayedRemoveStore() : super(consentedStore());
  Completer<void>? gate;
  bool failRemoval = false;

  @override
  Future<void> remove(String key) async {
    if (key.contains(':modification:')) {
      await gate?.future;
      if (failRemoval) throw StateError('device storage unavailable');
    }
    await super.remove(key);
  }
}

Future<void> _signInAs(
  WidgetTester tester,
  _Fixture fixture,
  UserOut user,
) async {
  await _route(tester, '/me/settings');
  await tapVisible(tester, find.text('退出登录'));
  await tester.tap(find.widgetWithText(FilledButton, '退出登录'));
  await tester.pumpAndSettle();
  fixture.env.server.user = user;
  await tester.enterText(
    find.byKey(const ValueKey('login-email')),
    'another@example.com',
  );
  await tester.tap(find.text('发送验证码'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('code-input')), goodCode);
  await tester.pumpAndSettle();
}

class _SlowEvents extends FakeEventQueue {
  Completer<void>? gate;
  @override
  Future<void> enqueue(
    QueuedEvent event, {
    Map<String, dynamic>? businessRecord,
  }) async {
    await gate?.future;
    await super.enqueue(event, businessRecord: businessRecord);
  }
}

void main() {
  testWidgets(
    'adopted AI explanation survives unchanged server recheck after restart',
    (tester) async {
      final fixture = _Fixture();
      await _selected(tester, fixture);
      await _tap(tester, 'change-explanation-generate');
      expect(find.text('自动说明：只澄清本次操作'), findsOneWidget);
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/$_recipe/edit');
      await _reveal(tester, 'change-explanation-note');
      expect(find.text('自动说明：只澄清本次操作'), findsOneWidget);
      expect(find.text('澄清'), findsOneWidget);
      await _tap(tester, 'text-edit-confirm');
      final save =
          fixture.env.server
                  .calls(
                    'POST',
                    '/v1/ai/recipes/modifications/$_modification/confirm',
                  )
                  .single
                  .body
              as Map;
      expect(save['change_note'], '自动说明：只澄清本次操作');
      expect(save['tags'], ['澄清']);
      expect(save['explanation_fingerprint'], 'checked-operations');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed later proposal retains adopted AI explanation without stale fingerprint',
    (tester) async {
      final fixture = _Fixture();
      await _selected(tester, fixture);
      await _tap(tester, 'change-explanation-generate');
      expect(find.text('自动说明：只澄清本次操作'), findsOneWidget);
      fixture.failProposal = true;
      await _reveal(tester, 'text-edit-input');
      await tester.enterText(
        find.byKey(const ValueKey('text-edit-input')),
        '再试另一种写法',
      );
      await _tap(tester, 'text-edit-preview');
      await _reveal(tester, 'change-explanation-note');
      expect(find.text('自动说明：只澄清本次操作'), findsOneWidget);
      expect(find.text('澄清'), findsOneWidget);
      await _tap(tester, 'text-edit-confirm');
      final save =
          fixture.env.server
                  .calls(
                    'POST',
                    '/v1/ai/recipes/modifications/$_modification/confirm',
                  )
                  .single
                  .body
              as Map;
      expect(save['change_note'], '自动说明：只澄清本次操作');
      expect(save['tags'], ['澄清']);
      expect(save['explanation_fingerprint'], isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancel abandons author metadata ownership before a fresh explanation',
    (tester) async {
      final fixture = _Fixture();
      await _selected(tester, fixture);
      await _reveal(tester, 'change-explanation-note');
      await tester.enterText(
        find.byKey(const ValueKey('change-explanation-note')),
        '放弃的作者说明',
      );
      await _reveal(tester, 'change-explanation-tags');
      await tester.enterText(
        find.byKey(const ValueKey('change-explanation-tags')),
        '放弃的作者标签',
      );
      await _tap(tester, 'text-edit-cancel');
      await _reveal(tester, 'text-edit-input');
      await tester.enterText(
        find.byKey(const ValueKey('text-edit-input')),
        '重新澄清做法',
      );
      await _tap(tester, 'text-edit-preview');
      await _tap(tester, 'text-edit-accept-clarify');
      await _tap(tester, 'text-edit-reject-remind');
      await _tap(tester, 'change-explanation-generate');
      expect(find.text('自动说明：只澄清本次操作'), findsOneWidget);
      expect(find.text('澄清'), findsOneWidget);
      expect(find.text('放弃的作者说明'), findsNothing);
      expect(find.text('放弃的作者标签'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final cleanupFails in [false, true]) {
    testWidgets(
      'save response after disposal cleans old baseline without deleting newer form; cleanup failure $cleanupFails',
      (tester) async {
        final local = _DelayedRemoveStore();
        final fixture = _Fixture(local: local);
        await _selected(tester, fixture);
        await _reveal(tester, 'text-edit-confirm');
        final response = Completer<void>();
        fixture.confirmationGate = response;
        local.failRemoval = cleanupFails;
        addTearDown(() {
          if (!response.isCompleted) response.complete();
        });
        await tester.tap(find.byKey(const ValueKey('text-edit-confirm')));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(fixture.saved, isTrue);
        expect(fixture.version, 'saved');
        await _route(tester, '/recipes');
        await _route(tester, '/recipes/$_recipe/edit');
        await _reveal(tester, 'recipe-step-instruction-cook');
        await tester.enterText(
          find.byKey(const ValueKey('recipe-step-instruction-cook')),
          '新版本上仍未保存的步骤',
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        response.complete();
        await tester.pumpAndSettle();
        expect(
          GoRouter.of(tester.element(find.byType(Scaffold).first))
              .routeInformationProvider
              .value
              .uri
              .path,
          '/recipes/$_recipe/edit',
        );
        await restartApp(tester, fixture.env);
        await _route(tester, '/recipes/$_recipe/edit');
        expect(find.text('恢复未保存修改？'), findsOneWidget);
        await tester.tap(find.text('恢复'));
        await tester.pumpAndSettle();
        await _reveal(tester, 'recipe-step-instruction-cook');
        expect(find.text('新版本上仍未保存的步骤'), findsOneWidget);
        // Visit the immutable historical baseline through its public editor to
        // expose a stranded old receipt, without inspecting local-store keys.
        local.failRemoval = false;
        await _route(tester, '/recipes');
        await _route(tester, '/recipes/$_recipe/edit?versionId=baseline');
        expect(
          GoRouter.of(tester.element(find.byType(Scaffold).first))
              .routeInformationProvider
              .value
              .uri
              .path,
          cleanupFails ? '/recipes/$_recipe' : '/recipes/$_recipe/edit',
        );
        expect(find.byKey(const ValueKey('text-edit-confirm')), findsNothing);
        expect(
          fixture.env.server.calls(
            'POST',
            '/v1/ai/recipes/modifications/$_modification/confirm',
          ),
          hasLength(1),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'old committed cleanup cannot delete a reopened editor newer form draft',
    (tester) async {
      final local = _DelayedRemoveStore();
      final fixture = _Fixture(local: local);
      await _selected(tester, fixture);
      await _reveal(tester, 'text-edit-confirm');
      final gate = Completer<void>();
      local.gate = gate;
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      await tester.tap(find.byKey(const ValueKey('text-edit-confirm')));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        fixture.env.server.calls(
          'POST',
          '/v1/ai/recipes/modifications/$_modification/confirm',
        ),
        hasLength(1),
      );
      fixture.version = 'saved';
      await _route(tester, '/recipes');
      await _route(tester, '/recipes/$_recipe/edit');
      await _reveal(tester, 'recipe-step-instruction-cook');
      await tester.enterText(
        find.byKey(const ValueKey('recipe-step-instruction-cook')),
        '新编辑器的未保存手写步骤',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      gate.complete();
      await tester.pumpAndSettle();
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/$_recipe/edit');
      expect(find.text('恢复未保存修改？'), findsOneWidget);
      await tester.tap(find.text('恢复'));
      await tester.pumpAndSettle();
      await _reveal(tester, 'recipe-step-instruction-cook');
      expect(find.text('新编辑器的未保存手写步骤'), findsOneWidget);
      expect(find.byKey(const ValueKey('text-edit-confirm')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'old abandonment cleanup preserves reopened editor newer choices',
    (tester) async {
      final local = _DelayedRemoveStore();
      final fixture = _Fixture(local: local);
      await _selected(tester, fixture);
      await _reveal(tester, 'text-edit-cancel');
      final gate = Completer<void>();
      local.gate = gate;
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      await tester.tap(find.byKey(const ValueKey('text-edit-cancel')));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await _route(tester, '/recipes');
      // Restored checking is waiting behind the held storage removal. Keep
      // exercising the public editor without settling its deliberate spinner.
      await _route(tester, '/recipes/$_recipe/edit', settle: false);
      await _reveal(tester, 'text-edit-after-clarify', settle: false);
      await tester.enterText(
        find.byKey(const ValueKey('text-edit-after-clarify')),
        '新编辑器确认的后值',
      );
      await tester.pump(const Duration(milliseconds: 300));
      gate.complete();
      await tester.pumpAndSettle();
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/$_recipe/edit');
      await _reveal(tester, 'text-edit-after-clarify');
      expect(find.text('新编辑器确认的后值'), findsOneWidget);
      await _reveal(tester, 'text-edit-confirm');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('text-edit-confirm')),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final generated in [false, true]) {
    testWidgets(
      'committed cleanup stays in the originating account after public sign-in switch from ${generated ? 'generation' : 'editing'}',
      (tester) async {
        final local = _DelayedRemoveStore();
        final fixture = _Fixture(local: local);
        await _selected(tester, fixture, generated: generated);
        await _reveal(tester, 'text-edit-confirm');
        final gate = Completer<void>();
        local.gate = gate;
        addTearDown(() {
          if (!gate.isCompleted) gate.complete();
        });
        await tester.tap(find.byKey(const ValueKey('text-edit-confirm')));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(
          fixture.env.server.calls(
            'POST',
            '/v1/ai/recipes/modifications/$_modification/confirm',
          ),
          hasLength(1),
        );
        await _signInAs(
          tester,
          fixture,
          testUser().copyWith(
            id: '99999999-9999-4999-8999-999999999999',
            nickname: '另一位味友',
          ),
        );
        gate.complete();
        await tester.pumpAndSettle();
        expect(
          GoRouter.of(tester.element(find.byType(Scaffold).first))
              .routeInformationProvider
              .value
              .uri
              .path,
          '/today',
        );
        await _route(tester, '/recipes/one-line');
        expect(find.byKey(const ValueKey('text-edit-confirm')), findsNothing);
        await _signInAs(tester, fixture, testUser());
        final path = generated ? '/recipes/one-line' : '/recipes/$_recipe/edit';
        await _route(tester, path);
        expect(
          GoRouter.of(tester.element(find.byType(Scaffold).first))
              .routeInformationProvider
              .value
              .uri
              .path,
          path,
        );
        expect(find.byKey(const ValueKey('text-edit-confirm')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'committed cleanup safely finishes after leaving the ${generated ? 'generated result' : 'ordinary editor'}',
      (tester) async {
        final local = _DelayedRemoveStore();
        final fixture = _Fixture(local: local);
        await _selected(tester, fixture, generated: generated);
        await _reveal(tester, 'text-edit-confirm');
        final gate = Completer<void>();
        local.gate = gate;
        addTearDown(() {
          if (!gate.isCompleted) gate.complete();
        });
        await tester.tap(find.byKey(const ValueKey('text-edit-confirm')));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(
          fixture.env.server.calls(
            'POST',
            '/v1/ai/recipes/modifications/$_modification/confirm',
          ),
          hasLength(1),
        );
        await _route(tester, '/recipes');
        gate.complete();
        await tester.pumpAndSettle();
        expect(
          GoRouter.of(tester.element(find.byType(Scaffold).first))
              .routeInformationProvider
              .value
              .uri
              .path,
          '/recipes',
        );
        await restartApp(tester, fixture.env);
        final path = generated ? '/recipes/one-line' : '/recipes/$_recipe/edit';
        await _route(tester, path);
        expect(
          GoRouter.of(tester.element(find.byType(Scaffold).first))
              .routeInformationProvider
              .value
              .uri
              .path,
          path,
        );
        expect(find.byKey(const ValueKey('text-edit-confirm')), findsNothing);
        expect(find.text('恢复未保存修改？'), findsNothing);
        expect(
          fixture.env.server.calls(
            'POST',
            '/v1/ai/recipes/modifications/$_modification/confirm',
          ),
          hasLength(1),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'AI metadata and untouched manual form never duplicate explanation keys',
    (tester) async {
      final fixture = _Fixture();
      await _selected(tester, fixture, size: const Size(1200, 3000));
      await _reveal(tester, 'recipe-dish-name');
      expect(
        find.byKey(const ValueKey('change-explanation-note')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('change-explanation-tags')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'explanation uses persisted intent and does not replace modification quota',
    (tester) async {
      final events = _SlowEvents();
      final fixture = _Fixture(events: events);
      await _selected(tester, fixture);
      await _reveal(tester, 'change-explanation-generate');
      final gate = Completer<void>();
      events.gate = gate;
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      await tester.tap(
        find.byKey(const ValueKey('change-explanation-generate')),
      );
      await tester.pump();
      expect(
        fixture.env.server.calls('POST', '/v1/ai/recipes/change-explanation'),
        isEmpty,
      );
      events.gate = null;
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('自动说明：只澄清本次操作'), findsOneWidget);
      await _reveal(tester, 'text-edit-quota');
      expect(find.text('今日修改剩余 48 次'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('text-edit-preview')),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('manual explanation adopts successful last-allowance result', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _selected(tester, fixture);
    await _reveal(tester, 'recipe-step-instruction-cook');
    await tester.enterText(
      find.byKey(const ValueKey('recipe-step-instruction-cook')),
      '手动澄清本次操作',
    );
    // Start outside the centred field's selection handle.
    await tester.dragFrom(const Offset(30, 220), const Offset(0, 500));
    await tester.pumpAndSettle();
    await _tap(tester, 'change-explanation-generate');
    expect(find.text('自动说明：只澄清本次操作'), findsOneWidget);
    expect(find.text('澄清'), findsOneWidget);
  });

  testWidgets(
    'lost save response retries the exact confirmation without replaying saved decisions',
    (tester) async {
      final fixture = _Fixture();
      await _selected(tester, fixture, generated: true);
      fixture.loseConfirmationResponse = true;
      final checksBefore = fixture.env.server
          .calls(
            'POST',
            '/v1/ai/recipes/modifications/$_modification/decisions',
          )
          .length;
      await _tap(tester, 'text-edit-confirm');
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/one-line');
      expect(
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .routeInformationProvider
            .value
            .uri
            .path,
        '/recipes/$_recipe',
      );
      final saves = fixture.env.server.calls(
        'POST',
        '/v1/ai/recipes/modifications/$_modification/confirm',
      );
      expect(saves, hasLength(2));
      expect(saves.last.body, saves.first.body);
      expect(
        fixture.env.server.calls(
          'POST',
          '/v1/ai/recipes/modifications/$_modification/decisions',
        ),
        hasLength(checksBefore),
      );
    },
  );

  testWidgets('newer invalid JSON survives an older delayed valid edit', (
    tester,
  ) async {
    final events = _SlowEvents();
    final fixture = _Fixture(events: events)..numeric = true;
    await _selected(tester, fixture);
    await _reveal(tester, 'text-edit-after-clarify');
    final gate = Completer<void>();
    events.gate = gate;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    await tester.enterText(
      find.byKey(const ValueKey('text-edit-after-clarify')),
      '200',
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('text-edit-after-clarify')),
      '不是数字',
    );
    await tester.pump(const Duration(milliseconds: 300));
    gate.complete();
    events.gate = null;
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('请输入有效的 JSON 数值。'), findsOneWidget);
    await _reveal(tester, 'text-edit-confirm');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNull,
    );
    await restartApp(tester, fixture.env);
    await _route(tester, '/recipes/$_recipe/edit');
    await _reveal(tester, 'text-edit-after-clarify');
    expect(find.text('不是数字'), findsOneWidget);
    expect(find.text('请输入有效的 JSON 数值。'), findsOneWidget);
    await _reveal(tester, 'text-edit-confirm');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'saved generated confirmation resumes cleanup after failed local removal',
    (tester) async {
      final local = _DelayedRemoveStore();
      final fixture = _Fixture(local: local);
      await _selected(tester, fixture, generated: true);
      local.failRemoval = true;
      await _tap(tester, 'text-edit-confirm');
      local.failRemoval = false;
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/one-line');
      expect(
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .routeInformationProvider
            .value
            .uri
            .path,
        '/recipes/$_recipe',
      );
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/one-line');
      expect(find.byKey(const ValueKey('text-edit-confirm')), findsNothing);
    },
  );

  testWidgets('late server check cannot replace a newer edited value', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _selected(tester, fixture);
    await _reveal(tester, 'text-edit-after-clarify');
    final gate = Completer<void>();
    fixture.checkGate = gate;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
    });
    await tester.enterText(
      find.byKey(const ValueKey('text-edit-after-clarify')),
      '较早后值',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(
      find.byKey(const ValueKey('text-edit-after-clarify')),
      '最新后值，中心达到 74°C。',
    );
    await tester.pump(const Duration(milliseconds: 300));
    gate.complete();
    await tester.pumpAndSettle();
    await _reveal(tester, 'text-edit-confirm');
    expect(find.text('待确认步骤 cook：较早后值'), findsNothing);
    expect(find.text('待确认步骤 cook：最新后值，中心达到 74°C。'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'discarding restored form also removes visible recovered modification confirmation',
    (tester) async {
      final fixture = _Fixture();
      await _selected(tester, fixture);
      await _reveal(tester, 'recipe-step-instruction-cook');
      await tester.enterText(
        find.byKey(const ValueKey('recipe-step-instruction-cook')),
        '作者另外手动修改',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/$_recipe/edit');
      expect(find.text('恢复未保存修改？'), findsOneWidget);
      await tester.tap(find.text('放弃草稿'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('text-edit-confirm')), findsNothing);
      expect(
        fixture.env.server.calls(
          'POST',
          '/v1/ai/recipes/modifications/$_modification/confirm',
        ),
        isEmpty,
      );
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/$_recipe/edit');
      expect(find.text('恢复未保存修改？'), findsNothing);
      expect(find.byKey(const ValueKey('text-edit-confirm')), findsNothing);
    },
  );

  testWidgets(
    'failed later proposal survives reopen; same counted request retries at quota zero',
    (tester) async {
      final fixture = _Fixture();
      await _selected(tester, fixture);
      await _reveal(tester, 'text-edit-input');
      await tester.enterText(
        find.byKey(const ValueKey('text-edit-input')),
        '再补一句步骤说明',
      );
      final quota = AIStatus(
        available: false,
        remaining: 0,
        reason: 'daily_quota',
      );
      fixture.env.server.on(
        'POST',
        '/v1/ai/recipes/modifications',
        (_) => (
          200,
          fixture.preview()
            ..['error'] = 'model_failure'
            ..['status'] = quota.toJson(),
        ),
      );
      fixture.env.server.on(
        'GET',
        '/v1/ai/recipes/modifications/status',
        (_) => (200, quota.toJson()),
      );
      await _tap(tester, 'text-edit-preview');
      final failedId =
          (fixture.env.server
                  .calls('POST', '/v1/ai/recipes/modifications')
                  .last
                  .body
              as Map)['request_id'];
      expect(find.text('本条处理：修改后值'), findsOneWidget);
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/$_recipe/edit');
      await _reveal(tester, 'text-edit-preview');
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('text-edit-preview')),
            )
            .onPressed,
        isNotNull,
      );
      await _tap(tester, 'text-edit-preview');
      final retry =
          fixture.env.server
                  .calls('POST', '/v1/ai/recipes/modifications')
                  .last
                  .body
              as Map;
      expect(retry['request_id'], failedId);
      expect(retry['retry_failed'], true);
      await _reveal(tester, 'text-edit-after-clarify');
      expect(find.text('我确认的文字：中心达到 74°C。'), findsOneWidget);
      await _tap(tester, 'text-edit-confirm');
      expect(
        fixture.env.server
            .calls(
              'POST',
              '/v1/ai/recipes/modifications/$_modification/confirm',
            )
            .length,
        1,
      );
    },
  );

  testWidgets(
    'failed confirmation and failed discard retain decisions for another reopen',
    (tester) async {
      final local = _DelayedRemoveStore();
      final fixture = _Fixture(local: local);
      await _selected(tester, fixture);
      fixture.failConfirmation = true;
      await _tap(tester, 'text-edit-confirm');
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/$_recipe/edit');
      await _reveal(tester, 'text-edit-after-clarify');
      expect(find.text('我确认的文字：中心达到 74°C。'), findsOneWidget);
      local.failRemoval = true;
      await _tap(tester, 'text-edit-cancel');
      await _reveal(tester, 'text-edit-error');
      expect(find.text('本机草稿清理失败，已保留修改，请重试。'), findsOneWidget);
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/$_recipe/edit');
      await _reveal(tester, 'text-edit-after-clarify');
      expect(find.text('我确认的文字：中心达到 74°C。'), findsOneWidget);
    },
  );

  testWidgets(
    'immutable baseline change never restores another version confirmation',
    (tester) async {
      final fixture = _Fixture();
      await _selected(tester, fixture);
      fixture.version = 'newer-baseline';
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/$_recipe/edit');
      expect(
        find.byKey(const ValueKey('text-edit-after-clarify')),
        findsNothing,
      );
      fixture.version = 'baseline';
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/$_recipe/edit');
      await _reveal(tester, 'text-edit-after-clarify');
      expect(find.text('我确认的文字：中心达到 74°C。'), findsOneWidget);
    },
  );

  testWidgets(
    'generated result and decisions do not cross signed-in accounts',
    (tester) async {
      final fixture = _Fixture();
      await _selected(tester, fixture, generated: true);
      fixture.env.server.user = testUser().copyWith(
        id: '99999999-9999-4999-8999-999999999999',
      );
      final other = TestEnv.signedIn(
        server: fixture.env.server,
        local: fixture.env.local,
      );
      await restartApp(tester, other);
      await _route(tester, '/recipes/one-line');
      expect(find.byKey(const ValueKey('text-edit-input')), findsNothing);
      fixture.env.server.user = testUser();
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/one-line');
      await _reveal(tester, 'text-edit-after-clarify');
      expect(find.text('我确认的文字：中心达到 74°C。'), findsOneWidget);
    },
  );

  testWidgets(
    'cancel waits for local cleanup and old callbacks cannot resurrect the draft',
    (tester) async {
      final local = _DelayedRemoveStore();
      final fixture = _Fixture(local: local);
      await _selected(tester, fixture);
      await _reveal(tester, 'text-edit-cancel');
      final gate = Completer<void>();
      local.gate = gate;
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      await tester.tap(find.byKey(const ValueKey('text-edit-cancel')));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      gate.complete();
      await tester.pumpAndSettle();
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/$_recipe/edit');
      expect(find.byKey(const ValueKey('text-edit-confirm')), findsNothing);
    },
  );

  testWidgets(
    'author explanation survives reopen and is submitted with checked modification',
    (tester) async {
      final fixture = _Fixture();
      await _selected(tester, fixture);
      await _reveal(tester, 'change-explanation-note');
      await tester.enterText(
        find.byKey(const ValueKey('change-explanation-note')),
        '作者确认：只把步骤说明写清楚',
      );
      await tester.enterText(
        find.byKey(const ValueKey('change-explanation-tags')),
        '文字澄清，保留原量',
      );
      await tester.pumpAndSettle();
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/$_recipe/edit');
      await _reveal(tester, 'change-explanation-note');
      expect(find.text('作者确认：只把步骤说明写清楚'), findsOneWidget);
      expect(find.text('文字澄清，保留原量'), findsOneWidget);
      await _tap(tester, 'text-edit-confirm');
      final body =
          fixture.env.server
                  .calls(
                    'POST',
                    '/v1/ai/recipes/modifications/$_modification/confirm',
                  )
                  .single
                  .body
              as Map;
      expect(body['change_note'], '作者确认：只把步骤说明写清楚');
      expect(body['tags'], ['文字澄清', '保留原量']);
      await _route(tester, '/recipes/$_recipe/edit');
      expect(find.byKey(const ValueKey('text-edit-confirm')), findsNothing);
    },
  );

  testWidgets(
    'numeric edited values stay JSON numbers; invalid JSON cannot confirm or dispatch',
    (tester) async {
      final fixture = _Fixture()..numeric = true;
      await pumpApp(tester, env: fixture.env);
      await _route(tester, '/recipes/$_recipe/edit');
      await tester.enterText(
        find.byKey(const ValueKey('text-edit-input')),
        '缩短步骤时间',
      );
      await _tap(tester, 'text-edit-preview');
      await _tap(tester, 'text-edit-modify-clarify');
      await _reveal(tester, 'text-edit-after-clarify');
      await tester.enterText(
        find.byKey(const ValueKey('text-edit-after-clarify')),
        '180',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      final path = '/v1/ai/recipes/modifications/$_modification/decisions';
      final submitted =
          (fixture.env.server.calls('POST', path).last.body as Map)['decisions']
              as List;
      expect(submitted.first['after'], 180);
      await _tap(tester, 'text-edit-reject-remind');
      await _reveal(tester, 'text-edit-after-clarify');
      final before = fixture.env.server.calls('POST', path).length;
      await tester.enterText(
        find.byKey(const ValueKey('text-edit-after-clarify')),
        '不是数字',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('请输入有效的 JSON 数值。'), findsOneWidget);
      expect(fixture.env.server.calls('POST', path).length, before);
      await _reveal(tester, 'text-edit-confirm');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('text-edit-confirm')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'generated entry reopens the same result and modification without another model call',
    (tester) async {
      final fixture = _Fixture();
      await _selected(tester, fixture, generated: true);
      await restartApp(tester, fixture.env);
      await _route(tester, '/recipes/one-line');
      await _reveal(tester, 'text-edit-after-clarify');
      expect(find.text('我确认的文字：中心达到 74°C。'), findsOneWidget);
      expect(find.text('本条处理：拒绝'), findsOneWidget);
      expect(
        fixture.env.server
            .calls('POST', '/v1/ai/recipes/requests/$_request/generate')
            .length,
        1,
      );
      expect(
        fixture.env.server.calls('POST', '/v1/ai/recipes/modifications').length,
        1,
      );
    },
  );

  testWidgets(
    'ordinary editor recovers choices and edited values; checks again before confirmation',
    (tester) async {
      final fixture = _Fixture();
      await _selected(tester, fixture);
      final before = fixture.env.server
          .calls(
            'POST',
            '/v1/ai/recipes/modifications/$_modification/decisions',
          )
          .length;
      // Rebuild the complete provider container with the same local storage.
      // This is the established restart seam, not a real OS process kill.
      await restartApp(tester, fixture.env);
      final gate = Completer<void>();
      fixture.checkGate = gate;
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      await _route(tester, '/recipes/$_recipe/edit', settle: false);
      expect(find.text('本条处理：修改后值'), findsOneWidget);
      await _reveal(tester, 'text-edit-confirm', settle: false);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('text-edit-confirm')),
            )
            .onPressed,
        isNull,
      );
      expect(
        fixture.env.server
            .calls(
              'POST',
              '/v1/ai/recipes/modifications/$_modification/decisions',
            )
            .length,
        before + 1,
      );
      gate.complete();
      await tester.pumpAndSettle();
      await _reveal(tester, 'text-edit-after-clarify');
      expect(find.text('我确认的文字：中心达到 74°C。'), findsOneWidget);
      expect(find.text('本条处理：拒绝'), findsOneWidget);
      await _reveal(tester, 'text-edit-confirm');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('text-edit-confirm')),
            )
            .onPressed,
        isNotNull,
      );
    },
  );
}
