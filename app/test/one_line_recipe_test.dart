import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/fake_event_queue.dart';

import 'helpers.dart';

const _requestId = '11111111-1111-4111-8111-111111111111';
const _recipeId = '22222222-2222-4222-8222-222222222222';
const _text = '想做一道小朋友能吃的、不辣的宫保鸡丁';

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

RecipeSnapshot _snapshot() => RecipeSnapshot.fromJson({
  'format_version': 1,
  'servings': 2,
  'dish_type': '炒',
  'tags': ['不辣', '儿童'],
  'design_rationale': '不用辣椒；一般经验，需要实际做过验证。',
  'cuisine': '川菜',
  'ingredients': [
    {
      'id': 'chicken',
      'display_name': '鸡腿肉',
      'quantity': 300,
      'unit': 'g',
      'base_quantity': 300,
      'base_unit': 'g',
      'scaling_mode': 'proportional',
      'quantity_source': {'source': 'ai_estimated', 'basis': '一般经验'},
    },
  ],
  'steps': [
    {
      'id': 'cook',
      'instruction': '中火炒熟鸡肉，中心达到 74°C',
      'duration_seconds': 300,
      'ingredient_ids': ['chicken'],
      'heat': '中火',
      'cookware': '炒锅',
      'why': '充分加热降低食品安全风险',
      'depends_on': [],
    },
  ],
});

RecipeDetail _detail(RecipeSnapshot snapshot) => RecipeDetail(
  author: RecipeAuthor(id: testUser().id, nickname: testUser().nickname),
  createdAt: '2026-10-07T00:00:00+00:00',
  updatedAt: '2026-10-07T00:00:00+00:00',
  dish: DishOut(id: 'dish', name: '宫保鸡丁', aliases: []),
  id: _recipeId,
  visibility: RecipeDetailVisibilityEnum.private,
  version: RecipeVersionOut(
    aiAssisted: true,
    changeNote: 'AI 第一版',
    createdAt: '2026-10-07T00:00:00+00:00',
    derived: RecipeDerived(
      activeTimeSeconds: 300,
      totalTimeSeconds: 300,
      allergensIncomplete: true,
    ),
    editOperations: [],
    id: 'version',
    images: [],
    snapshot: snapshot,
    versionNumber: 1,
  ),
);

TestEnv _env({String? failure}) {
  final env = TestEnv.signedIn();
  final status = AIStatus(
    available: failure == null,
    remaining: failure == 'daily_quota' ? 0 : 50,
    reason: failure,
  );
  env.server.on('GET', '/v1/ai/recipes/status', (_) => (200, status.toJson()));
  env.server.on(
    'POST',
    '/v1/ai/recipes/requests',
    (_) => (
      200,
      RetrievalResult(
        intent: RecipeIntent(
          dishName: '宫保鸡丁',
          taste: ['不辣'],
          restrictions: ['儿童'],
        ),
        questions: [
          Question(key: QuestionKeyEnum.servings, text: '做几人份？', default_: '2'),
          Question(
            key: QuestionKeyEnum.cookware,
            text: '有什么厨具？',
            default_: '常用锅具',
          ),
        ],
        recipes: [],
        requestId: _requestId,
        status: status,
        text: _text,
      ).toJson(),
    ),
  );
  env.server.on(
    'POST',
    '/v1/ai/recipes/requests/$_requestId/generate',
    (_) => (
      200,
      GenerationResult(
        requestId: _requestId,
        status: status.copyWith(
          remaining: failure == null ? 49 : status.remaining,
        ),
        error: failure,
        safety: failure == null ? _safety() : null,
        draft: failure == null
            ? GeneratedDraft(
                cuisine: '川菜',
                rationale: '不用辣椒；一般经验，需要实际做过验证。',
                recipe: RecipeCreate(
                  dishName: '宫保鸡丁',
                  snapshot: _snapshot(),
                  aiAssisted: true,
                ),
              )
            : null,
        numericWarnings: failure == null ? ['用量是一般经验，请实际验证。'] : [],
      ).toJson(),
    ),
  );
  env.server.on(
    'POST',
    '/v1/recipes/safety/check',
    (_) => (200, RecipeSafetyCheckOut(result: _safety()).toJson()),
  );
  var saved = _snapshot();
  env.server.on('POST', '/v1/ai/recipes/requests/$_requestId/save', (r) {
    saved = RecipeCreate.fromJson(Map<String, dynamic>.from(r.body as Map))
        .snapshot;
    return (201, _detail(saved).toJson());
  });
  env.server.on(
    'GET',
    '/v1/recipes/$_recipeId',
    (_) => (200, _detail(saved).toJson()),
  );
  _installModificationApi(env);
  return env;
}

