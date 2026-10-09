import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

const recipeId = '11111111-1111-4111-8111-111111111111';
const versionId = '22222222-2222-4222-8222-222222222222';
const question = '鸡肉为什么要炒熟？';
const answerPath = '/v1/ai/recipes/$recipeId/versions/$versionId/answer';

RecipeSafetyResult safety() => RecipeSafetyResult(
  allergens: [],
  allergensIncomplete: true,
  canSave: true,
  checkedAt: '2026-10-08T00:00:00+00:00',
  findings: [
    RecipeSafetyFinding(
      basis: '食品安全规则',
      message: '鸡肉表面变白不代表中心熟透，中心温度需达到 74°C。',
      ruleId: 'poultry-cook-through',
      severity: RecipeSafetyFindingSeverityEnum.warning,
    ),
  ],
  highRisk: false,
  prohibitedClaims: [],
  replacementAllergens: [],
  rulesVersion: 'safety-v1',
);

RecipeDetail detail() => RecipeDetail(
  author: RecipeAuthor(id: testUser().id, nickname: testUser().nickname),
  createdAt: '2026-10-08T00:00:00+00:00',
  updatedAt: '2026-10-08T00:00:00+00:00',
  dish: DishOut(id: 'dish', name: '宫保鸡丁', aliases: []),
  id: recipeId,
  visibility: RecipeDetailVisibilityEnum.private,
  version: RecipeVersionOut(
    aiAssisted: false,
    changeNote: '手动确认版',
    createdAt: '2026-10-08T00:00:00+00:00',
    derived: RecipeDerived(activeTimeSeconds: 120, totalTimeSeconds: 120),
    editOperations: [],
    id: versionId,
    images: [],
    safety: safety(),
    snapshot: RecipeSnapshot.fromJson({
      'format_version': 1,
      'servings': 2,
      'ingredients': [
        {'id': 'chicken', 'display_name': '鸡腿肉', 'quantity': 320, 'unit': 'g'},
      ],
      'steps': [
        {'id': 'cook', 'instruction': '鸡肉炒至表面变白', 'duration_seconds': 120},
      ],
    }),
    versionNumber: 1,
  ),
);

RecipeAnswer answer({
  RecipeAnswerStateEnum state = RecipeAnswerStateEnum.answered,
}) => RecipeAnswer(
  basis: RecipeAnswerBasisEnum.generalExperience,
  capability: RecipeAnswerCapabilityEnum.explain,
  conclusion: state == RecipeAnswerStateEnum.answered
      ? '这版只写表面变白，不能判断中心熟透。'
      : '无法从这个版本可靠确定。',
  details: '解释不自动修改菜谱。',
  explanation: '用食品温度计检查鸡肉中心达到 74°C。',
  error: state == RecipeAnswerStateEnum.unavailable ? 'monthly_budget' : null,
  question: question,
  recipeId: recipeId,
  safety: safety(),
  source_: RecipeAnswerSource_Enum.aiEstimated,
  state: state,
  status: AIStatus(
    available: state != RecipeAnswerStateEnum.unavailable,
    remaining: 49,
  ),
  versionId: versionId,
);

TestEnv env() {
  final result = TestEnv.signedIn();
  result.server.on(
    'GET',
    '/v1/recipes',
    (_) => (
      200,
      RecipeList(
        items: [
          RecipeListItem(
            activeTimeSeconds: 120,
            dish: detail().dish,
            id: recipeId,
            servings: 2,
            totalTimeSeconds: 120,
            updatedAt: detail().updatedAt,
            versionNumber: 1,
            visibility: RecipeListItemVisibilityEnum.private,
          ),
        ],
      ).toJson(),
    ),
  );
  result.server.on(
    'GET',
    '/v1/recipes/$recipeId',
    (_) => (200, detail().toJson()),
  );
  result.server.on('POST', answerPath, (_) => (200, answer().toJson()));
  return result;
}

