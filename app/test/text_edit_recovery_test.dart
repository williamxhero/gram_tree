import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';

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
  final env = TestEnv.signedIn();
  String version = 'baseline';
  bool failProposal = false;
  bool failConfirmation = false;
  Completer<void>? checkGate;
  List<Map<String, dynamic>> decisions = [];
  int revision = 0;

  _Fixture() {
    final status = AIStatus(available: true, remaining: 48);
    env.server.on('GET', '/v1/ai/recipes/status', (_) => (200, status.toJson()));
    env.server.on('POST', '/v1/ai/recipes/requests', (_) => (200,
      RetrievalResult(intent: RecipeIntent(dishName: '炒鸡肉'), questions: [],
        recipes: [], requestId: _request, status: status, text: '炒鸡肉').toJson()));
    env.server.on('POST', '/v1/ai/recipes/requests/$_request/generate', (_) => (200,
      GenerationResult(requestId: _request, status: status, safety: _safety(),
        draft: GeneratedDraft(cuisine: '家常', rationale: '一般经验',
          recipe: RecipeCreate(dishName: '炒鸡肉', snapshot: _snapshot(), aiAssisted: true))).toJson()));
    env.server.on(
      'GET',
      '/v1/recipes/$_recipe',
      (_) => (200, _detail(version: version).toJson()),
    );
    env.server.on(
      'GET',
      '/v1/ai/recipes/modifications/status',
      (_) => (200, status.toJson()),
    );
    env.server.on('POST', '/v1/ai/recipes/modifications', (_) {
      if (failProposal) return FakeServer.error(503, 'unavailable', '模型请求超时');
      return (200, preview());
    });
    env.server.on(
      'POST',
      '/v1/ai/recipes/modifications/$_modification/decisions',
      (r) async {
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
      (_) {
        if (failConfirmation)
          return FakeServer.error(503, 'unavailable', '保存失败');
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
        ('clarify', 'instruction', '翻炒至中心达到 74°C。', <String>[]),
        ('remind', 'notes', '温度计测量中心。', ['clarify']),
      ])
        {
          'operation_id': id,
          'type': 'change_step_field',
          'id': 'cook',
          'field': field,
          'before': field == 'instruction' ? _instruction : null,
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
    'snapshot': _snapshot(
      decisions
                  .where((d) => d['operation_id'] == 'clarify')
                  .firstOrNull?['after']
              as String? ??
          _instruction,
    ).toJson(),
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

Future<void> _route(WidgetTester tester, String path, {bool settle = true}) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
}

Future<void> _reveal(WidgetTester tester, String key, {bool settle = true}) async {
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

Future<void> _selected(WidgetTester tester, _Fixture fixture, {bool generated = false}) async {
  await pumpApp(tester, env: fixture.env);
  await _route(tester, generated ? '/recipes/one-line' : '/recipes/$_recipe/edit');
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
    '我确认的文字：中心达到 74°C。',
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
  await _tap(tester, 'text-edit-reject-remind');
}

void main() {
  testWidgets('generated entry reopens the same result and modification without another model call', (tester) async {
    final fixture = _Fixture();
    await _selected(tester, fixture, generated: true);
    await restartApp(tester, fixture.env);
    await _route(tester, '/recipes/one-line');
    await _reveal(tester, 'text-edit-after-clarify');
    expect(find.text('我确认的文字：中心达到 74°C。'), findsOneWidget);
    expect(find.text('本条处理：拒绝'), findsOneWidget);
    expect(fixture.env.server.calls('POST', '/v1/ai/recipes/requests/$_request/generate').length, 1);
    expect(fixture.env.server.calls('POST', '/v1/ai/recipes/modifications').length, 1);
  });

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