const _modificationId = '33333333-3333-4333-8333-333333333333';
const _modifyText = '把步骤说明写清楚，不改食材和用量';
const _clarified = '中火翻炒鸡肉，直到中心达到 74°C，盛出。';

void _installModificationApi(
  TestEnv env, {
  String? error,
  bool unavailable = false,
  bool failFirstDecision = false,
}) {
  final status = AIStatus(
    available: !unavailable,
    remaining: unavailable ? 0 : 48,
    reason: unavailable ? 'daily_quota' : null,
  );
  env.server.on(
    'GET',
    '/v1/ai/recipes/modifications/status',
    (_) => (200, status.toJson()),
  );
  var revision = 0;
  var snapshot = _snapshot();
  var decisions = <Map<String, dynamic>>[
    for (final id in ['clarify-cook', 'remind-cook', 'explain-cook'])
      {'operation_id': id, 'decision': 'pending', 'blocked_by': <String>[]},
  ];
  Map<String, dynamic> preview() => ModificationPreview.fromJson({
    'id': _modificationId,
    'revision': revision,
    'intent': {
      'category': 'text',
      'parameters': {'field': 'instruction'},
      'confidence': 0.95,
    },
    'operations': [
      for (final (id, field, before, after, dependencies) in [
        (
          'clarify-cook',
          'instruction',
          '中火炒熟鸡肉，中心达到 74°C',
          _clarified,
          <String>[],
        ),
        ('remind-cook', 'notes', null, '用温度计确认中心温度。', ['clarify-cook']),
        ('explain-cook', 'why', '充分加热降低食品安全风险', '充分加热降低食品安全风险。', <String>[]),
      ])
        {
          'operation_id': id,
          'type': 'change_step_field',
          'id': 'cook',
          'field': field,
          'before': before,
          'after': after,
          'scope': ['steps:cook'],
          'intent': _modifyText,
          'reason': '只澄清步骤文字，保留用量和时长',
          'risk': '仍需实际做过验证',
          'confidence': 0.95,
          'depends_on': dependencies,
        },
    ],
    'decisions': decisions,
    'snapshot': snapshot.toJson(),
    'safety': _safety()
        .copyWith(
          canSave: snapshot.steps!.first.instruction != '包治百病',
          prohibitedClaims: snapshot.steps!.first.instruction == '包治百病'
              ? ['包治百病']
              : [],
        )
        .toJson(),
    'reproducibility': {
      'rules_version': 'test-v1',
      'state': 'reproducible',
      'required_field_count': 1,
      'concrete_field_count': 1,
      'field_completeness': 1.0,
      'remaining_count': 0,
      'problems': [],
    },
    'status': status.toJson(),
    'warnings': [],
    'error': ?error,
  }).toJson();
  env.server.on(
    'POST',
    '/v1/ai/recipes/modifications',
    (_) => (200, preview()),
  );
  env.server.on(
    'POST',
    '/v1/ai/recipes/modifications/$_modificationId/decisions',
    (request) {
      if (failFirstDecision) {
        failFirstDecision = false;
        return FakeServer.error(503, 'temporarily_unavailable', '检查暂不可用，请重试');
      }
      final supplied = (request.body as Map)['decisions'] as List;
      decisions = [
        for (final id in ['clarify-cook', 'remind-cook', 'explain-cook'])
          {
            'operation_id': id,
            'decision': 'pending',
            'blocked_by': <String>[],
            ...?supplied.where((d) => d['operation_id'] == id).firstOrNull
                as Map?,
          },
      ];
      if (decisions.first['decision'] == 'reject') {
        decisions[1] = {
          'operation_id': 'remind-cook',
          'decision': 'reject',
          'blocked_by': ['clarify-cook'],
        };
      }
      final instruction = switch (decisions.first['decision']) {
        'accept' => _clarified,
        'modify' => decisions.first['after'] as String,
        _ => '中火炒熟鸡肉，中心达到 74°C',
      };
      snapshot = _snapshot().copyWith(
        steps: [_snapshot().steps!.first.copyWith(instruction: instruction)],
      );
      revision++;
      return (200, preview());
    },
  );
  env.server.on(
    'POST',
    '/v1/ai/recipes/modifications/$_modificationId/confirm',
    (_) {
      final saved = _detail(snapshot);
      env.server.on(
        'GET',
        '/v1/recipes/$_recipeId',
        (_) => (200, saved.toJson()),
      );
      return (201, saved.toJson());
    },
  );
}