Future<void> tap(WidgetTester tester, String key, {double delta = 300}) async {
  final finder = find.byKey(ValueKey(key));
  tester.testTextInput.hide();
  await tester.pump();
  if (finder.evaluate().isEmpty) {
    final scrollable = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    await tester.drag(scrollable, const Offset(0, 10000));
    await tester.pumpAndSettle();
  }
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  expect(
    finder.hitTestable(),
    findsOneWidget,
    reason: '$key must be reachable before tapping',
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
  if (key == 'recipe-answer-submit') {
    final panel = find.byKey(const ValueKey('recipe-answer-why'));
    for (var i = 0; i < 50 && panel.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(
      panel,
      findsOneWidget,
      reason: 'Submission must finish opening its panel',
    );
  }
}

Future<void> open(
  WidgetTester tester,
  TestEnv environment, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Size size = const Size(360, 780),
}) async {
  await pumpApp(
    tester,
    env: environment,
    brightness: brightness,
    textScale: textScale,
    size: size,
  );
  await tester.tap(find.byKey(const ValueKey('primary-create-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('my-recipes-entry')));
  await tester.pumpAndSettle();
  final card = find.byKey(const ValueKey('recipe-card-$recipeId'));
  for (var i = 0; i < 20 && card.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(
    card,
    findsOneWidget,
    reason: tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .join('|'),
  );
  await tester.tap(card);
  for (
    var i = 0;
    i < 20 &&
        find.byKey(const ValueKey('recipe-detail-content')).evaluate().isEmpty;
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.byKey(const ValueKey('recipe-detail-content')), findsOneWidget);
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.3, 1.6]) {
      testWidgets('320x640 $brightness $scale 长解释可滚动关闭且保留问题与原始用量', (
        tester,
      ) async {
        final environment = env();
        final longAnswer = answer().copyWith(
          details:
              '${List.filled(45, '逐步核对这版的食材和火候，不把推测作为结论。').join('\n')}\nLONG_ANSWER_END',
        );
        environment.server.on(
          'POST',
          answerPath,
          (_) => (200, longAnswer.toJson()),
        );
        await open(
          tester,
          environment,
          brightness: brightness,
          textScale: scale,
          size: const Size(320, 640),
        );
        await tap(tester, 'recipe-answer-input');
        await tester.enterText(
          find.byKey(const ValueKey('recipe-answer-input')),
          question,
        );
        await tap(tester, 'recipe-answer-submit');
        final close = find.byKey(const ValueKey('recipe-answer-close'));
        expect(close.hitTestable(), findsOneWidget);
        expect(find.text('已回答 · 一般经验'), findsOneWidget);
        final panel = find.byKey(const ValueKey('recipe-answer-why'));
        final scrollable = find
            .ancestor(of: panel, matching: find.byType(Scrollable))
            .first;
        await tester.drag(scrollable, const Offset(0, -10000));
        await tester.pumpAndSettle();
        final body = find.descendant(
          of: panel,
          matching: find.textContaining('LONG_ANSWER_END'),
        );
        expect(body, findsOneWidget);
        expect(
          tester.getBottomLeft(body).dy,
          lessThanOrEqualTo(tester.getRect(scrollable).bottom + 1),
        );
        expect(close.hitTestable(), findsOneWidget);
        await tester.tap(close);
        await tester.pumpAndSettle();
        await tap(tester, 'recipe-serving-increase');
        expect(find.text('3'), findsWidgets);
        await tap(tester, 'recipe-answer-input');
        expect(find.text(question), findsOneWidget);
        await tap(tester, 'edit-recipe-button');
        final quantity = find.byKey(
          const ValueKey('recipe-ingredient-quantity-chicken'),
        );
        await tester.scrollUntilVisible(
          quantity,
          200,
          scrollable: find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .first,
        );
        await tester.ensureVisible(quantity);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: quantity,
            matching: find.textContaining(RegExp(r'^320(?:\.0)?$')),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('按钮和键盘提交同一意图，打开及重开面板只记录来源元数据', (tester) async {
    final environment = env();
    await open(tester, environment);
    for (final keyboard in [false, true]) {
      await tap(tester, 'recipe-answer-input');
      await tester.enterText(
        find.byKey(const ValueKey('recipe-answer-input')),
        question,
      );
      if (keyboard) {
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      } else {
        await tap(tester, 'recipe-answer-submit');
      }
      expect(find.byKey(const ValueKey('recipe-answer-why')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('recipe-answer-close')));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('为什么 · 明细'));
    await tester.tap(find.text('为什么 · 明细'));
    await tester.pumpAndSettle();
    final events = environment.server
        .calls('POST', '/v1/sync/writes')
        .expand((r) => ((r.body as Map)['writes'] as List).cast<Map>())
        .map((write) {
          expect(write['write_type'], 'experience.event');
          expect(write['owner_id'], environment.server.user.id);
          return write['payload'] as Map;
        })
        .toList();
    final actions = events
        .where(
          (e) =>
              e['event_type'] == 'ui.component_action' &&
              (e['content'] as Map)['component_id'] == 'recipe-answer',
        )
        .toList();
    expect(actions, hasLength(2));
    for (final event in actions) {
      expect(event['content'], {
        'component_id': 'recipe-answer',
        'intent': 'call_operation',
      });
    }
    final opened = events
        .where(
          (e) =>
              e['event_type'] == 'ui.why_panel_opened' &&
              (e['content'] as Map)['component_id'] == 'recipe-answer',
        )
        .toList();
    expect(opened, hasLength(3));
    for (final event in opened) {
      expect(event['content'], {
        'component_id': 'recipe-answer',
        'source_type': 'ai_estimated',
      });
    }
    expect(events.toString(), isNot(contains(question)));
    expect(events.toString(), isNot(contains(answer().conclusion)));
    expect(environment.server.calls('POST', answerPath), hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('回答安全信息不完整时仍显示版本必显警告', (tester) async {
    final environment = env();
    environment.server.on(
      'POST',
      answerPath,
      (_) => (
        200,
        answer()
            .copyWith(
              safety: safety().copyWith(
                findings: [],
                allergensIncomplete: false,
              ),
            )
            .toJson(),
      ),
    );
    await open(tester, environment);
    await tap(tester, 'recipe-answer-input');
    await tester.enterText(
      find.byKey(const ValueKey('recipe-answer-input')),
      question,
    );
    await tap(tester, 'recipe-answer-submit');
    final panel = find.byKey(const ValueKey('recipe-answer-why'));
    expect(
      find.descendant(of: panel, matching: find.textContaining('中心温度需达到 74°C')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: panel, matching: find.textContaining('过敏信息可能不完整')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('长版本滚回规则换算再返回时仍保留问题', (tester) async {
    final environment = env();
    final base = detail();
    final longVersion = base.copyWith(
      version: base.version.copyWith(
        snapshot: base.version.snapshot.copyWith(
          steps: [
            for (var i = 0; i < 30; i++)
              RecipeStep(
                id: 'cook-$i',
                instruction: '第 $i 步：鸡肉炒熟并检查中心温度。',
                durationSeconds: 120,
              ),
          ],
        ),
      ),
    );
    environment.server.on(
      'GET',
      '/v1/recipes/$recipeId',
      (_) => (200, longVersion.toJson()),
    );
    await open(tester, environment);
    await tap(tester, 'recipe-answer-input');
    await tester.enterText(
      find.byKey(const ValueKey('recipe-answer-input')),
      question,
    );
    await tap(tester, 'recipe-answer-submit');
    await tester.tap(find.byKey(const ValueKey('recipe-answer-close')));
    await tester.pumpAndSettle();
    // Browse the trailing steps well beyond the lazy viewport/cache, then return.
    await tester.drag(
      find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
      const Offset(0, -10000),
    );
    await tester.pumpAndSettle();
    await tap(tester, 'recipe-serving-increase');
    expect(find.text('3'), findsWidgets);
    await tap(tester, 'recipe-answer-input');
    expect(find.text(question), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('网络失败保留问题、安全和 AI 来源，不泄露内部错误', (tester) async {
    final environment = env();
    environment.server.on(
      'POST',
      answerPath,
      (_) => FakeServer.error(
        503,
        'internal_failure',
        'PRIVATE_MODEL_LOG_DO_NOT_DISPLAY',
      ),
    );
    await open(tester, environment);
    await tap(tester, 'recipe-answer-input');
    await tester.enterText(
      find.byKey(const ValueKey('recipe-answer-input')),
      question,
    );
    await tap(tester, 'recipe-answer-submit');
    expect(find.text('能力不可用 · 一般经验'), findsOneWidget);
    expect(find.text('AI 估算 · 菜谱解释'), findsOneWidget);
    expect(find.textContaining('中心温度需达到 74°C'), findsOneWidget);
    expect(find.textContaining('PRIVATE_MODEL_LOG'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('recipe-answer-close')));
    await tester.pumpAndSettle();
    expect(find.text(question), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('回答版本不匹配时不展示其他版本的解释，保留问题', (tester) async {
    final environment = env();
    environment.server.on(
      'POST',
      answerPath,
      (_) => (
        200,
        {
          ...answer().toJson(),
          'version_id': '33333333-3333-4333-8333-333333333333',
          'conclusion': '其他版本的解释，不应出现',
        },
      ),
    );
    await open(tester, environment);
    await tap(tester, 'recipe-answer-input');
    await tester.enterText(
      find.byKey(const ValueKey('recipe-answer-input')),
      question,
    );
    await tap(tester, 'recipe-answer-submit');
    expect(find.text('能力不可用 · 一般经验'), findsOneWidget);
    expect(find.textContaining('其他版本的解释'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('recipe-answer-close')));
    await tester.pumpAndSettle();
    expect(find.text(question), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('版本厨房问题显示一般经验为什么面板，关闭仍保留问题与规则换算', (tester) async {
    final environment = env();
    await open(tester, environment);
    await tap(tester, 'recipe-answer-input');
    await tester.enterText(
      find.byKey(const ValueKey('recipe-answer-input')),
      question,
    );
    await tap(tester, 'recipe-answer-submit');
    expect(find.byKey(const ValueKey('recipe-answer-why')), findsOneWidget);
    expect(find.text('已回答 · 一般经验'), findsOneWidget);
    expect(find.textContaining('这是一般经验，还没有足够记录验证'), findsWidgets);
    expect(find.textContaining('解释不自动修改菜谱'), findsOneWidget);
    expect(find.textContaining('中心温度需达到 74°C'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('recipe-answer-close')));
    await tester.pumpAndSettle();
    expect(find.text(question), findsOneWidget);
    await tap(tester, 'recipe-serving-increase');
    expect(find.text('3'), findsWidgets);
    await tap(tester, 'recipe-answer-input');
    expect(find.text(question), findsOneWidget);
    expect(environment.server.calls('POST', answerPath).length, 1);
    final request = environment.server.calls('POST', answerPath).single;
    expect(request.body, {'question': question});
    expect(tester.takeException(), isNull);
  });

  for (final state in [
    RecipeAnswerStateEnum.uncertain,
    RecipeAnswerStateEnum.cannotAnswer,
    RecipeAnswerStateEnum.unavailable,
  ]) {
    testWidgets('回答状态 $state 不隐藏安全信息，不改输入，可重试恢复', (tester) async {
      final environment = env();
      environment.server.on(
        'POST',
        answerPath,
        (_) => (200, answer(state: state).toJson()),
      );
      await open(tester, environment);
      await tap(tester, 'recipe-answer-input');
      await tester.enterText(
        find.byKey(const ValueKey('recipe-answer-input')),
        question,
      );
      await tap(tester, 'recipe-answer-submit');
      expect(find.byKey(const ValueKey('recipe-answer-why')), findsOneWidget);
      expect(find.textContaining('中心温度需达到 74°C'), findsOneWidget);
      if (state == RecipeAnswerStateEnum.unavailable) {
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('recipe-answer-why')),
            matching: find.textContaining('月预算'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('查看、表单编辑和规则换算仍可使用'), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('recipe-answer-close')));
      await tester.pumpAndSettle();
      expect(find.text(question), findsOneWidget);
      environment.server.on(
        'POST',
        answerPath,
        (_) => (200, answer().toJson()),
      );
      await tap(tester, 'recipe-answer-submit');
      expect(find.text('已回答 · 一般经验'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('recipe-answer-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('edit-recipe-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('recipe-editor-content')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
