import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';

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
  return env;
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

void main() {
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