Future<void> _reveal(WidgetTester tester, String key) async {
  final scrollable = find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .first;
  for (var i = 0; i < 12; i++) {
    await tester.drag(scrollable, const Offset(0, 500));
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
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String key) async {
  await _reveal(tester, key);
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<void> _preview(WidgetTester tester) async {
  await _reveal(tester, 'text-edit-input');
  await tester.enterText(
    find.byKey(const ValueKey('text-edit-input')),
    _modifyText,
  );
  await tester.pumpAndSettle();
  await _choose(tester, 'text-edit-preview');
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first,
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, TestEnv env) async {
  await pumpApp(tester, env: env);
  await tester.tap(find.byKey(const ValueKey('primary-create-button')));
  await tester.pumpAndSettle();
  await _tap(tester, 'one-line-recipe-entry');
  await tester.enterText(find.byKey(const ValueKey('one-line-input')), _text);
  await _tap(tester, 'one-line-search');
}

/// Simulates slow device persistence at the storage boundary, not an intent stub.
class _SlowLocalEvents extends FakeEventQueue {
  Completer<void>? write;
  bool delayOnlyNext = false;

  @override
  Future<void> enqueue(QueuedEvent event) async {
    final pending = write;
    if (delayOnlyNext) write = null;
    await pending?.future;
    await super.enqueue(event);
  }
}

void main() {
  testWidgets('读取修改额度失败可通过统一动作重试，原话保留', (tester) async {
    final env = _env();
    var first = true;
    env.server.on('GET', '/v1/ai/recipes/modifications/status', (_) {
      if (first) {
        first = false;
        return FakeServer.error(503, 'temporarily_unavailable', '暂不可用');
      }
      return (200, AIStatus(available: true, remaining: 47).toJson());
    });
    await _open(tester, env);
    await _tap(tester, 'ai-design-new');
    await _tap(tester, 'ai-skip-questions');
    await _reveal(tester, 'text-edit-retry-status');
    await _choose(tester, 'text-edit-retry-status');
    expect(find.text('今日修改剩余 47 次'), findsOneWidget);
    expect(find.byKey(const ValueKey('text-edit-error')), findsNothing);
    await _reveal(tester, 'text-edit-input');
    await tester.enterText(
      find.byKey(const ValueKey('text-edit-input')),
      _modifyText,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('text-edit-preview')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('更新选择检查失败可统一动作重试，不用旧检查确认', (tester) async {
    final env = _env();
    _installModificationApi(env, failFirstDecision: true);
    await _open(tester, env);
    await _tap(tester, 'ai-design-new');
    await _tap(tester, 'ai-skip-questions');
    await _preview(tester);
    await _choose(tester, 'text-edit-accept-clarify-cook');
    await _reveal(tester, 'text-edit-retry-checks');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNull,
    );
    await _choose(tester, 'text-edit-retry-checks');
    expect(find.text('待确认步骤 cook：$_clarified'), findsOneWidget);
    expect(find.byKey(const ValueKey('text-edit-retry-checks')), findsNothing);
    expect(find.byKey(const ValueKey('text-edit-error')), findsNothing);
  });

  testWidgets('依赖上游待处理时明确提示，先处理上游才可接受依赖项', (tester) async {
    final env = _env();
    await _open(tester, env);
    await _tap(tester, 'ai-design-new');
    await _tap(tester, 'ai-skip-questions');
    await _preview(tester);
    await _reveal(tester, 'text-edit-accept-remind-cook');
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('text-edit-accept-remind-cook')),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('上游操作尚待处理：clarify-cook；请先处理依赖。'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('text-edit-reject-remind-cook')),
          )
          .onPressed,
      isNotNull,
      reason: '拒绝无需先接受依赖',
    );
    await _choose(tester, 'text-edit-why-clarify-cook');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('why-panel')),
        matching: find.textContaining('把握程度：高'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('why-panel')),
        matching: find.textContaining('95%'),
      ),
      findsNothing,
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await _choose(tester, 'text-edit-accept-clarify-cook');
    await _reveal(tester, 'text-edit-accept-remind-cook');
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('text-edit-accept-remind-cook')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('后值一改就关闭确认，不等待本机事件写入才失效旧检查', (tester) async {
    final original = _env();
    final queue = _SlowLocalEvents();
    final env = TestEnv(
      server: original.server,
      local: original.local,
      secure: original.secure,
      eventQueue: queue,
    );
    await _open(tester, env);
    await _tap(tester, 'ai-design-new');
    await _tap(tester, 'ai-skip-questions');
    await _preview(tester);
    await _choose(tester, 'text-edit-modify-clarify-cook');
    await _choose(tester, 'text-edit-reject-remind-cook');
    await _choose(tester, 'text-edit-reject-explain-cook');
    await _reveal(tester, 'text-edit-after-clarify-cook');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNotNull,
    );
    final write = Completer<void>();
    queue.write = write;
    addTearDown(() {
      if (!write.isCompleted) write.complete();
    });
    await tester.enterText(
      find.byKey(const ValueKey('text-edit-after-clarify-cook')),
      '包治百病',
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNull,
      reason: '可见后值已改变，即使本机事件存储仍在等待',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('text-edit-input')))
          .enabled,
      isFalse,
      reason: '排队中的旧选择不能遇到替换后的新预览',
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('text-edit-preview')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('text-edit-cancel')))
          .onPressed,
      isNull,
    );
    write.complete();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await _reveal(tester, 'text-edit-confirm');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNull,
      reason: '新的安全检查不能允许宣称包治百病',
    );
  });

  testWidgets('连续修改后值按输入顺序生效，不被较慢的旧事件覆盖', (tester) async {
    final original = _env();
    final queue = _SlowLocalEvents();
    final env = TestEnv(
      server: original.server,
      local: original.local,
      secure: original.secure,
      eventQueue: queue,
    );
    await _open(tester, env);
    await _tap(tester, 'ai-design-new');
    await _tap(tester, 'ai-skip-questions');
    await _preview(tester);
    await _choose(tester, 'text-edit-modify-clarify-cook');
    await _choose(tester, 'text-edit-reject-remind-cook');
    await _choose(tester, 'text-edit-reject-explain-cook');
    await _reveal(tester, 'text-edit-after-clarify-cook');
    final firstWrite = Completer<void>();
    queue
      ..write = firstWrite
      ..delayOnlyNext = true;
    addTearDown(() {
      if (!firstWrite.isCompleted) firstWrite.complete();
    });
    await tester.enterText(
      find.byKey(const ValueKey('text-edit-after-clarify-cook')),
      '先前输入的安全文字',
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('text-edit-after-clarify-cook')),
      '包治百病',
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNull,
      reason: '较早的本机事件仍未落盘，不能确认',
    );
    firstWrite.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await _reveal(tester, 'text-edit-confirm');
    expect(find.text('待确认步骤 cook：先前输入的安全文字'), findsNothing);
    expect(find.text('待确认步骤 cook：包治百病'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNull,
      reason: '最终检查必须针对最新后值，而非较晚完成写入的旧值',
    );
  });

  testWidgets('生成结果逐条处理才确认，编辑后更新安全检查，保存后能查看', (tester) async {
    final env = _env();
    await _open(tester, env);
    await _tap(tester, 'ai-design-new');
    await _tap(tester, 'ai-skip-questions');
    await _preview(tester);
    await _reveal(tester, 'text-edit-confirm');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNull,
    );
    expect(
      env.server.calls(
        'POST',
        '/v1/ai/recipes/modifications/$_modificationId/confirm',
      ),
      isEmpty,
    );
    await _choose(tester, 'text-edit-modify-clarify-cook');
    await _reveal(tester, 'text-edit-after-clarify-cook');
    await tester.enterText(
      find.byKey(const ValueKey('text-edit-after-clarify-cook')),
      '包治百病',
    );
    await tester.pump();
    await _reveal(tester, 'text-edit-confirm');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNull,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await _choose(tester, 'text-edit-reject-remind-cook');
    await _choose(tester, 'text-edit-reject-explain-cook');
    await _reveal(tester, 'text-edit-confirm');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNull,
      reason: '安全检查禁止医疗宣称',
    );
    await _reveal(tester, 'text-edit-after-clarify-cook');
    await tester.enterText(
      find.byKey(const ValueKey('text-edit-after-clarify-cook')),
      '中火翻炒至鸡肉中心达到 74°C，再盛出。',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await _reveal(tester, 'text-edit-confirm');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNotNull,
    );
    expect(env.server.calls('POST', '/v1/recipes'), isEmpty);
    expect(
      env.server.calls('POST', '/v1/ai/recipes/requests/$_requestId/save'),
      isEmpty,
    );
    await _choose(tester, 'text-edit-confirm');
    expect(find.byKey(const ValueKey('recipe-detail-content')), findsOneWidget);
    await _reveal(tester, 'recipe-step-0');
    expect(find.textContaining('中火翻炒至鸡肉中心达到 74°C，再盛出。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('本人编辑页拒绝上游默认拒绝依赖，未处理项不应用，表单保存不偷用预览', (tester) async {
    final env = _env();
    await _open(tester, env);
    await _tap(tester, 'ai-design-new');
    await _tap(tester, 'ai-skip-questions');
    await _tap(tester, 'ai-edit-draft');
    await _reveal(tester, 'save-recipe-button');
    await _choose(tester, 'save-recipe-button');
    await _choose(tester, 'edit-recipe-button');
    expect(find.byKey(const ValueKey('text-edit-input')), findsOneWidget);
    await _preview(tester);
    await _choose(tester, 'text-edit-reject-clarify-cook');
    await _reveal(tester, 'text-edit-operation-remind-cook');
    expect(find.text('依赖被拒绝，已默认拒绝：clarify-cook'), findsOneWidget);
    await _reveal(tester, 'text-edit-confirm');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNull,
      reason: '独立操作还待处理',
    );
    await _choose(tester, 'text-edit-accept-explain-cook');
    await _reveal(tester, 'text-edit-confirm');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNotNull,
    );
    await _choose(tester, 'text-edit-cancel');
    expect(
      env.server.calls(
        'POST',
        '/v1/ai/recipes/modifications/$_modificationId/confirm',
      ),
      isEmpty,
    );
    await _reveal(tester, 'recipe-step-instruction-cook');
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('recipe-step-instruction-cook')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      '中火炒熟鸡肉，中心达到 74°C',
    );
    await tester.enterText(
      find.byKey(const ValueKey('recipe-step-instruction-cook')),
      '作者手动改文字',
    );
    await tester.pumpAndSettle();
    await _reveal(tester, 'text-edit-input');
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('text-edit-input')))
          .enabled,
      isFalse,
    );
    expect(find.text('当前有未保存的表单修改，请先手动保存，再请求文字修改。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final error in [
    'unsupported_intent',
    'uncertain_intent',
    'invalid_output',
  ]) {
    testWidgets('$error 原话保留并诚实提示，手动生成流程不受影响', (tester) async {
      final env = _env();
      _installModificationApi(env, error: error);
      await _open(tester, env);
      await _tap(tester, 'ai-design-new');
      await _tap(tester, 'ai-skip-questions');
      await _preview(tester);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('text-edit-input')))
            .controller!
            .text,
        _modifyText,
      );
      await _reveal(tester, 'text-edit-error');
      expect(find.byKey(const ValueKey('text-edit-error')), findsOneWidget);
      expect(find.byKey(const ValueKey('text-edit-confirm')), findsNothing);
      await _choose(tester, 'ai-edit-draft');
      expect(
        find.byKey(const ValueKey('recipe-editor-content')),
        findsOneWidget,
      );
    });
  }

  testWidgets('修改额度耗尽仍可走手动编辑保存', (tester) async {
    final env = _env();
    _installModificationApi(env, unavailable: true);
    await _open(tester, env);
    await _tap(tester, 'ai-design-new');
    await _tap(tester, 'ai-skip-questions');
    await _reveal(tester, 'text-edit-input');
    expect(find.text('今日修改剩余 0 次'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('text-edit-input')),
      _modifyText,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('text-edit-preview')),
          )
          .onPressed,
      isNull,
    );
    await _choose(tester, 'ai-edit-draft');
    expect(find.byKey(const ValueKey('recipe-editor-content')), findsOneWidget);
  });

  testWidgets('本人生成结果提供改文字入口，预览前不创建菜谱', (tester) async {
    final env = _env();
    await _open(tester, env);
    await _tap(tester, 'ai-design-new');
    await _tap(tester, 'ai-skip-questions');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('text-edit-input')),
      300,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(find.byKey(const ValueKey('text-edit-input')), findsOneWidget);
    expect(find.text('只支持改文字；其他修改暂未支持。确认前不会保存。'), findsOneWidget);
    expect(
      env.server.calls('POST', '/v1/ai/recipes/requests/$_requestId/save'),
      isEmpty,
    );
    expect(env.server.calls('POST', '/v1/recipes'), isEmpty);
  });

  testWidgets('先检索、显式选择新设计、跳过问题、显示依据、复用编辑器保存', (tester) async {
    final env = _env();
    await _open(tester, env);
    expect(find.text('今日生成剩余 50 次'), findsOneWidget);
    await _tap(tester, 'ai-design-new');
    expect(find.byKey(const ValueKey('ai-question-servings')), findsOneWidget);
    expect(find.byKey(const ValueKey('ai-question-cookware')), findsOneWidget);
    await _tap(tester, 'ai-skip-questions');
    await _tap(tester, 'ai-edit-draft');
    expect(find.text('AI 辅助 · 尚未做过验证'), findsOneWidget);
    expect(find.text('宫保鸡丁'), findsWidgets);
    final quantity = find.byKey(
      const ValueKey('recipe-ingredient-quantity-chicken'),
    );
    await tester.scrollUntilVisible(
      quantity,
      300,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.enterText(quantity, '320');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('save-recipe-button')),
      -300,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await _tap(tester, 'save-recipe-button');
    expect(find.byKey(const ValueKey('recipe-detail-content')), findsOneWidget);
    expect(find.text('AI 辅助 · 尚未做过验证'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final reason in [
    'daily_quota',
    'monthly_budget',
    'model_unavailable',
    'invalid_output',
  ]) {
    testWidgets('$reason 保留原话、可重试并能手动新建', (tester) async {
      await _open(tester, _env(failure: reason));
      await _tap(tester, 'ai-design-new');
      await _tap(tester, 'ai-skip-questions');
      expect(find.byKey(const ValueKey('ai-error')), findsOneWidget);
      await _tap(tester, 'ai-retry');
      await _tap(tester, 'ai-manual-fallback');
      expect(
        find.byKey(const ValueKey('recipe-editor-content')),
        findsOneWidget,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('one-line-input'));
      await tester.scrollUntilVisible(
        input,
        -300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      expect(tester.widget<TextField>(input).controller!.text, _text);
      expect(tester.takeException(), isNull);
    });
  }
}
