import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/router.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/features/recipes/full_comparison_page.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gram_tree/ui_protocol/components/component_scaffold.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

const recipe = '11111111-1111-4111-8111-111111111111';
const versionA = '22222222-2222-4222-8222-222222222222';
const versionB = '33333333-3333-4333-8333-333333333333';
const editBase = '44444444-4444-4444-8444-444444444444';

RecipeIngredient ingredient(String id, String name, num quantity) =>
    RecipeIngredient(
      id: id,
      displayName: name,
      quantity: quantity,
      unit: 'g',
      baseQuantity: quantity,
      baseUnit: RecipeIngredientBaseUnitEnum.g,
      preparation: '切小块',
      group: '调味料',
      optional: false,
      scalingMode: RecipeIngredientScalingModeEnum.proportional,
      flavorContribution: RecipeFlavorContribution(salty: 0, umami: 2),
      flavorSource: ValueSource(
        source_: ValueSourceSource_Enum.authorFilled,
        basis: '本菜谱味型原始依据',
      ),
      functional: true,
      functionalSource: ValueSource(
        source_: ValueSourceSource_Enum.authorFilled,
        basis: '原始功能依据',
      ),
    );

RecipeStep step(String id, String text, int duration) => RecipeStep(
  id: id,
  action: '炒',
  instruction: text,
  durationSeconds: duration,
  ingredientIds: ['salt'],
  heat: '中火',
  temperatureCelsius: 160,
  cookware: '炒锅',
  doneness: '中心无粉红',
  unattended: false,
  dependsOn: id == 'cook' ? ['prepare'] : [],
  notes: '不要堆叠',
  why: '保持锅温',
  durationSource: ValueSource(
    source_: ValueSourceSource_Enum.aiEstimated,
    basis: '保存的时长估算依据',
  ),
);

RecipeDetail detail(String version, int number) => RecipeDetail(
  id: recipe,
  author: RecipeAuthor(id: 'author', nickname: '作者'),
  dish: DishOut(id: 'dish', name: '完整对比菜', aliases: []),
  visibility: RecipeDetailVisibilityEnum.private,
  createdAt: '2026-10-01T00:00:00Z',
  updatedAt: '2026-10-02T00:00:00Z',
  version: RecipeVersionOut(
    id: version,
    versionNumber: number,
    aiAssisted: false,
    changeNote: '保存原文',
    createdAt: '2026-10-02T00:00:00Z',
    editOperations: [],
    images: [],
    derived: RecipeDerived(activeTimeSeconds: 120, totalTimeSeconds: 180),
    conclusion: number == 1 ? null : RecipeVersionOutConclusionEnum.significant,
    rulesVersion: number == 1 ? null : 'rules-test-1',
    snapshot: RecipeSnapshot(
      formatVersion: RecipeSnapshotFormatVersionEnum.number1,
      servings: number == 1 ? 2 : 4,
      description: '双方原始说明',
      ingredients: [
        ingredient('salt', '盐', number == 1 ? 3 : 7.2),
        ingredient('water', '水', number == 1 ? 100 : 200),
      ],
      steps: [
        step('prepare', '先备料', 20),
        step('cook', '分批炒鸡肉', number == 1 ? 120 : 132),
      ],
    ),
  ),
);

Map<String, dynamic> change({
  required String kind,
  required String field,
  required Object? before,
  required Object? after,
  required String grade,
  String basis = '服务端变化依据',
  double? relative,
  String? unit,
}) => {
  'kind': kind,
  'field': field,
  'before': before,
  'after': after,
  'grade': grade,
  'basis': basis,
  'rule_id': 'rule.$field',
  'rules_version': 'rules-test-1',
  'relative_change': ?relative,
  'unit': ?unit,
};

RecipeFullComparison fixture() => RecipeFullComparison.fromJson({
  'scope': 'full',
  'conclusion': 'significant',
  'rules_version': 'rules-test-1',
  'basis': ['厨具变化是决定性差异', '不会把多个微调叠加成显著'],
  'normalized_servings': 2,
  'from_version': ComparisonVersion(
    recipeId: recipe,
    versionId: versionA,
    versionNumber: 1,
    author: '作者',
    dishName: '完整对比菜',
    servings: 2,
  ).toJson(),
  'to_version': ComparisonVersion(
    recipeId: recipe,
    versionId: versionB,
    versionNumber: 2,
    author: '作者',
    dishName: '完整对比菜',
    servings: 4,
  ).toJson(),
  'ingredients': [
    {
      'before': ingredient('salt', '盐', 3).toJson(),
      'after': ingredient('salt', '盐', 7.2).toJson()..['base_quantity'] = 3.6,
      'pairing': 'stable_id',
      'changes': [
        change(
          kind: 'quantity',
          field: 'base_quantity',
          before: 3,
          after: 3.6,
          relative: .2,
          unit: 'g',
          grade: 'general',
          basis: '用量按 A 人份归一比较',
        ),
      ],
    },
    {
      'before': ingredient('water', '水', 100).toJson(),
      'after': ingredient('water', '水', 200).toJson()..['base_quantity'] = 100,
      'pairing': 'stable_id',
      'changes': [],
    },
  ],
  'steps': [
    {
      'before': step('prepare', '先备料', 20).toJson(),
      'after': step('prepare', '先备料', 20).toJson(),
      'before_index': 1,
      'after_index': 1,
      'alignment': 'deterministic',
      'confidence': 1,
      'basis': '稳定步骤身份',
      'changes': [],
    },
    {
      'before': step('cook', '分批炒鸡肉', 120).toJson(),
      'after': step('cook', '分批炒鸡肉', 132).toJson(),
      'before_index': 2,
      'after_index': 2,
      'alignment': 'deterministic',
      'confidence': .9,
      'basis': '引用与依赖锚点',
      'changes': [
        change(
          kind: 'field',
          field: 'duration_seconds',
          before: 120,
          after: 132,
          relative: .1,
          unit: 's',
          grade: 'minor',
          basis: '时长改变低于一般阈值',
        ),
        change(
          kind: 'text',
          field: 'instruction',
          before: '炒熟',
          after: '分批炒鸡肉',
          grade: 'excluded',
          basis: '纯措辞不计配方幅度',
        ),
        change(
          kind: 'order',
          field: 'depends_on',
          before: ['prepare'],
          after: [],
          grade: 'general',
          basis: '前置依赖改变',
        ),
      ],
    },
    {
      'before': step('old', '不确定原步骤', 60).toJson(),
      'before_index': 3,
      'alignment': 'uncertain',
      'confidence': .4,
      'basis': '候选不能可靠唯一匹配',
      'changes': [
        change(
          kind: 'removed',
          field: 'step',
          before: '不确定原步骤',
          after: null,
          grade: 'general',
        ),
      ],
    },
    {
      'after': step('new', '不确定新步骤', 60).toJson(),
      'after_index': 3,
      'alignment': 'uncertain',
      'confidence': .4,
      'basis': '候选不能可靠唯一匹配',
      'changes': [
        change(
          kind: 'added',
          field: 'step',
          before: null,
          after: '不确定新步骤',
          grade: 'general',
        ),
      ],
    },
  ],
  'method_changes': [
    change(
      kind: 'field',
      field: 'cookware',
      before: '炒锅',
      after: '高压锅',
      grade: 'significant',
      basis: '厨具变化是决定性差异',
    ),
  ],
  'snapshot_fields': [
    change(
      kind: 'text',
      field: 'description',
      before: '旧说明',
      after: '新说明',
      grade: 'excluded',
    ),
  ],
});

RecipeComparisonAssistance assistanceFixture() => RecipeComparisonAssistance(
  fromVersionId: versionA,
  toVersionId: versionB,
  rulesVersion: 'rules-test-1',
  status: RecipeComparisonAssistanceStatusEnum.ready,
  alignments: [
    AssistedStepPair(
      beforeStepId: 'old',
      afterStepId: 'new',
      alignment: AssistedStepPairAlignmentEnum.aiAssisted,
      confidence: .95,
      sourceType: AssistedStepPairSourceTypeEnum.aiEstimated,
      basis: SourceBasis(
        reasonCode: 'general_experience',
        text: '仅辅助展示不确定步骤，不改变确定规则的新增删除。',
      ),
    ),
  ],
  interpretation: SourcedValue(
    value: '两版都炒熟，后一版分成两步，更适合分批操作。',
    sourceType: SourcedValueSourceTypeEnum.aiEstimated,
    basis: SourceBasis(
      reasonCode: 'general_experience',
      text: '仅依据有权读取的版本差异，属于一般经验。',
    ),
  ),
);

FakeServer serverForComparison({
  bool failFirst = false,
  String toRecipe = recipe,
  RecipeComparisonAssistance? assistance,
}) {
  final server = FakeServer();
  var attempts = 0;
  server.on('GET', '/v1/recipes/$recipe/full-comparison', (request) {
    attempts++;
    if (failFirst && attempts == 1) {
      return FakeServer.error(503, 'unavailable', '稍后重试');
    }
    if (request.query['from_version_id'] != versionA ||
        request.query['to_version_id'] != versionB) {
      return FakeServer.error(422, 'invalid_request', '方向错误');
    }
    final data = fixture().toJson();
    (data['to_version'] as Map<String, dynamic>)['recipe_id'] = toRecipe;
    return (200, RecipeFullComparison.fromJson(data).toJson());
  });
  server.on('GET', '/v1/recipes/$recipe/comparison-assistance', (request) {
    if (request.query['from_version_id'] != versionA ||
        request.query['to_version_id'] != versionB) {
      return FakeServer.error(422, 'invalid_request', '辅助比较方向错误');
    }
    return (
      200,
      (assistance ??
              RecipeComparisonAssistance(
                fromVersionId: versionA,
                toVersionId: versionB,
                rulesVersion: 'rules-test-1',
                status: RecipeComparisonAssistanceStatusEnum.unavailable,
                reasonCode: 'model_unavailable',
              ))
          .toJson(),
    );
  });
  for (final (version, number) in [(versionA, 1), (versionB, 2)]) {
    server.on(
      'GET',
      '/v1/recipes/${number == 1 ? recipe : toRecipe}/versions/$version',
      (_) {
        final saved = detail(version, number).toJson();
        if (assistance != null) {
          final snapshot =
              (saved['version'] as Map<String, dynamic>)['snapshot']
                  as Map<String, dynamic>;
          (snapshot['steps'] as List).add(
            step(
              number == 1 ? 'old' : 'new',
              number == 1 ? '不确定原步骤' : '不确定新步骤',
              60,
            ).toJson(),
          );
        }
        return (200, RecipeDetail.fromJson(saved).toJson());
      },
    );
  }
  return server;
}

Future<void> openComparison(WidgetTester tester, FakeServer server) async {
  await pumpApp(tester, env: TestEnv.signedIn(server: server));
  ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
      .read(routerProvider)
      .push('/recipes/$recipe/full-compare?from=$versionA&to=$versionB');
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  final body = find.byKey(const ValueKey('full-comparison-content'));
  if (finder.evaluate().isEmpty) {
    for (var i = 0; i < 20; i++) {
      await tester.drag(body, const Offset(0, 1000));
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < 60 && finder.evaluate().isEmpty; i++) {
      await tester.drag(body, const Offset(0, -350));
      await tester.pumpAndSettle();
    }
  }
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, String filter, String label) async {
  await tap(tester, find.byKey(ValueKey('full-compare-$filter-filter')));
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

class _AssistanceTransportFailure extends FakeServer {
  _AssistanceTransportFailure(this.delegate, this.failure);
  final FakeServer delegate;
  final DioExceptionType failure;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.uri.path.endsWith('/comparison-assistance')) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: failure,
          message: '合成辅助请求传输故障',
        ),
      );
      return;
    }
    await delegate.onRequest(options, handler);
  }
}

Future<void> expectUnassistedOriginals(WidgetTester tester) async {
  await reveal(tester, find.text('显著改动'));
  expect(find.text('显著改动'), findsOneWidget);
  expect(
    find.byKey(const ValueKey('comparison-assistance-unavailable')),
    findsOneWidget,
  );
  expect(find.text('AI 辅助对齐'), findsNothing);
  expect(find.text('AI · 一般经验'), findsNothing);
  expect(find.text('两版都炒熟，后一版分成两步，更适合分批操作。'), findsNothing);
  expect(find.textContaining('未能对齐 · 双方原文保留'), findsOneWidget);
  await tap(tester, find.byKey(const ValueKey('full-compare-expand-all')));
  for (final id in ['old', 'new']) {
    await reveal(tester, find.text('步骤 ID：$id'));
    expect(find.text('步骤 ID：$id'), findsOneWidget);
    expect(find.text('幅度：一般'), findsWidgets);
  }
  expect(tester.takeException(), isNull);
}

void main() {
  for (final reason in [
    'low_confidence',
    'model_unavailable',
    'replay_miss',
    'budget_exhausted',
  ]) {
    testWidgets('辅助 $reason 不伪造结果；确定结论与双方完整原文仍可用', (tester) async {
      final assistance = RecipeComparisonAssistance.fromJson({
        ...assistanceFixture().toJson(),
        'status': 'unavailable',
        'alignments': [],
        'interpretation': null,
        'reason_code': reason,
      });
      await openComparison(tester, serverForComparison(assistance: assistance));
      await expectUnassistedOriginals(tester);
    });
  }

  final valid = assistanceFixture().toJson();
  final validPair =
      (valid['alignments'] as List).single as Map<String, dynamic>;
  for (final entry in <String, Map<String, dynamic>>{
    '反向起点': {'from_version_id': versionB},
    '反向终点': {'to_version_id': versionA},
    '过期规则': {'rules_version': 'expired-rules'},
    '越权前步骤': {
      'alignments': [
        {...validPair, 'before_step_id': 'foreign-before'},
      ],
    },
    '越权后步骤': {
      'alignments': [
        {...validPair, 'after_step_id': 'foreign-after'},
      ],
    },
    '确定步骤不可交给 AI': {
      'alignments': [
        {...validPair, 'before_step_id': 'cook'},
      ],
    },
    '冲突对法': {
      'alignments': [validPair, validPair],
    },
    '把握超出上界': {
      'alignments': [
        {...validPair, 'confidence': 1.1},
      ],
    },
    '把握超出下界': {
      'alignments': [
        {...validPair, 'confidence': -0.1},
      ],
    },
    '不能冒充已验证': {
      'interpretation': {
        ...(valid['interpretation'] as Map<String, dynamic>),
        'source_type': 'verified',
      },
    },
    '不能引用个人经验': {
      'interpretation': {
        ...(valid['interpretation'] as Map<String, dynamic>),
        'basis': {'reason_code': 'personal_feedback', 'text': '不可使用的个人经验'},
      },
    },
  }.entries) {
    testWidgets('拒绝${entry.key}辅助展示，原始规则和字段不变', (tester) async {
      final assistance = RecipeComparisonAssistance.fromJson({
        ...valid,
        ...entry.value,
      });
      await openComparison(tester, serverForComparison(assistance: assistance));
      await expectUnassistedOriginals(tester);
    });
  }

  testWidgets('未能对齐的 unpaired 步骤不是可辅助的 uncertain 池', (tester) async {
    final server = serverForComparison(assistance: assistanceFixture());
    final comparison = fixture().toJson();
    ((comparison['steps'] as List)[2] as Map<String, dynamic>)['alignment'] =
        'unpaired';
    server.on(
      'GET',
      '/v1/recipes/$recipe/full-comparison',
      (_) => (200, comparison),
    );
    await openComparison(tester, server);
    await expectUnassistedOriginals(tester);
  });

  for (final entry in <String, Map<String, dynamic>>{
    '格式错误': {
      'alignments': [
        {'before_step_id': 'old'},
      ],
    },
    '来源非法': {
      'alignments': [
        {...validPair, 'source_type': 'verified'},
      ],
    },
  }.entries) {
    testWidgets('辅助${entry.key}反序列化失败不阻塞完整对比', (tester) async {
      final server = serverForComparison(assistance: assistanceFixture());
      server.on(
        'GET',
        '/v1/recipes/$recipe/comparison-assistance',
        (_) => (200, {...valid, ...entry.value}),
      );
      await openComparison(tester, server);
      await expectUnassistedOriginals(tester);
    });
  }

  for (final failure in [
    DioExceptionType.connectionError,
    DioExceptionType.receiveTimeout,
  ]) {
    testWidgets('辅助 $failure 与确定对比加载、原始明细隔离', (tester) async {
      final server = _AssistanceTransportFailure(
        serverForComparison(assistance: assistanceFixture()),
        failure,
      );
      await openComparison(tester, server);
      await expectUnassistedOriginals(tester);
    });
  }

  testWidgets('服务端已接受的把握值原样展示，客户端不另设阈值', (tester) async {
    final assistance = RecipeComparisonAssistance.fromJson({
      ...valid,
      'alignments': [
        {...validPair, 'confidence': .25},
      ],
    });
    await openComparison(tester, serverForComparison(assistance: assistance));
    expect(find.text('把握程度：25%'), findsOneWidget);
    expect(find.text('AI 辅助对齐'), findsOneWidget);
    expect(find.text('显著改动'), findsOneWidget);
  });

  testWidgets('辅助请求未完成时仍能筛选确定差异；失败后完整比较保持可用', (tester) async {
    final pending = Completer<(int, Object?)>();
    final server = serverForComparison(assistance: assistanceFixture());
    server.on(
      'GET',
      '/v1/recipes/$recipe/comparison-assistance',
      (_) => pending.future,
    );
    await openComparison(tester, server);
    expect(
      find.byKey(const ValueKey('comparison-assistance-loading')),
      findsOneWidget,
    );
    expect(find.text('显著改动'), findsOneWidget);
    await choose(tester, 'grade', '一般');
    await reveal(tester, find.text('幅度：一般'));
    expect(find.text('幅度：一般'), findsWidgets);
    pending.complete(FakeServer.error(503, 'unavailable', '辅助不可用'));
    await tester.pumpAndSettle();
    await choose(tester, 'grade', '全部幅度');
    await reveal(
      tester,
      find.byKey(const ValueKey('comparison-assistance-unavailable')),
    );
    await expectUnassistedOriginals(tester);
  });

  testWidgets('两种 AI 对法只改变辅助伙伴，不改变逐条等级、规则结论或保存的历史标签', (tester) async {
    for (final afterId in ['new', 'alternate']) {
      final assistance = RecipeComparisonAssistance.fromJson({
        ...valid,
        'alignments': [
          {...validPair, 'after_step_id': afterId},
        ],
      });
      final server = serverForComparison(assistance: assistance);
      final comparison = fixture().toJson();
      (comparison['steps'] as List).add({
        'after': step('alternate', '另一个不确定新步骤', 60).toJson(),
        'after_index': 4,
        'alignment': 'uncertain',
        'confidence': .4,
        'basis': '两个候选不能唯一匹配',
        'changes': [
          change(
            kind: 'added',
            field: 'step',
            before: null,
            after: '另一个不确定新步骤',
            grade: 'general',
          ),
        ],
      });
      server.on(
        'GET',
        '/v1/recipes/$recipe/full-comparison',
        (_) => (200, RecipeFullComparison.fromJson(comparison).toJson()),
      );
      final savedB = detail(versionB, 2).toJson();
      final snapshot =
          (savedB['version'] as Map<String, dynamic>)['snapshot']
              as Map<String, dynamic>;
      (snapshot['steps'] as List).addAll(<Map<String, dynamic>>[
        step('new', '不确定新步骤', 60).toJson(),
        step('alternate', '另一个不确定新步骤', 60).toJson(),
      ]);
      server.on(
        'GET',
        '/v1/recipes/$recipe/versions/$versionB',
        (_) => (200, RecipeDetail.fromJson(savedB).toJson()),
      );
      await openComparison(tester, server);
      expect(find.text('显著改动'), findsOneWidget);
      expect(
        find.text('AI 辅助展示 · A 第 3 步 → B 第 ${afterId == 'new' ? 3 : 4} 步'),
        findsOneWidget,
      );
      await tap(tester, find.byKey(const ValueKey('full-compare-expand-all')));
      for (final index in [2, 3, 4]) {
        final marker = find.byKey(ValueKey('comparison-why-step-$index-step'));
        await reveal(tester, marker);
        final card = find.ancestor(
          of: marker,
          matching: find.byType(ComponentCard),
        );
        expect(
          find.descendant(of: card, matching: find.text('幅度：一般')),
          findsOneWidget,
        );
      }
      await choose(tester, 'grade', '一般');
      expect(find.text('AI 辅助对齐'), findsNothing);
      await reveal(
        tester,
        find.byKey(const ValueKey('comparison-why-step-2-step')),
      );
      expect(find.text('幅度：一般'), findsWidgets);
      await tap(tester, find.byKey(const ValueKey('full-compare-detail-b')));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('recipe-version-conclusion')),
          matching: find.textContaining('显著改动'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('高把握 AI 辅助是独立展示，原始字段与确定规则新增删除仍完整可见', (tester) async {
    await openComparison(
      tester,
      serverForComparison(assistance: assistanceFixture()),
    );
    expect(find.text('显著改动'), findsOneWidget);
    expect(find.text('两版都炒熟，后一版分成两步，更适合分批操作。'), findsOneWidget);
    expect(find.text('AI · 一般经验'), findsOneWidget);
    await tap(
      tester,
      find.byKey(const ValueKey('comparison-assistance-why-0')),
    );
    expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
    expect(find.text('AI 辅助对齐依据'), findsOneWidget);
    expect(find.textContaining('把握程度：95%'), findsWidgets);
    expect(find.textContaining('不改变确定规则的新增删除'), findsOneWidget);
    expect(find.text('这次不用'), findsNothing);
    expect(find.text('以后别这样'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('full-compare-expand-all')));
    final pair = find.byKey(const ValueKey('comparison-assistance-pair-0'));
    for (final text in ['步骤 ID：old', '步骤 ID：new', '成熟判断：中心无粉红']) {
      final raw = find.descendant(of: pair, matching: find.text(text));
      await reveal(tester, raw);
      expect(raw, findsWidgets);
    }
    for (final id in ['step-2-step', 'step-3-step']) {
      await reveal(tester, find.byKey(ValueKey('comparison-why-$id')));
      expect(find.text('幅度：一般'), findsWidgets);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('完整对比保留 A→B、归一、确定规则结论和只读决定性依据', (tester) async {
    await openComparison(tester, serverForComparison());
    expect(find.text('显著改动'), findsOneWidget);
    expect(find.text('已按 2 人份对比'), findsOneWidget);
    expect(find.textContaining('不依赖 AI'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('full-comparison-why')));
    expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
    expect(find.textContaining('厨具变化是决定性差异'), findsOneWidget);
    expect(find.textContaining('rules-test-1'), findsWidgets);
    expect(find.text('这次不用'), findsNothing);
    expect(find.text('以后别这样'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('幅度/类型筛选、全部内容与原始明细保留未归一 B 数值和味型', (tester) async {
    await openComparison(tester, serverForComparison());
    await choose(tester, 'section', '食材');
    await choose(tester, 'grade', '一般');
    await reveal(tester, find.text('幅度：一般'));
    expect(find.text('相对变化：+20.0%'), findsOneWidget);
    expect(find.text('水'), findsNothing);
    await choose(tester, 'grade', '全部幅度');
    await tap(tester, find.byKey(const ValueKey('full-compare-show-all')));
    await tap(tester, find.byKey(const ValueKey('full-compare-expand-all')));
    await reveal(tester, find.textContaining('7.2 g'));
    expect(find.textContaining('7.2 g'), findsWidgets);
    expect(find.textContaining('咸 0'), findsWidgets);
    expect(find.textContaining('鲜 2'), findsWidgets);
    await reveal(tester, find.text('水'));
    expect(find.text('水 · 原始保存用量 200 g'), findsOneWidget);
    expect(find.text('未变化'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('步骤时长 field 百分比、措辞排除、依赖变化和不确定双方原文可追溯', (tester) async {
    await openComparison(tester, serverForComparison());
    await choose(tester, 'section', '步骤');
    await tap(tester, find.byKey(const ValueKey('full-compare-expand-all')));
    await reveal(tester, find.text('相对变化：+10.0%'));
    expect(find.text('幅度：微调'), findsOneWidget);
    await reveal(tester, find.textContaining('需要守着'));
    expect(find.textContaining('第 1 步'), findsWidgets);
    await reveal(tester, find.text('幅度：不计配方幅度'));
    await reveal(tester, find.textContaining('顺序变化'));
    await reveal(tester, find.text('不确定原步骤'));
    await reveal(tester, find.text('不确定新步骤'));
    expect(find.textContaining('对齐不确定'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI 辅助按步骤、幅度和类型筛选隐藏及恢复，不把辅助配对伪装成规则变化', (tester) async {
    await openComparison(
      tester,
      serverForComparison(assistance: assistanceFixture()),
    );
    const pairKey = ValueKey('comparison-assistance-pair-0');
    await reveal(tester, find.byKey(pairKey));
    expect(find.text('AI 辅助对齐'), findsOneWidget);
    await choose(tester, 'section', '食材');
    expect(find.byKey(pairKey), findsNothing);
    await reveal(tester, find.text('AI · 一般经验'));
    expect(find.text('AI · 一般经验'), findsOneWidget);
    await reveal(tester, find.text('显著改动'));
    expect(find.text('显著改动'), findsOneWidget);
    await choose(tester, 'section', '步骤');
    await reveal(tester, find.byKey(pairKey));
    expect(find.text('AI 辅助对齐'), findsOneWidget);
    await choose(tester, 'grade', '一般');
    expect(find.byKey(pairKey), findsNothing);
    await reveal(
      tester,
      find.byKey(const ValueKey('comparison-why-step-2-step')),
    );
    expect(find.text('幅度：一般'), findsWidgets);
    await choose(tester, 'grade', '全部幅度');
    await choose(tester, 'kind', '文字修改');
    expect(find.byKey(pairKey), findsNothing);
    await reveal(tester, find.text('幅度：不计配方幅度'));
    await choose(tester, 'kind', '全部类型');
    await reveal(tester, find.byKey(pairKey));
    expect(find.text('把握程度：95%'), findsOneWidget);
    await reveal(tester, find.text('显著改动'));
    expect(find.text('显著改动'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('变更类型筛选可仅显示措辞修改，排除用量、执行和新增删除', (tester) async {
    await openComparison(tester, serverForComparison());
    await choose(tester, 'section', '步骤');
    await choose(tester, 'kind', '文字修改');
    await reveal(tester, find.text('幅度：不计配方幅度'));
    expect(find.text('幅度：微调'), findsNothing);
    expect(find.text('不确定原步骤'), findsNothing);
    expect(find.text('不确定新步骤'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('新增量具食材只展示确认依据，新增载荷里的签名回执不出现在比较和原始明细', (tester) async {
    final server = serverForComparison();
    final measured = RecipeIngredient(
      id: 'measured',
      displayName: '量具盐',
      quantity: 3,
      unit: 'g',
      baseQuantity: 3,
      baseUnit: RecipeIngredientBaseUnitEnum.g,
      measureInputToken: 'signed-transport-fixture',
      quantitySource: ValueSource(
        source_: ValueSourceSource_Enum.authorFilled,
        original: '小勺 1 平勺',
        basis: '已确认小勺输入依据',
      ),
    );
    final data = fixture().toJson();
    data['ingredients'] = [
      GradedIngredientComparisonRow(
        after: measured,
        pairing: GradedIngredientComparisonRowPairingEnum.unpaired,
        changes: [
          GradedComparisonChange(
            kind: GradedComparisonChangeKindEnum.added,
            field: 'ingredient',
            after: measured.toJson(),
            grade: GradedComparisonChangeGradeEnum.general,
            basis: '新增食材',
            ruleId: 'added',
            rulesVersion: 'rules-test-1',
          ),
        ],
      ).toJson(),
    ];
    server.on(
      'GET',
      '/v1/recipes/$recipe/full-comparison',
      (_) => (200, RecipeFullComparison.fromJson(data).toJson()),
    );
    final saved = detail(versionB, 2).toJson();
    (saved['version'] as Map<String, dynamic>)['snapshot'] = RecipeSnapshot(
      formatVersion: RecipeSnapshotFormatVersionEnum.number1,
      servings: 4,
      ingredients: [measured],
      steps: [],
    ).toJson();
    server.on(
      'GET',
      '/v1/recipes/$recipe/versions/$versionB',
      (_) => (200, RecipeDetail.fromJson(saved).toJson()),
    );
    await openComparison(tester, server);
    await choose(tester, 'section', '食材');
    await tap(tester, find.byKey(const ValueKey('full-compare-expand-all')));
    await reveal(tester, find.text('量具输入依据'));
    expect(find.textContaining('signed-transport-fixture'), findsNothing);
    await tap(tester, find.text('量具输入依据'));
    expect(find.text('已确认小勺输入依据'), findsOneWidget);
    expect(find.textContaining('小勺 1 平勺'), findsWidgets);
    expect(find.textContaining('signed-transport-fixture'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A 详情经真实历史入口重新完整比较，B 保存结论打开历史且详情仍返回食谱列表', (tester) async {
    final server = serverForComparison(assistance: assistanceFixture());
    final current = detail(versionB, 2);
    server.on(
      'GET',
      '/v1/recipes',
      (_) => (
        200,
        RecipeList(
          items: [
            RecipeListItem(
              activeTimeSeconds: current.version.derived.activeTimeSeconds,
              dish: current.dish,
              id: current.id,
              servings: current.version.snapshot.servings,
              totalTimeSeconds: current.version.derived.totalTimeSeconds,
              updatedAt: current.updatedAt,
              versionNumber: current.version.versionNumber,
              visibility: RecipeListItemVisibilityEnum.private,
            ),
          ],
        ).toJson(),
      ),
    );
    server.on(
      'GET',
      '/v1/recipes/$recipe/versions',
      (_) => (
        200,
        RecipeVersionHistory(
          items: [
            RecipeVersionSummary(
              id: versionB,
              versionNumber: 2,
              previousVersionId: versionA,
              conclusion: RecipeVersionSummaryConclusionEnum.significant,
              rulesVersion: 'rules-test-1',
              aiAssisted: false,
              changeNote: '第二版',
              createdAt: '2026-10-02T00:00:00Z',
            ),
            RecipeVersionSummary(
              id: versionA,
              versionNumber: 1,
              aiAssisted: false,
              changeNote: '首版',
              createdAt: '2026-10-01T00:00:00Z',
            ),
          ],
        ).toJson(),
      ),
    );
    await openComparison(tester, server);
    await tap(tester, find.byKey(const ValueKey('full-compare-detail-a')));
    expect(find.byKey(const ValueKey('recipe-detail-content')), findsOneWidget);
    expect(find.byKey(const ValueKey('recipe-list-button')), findsOneWidget);
    expect(find.byTooltip('返回'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('recipe-history-button')));
    await tester.pumpAndSettle();
    expect(find.text('显著改动 · 对比上一版本'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('recipe-full-compare-previous-2')),
    );
    await tester.pumpAndSettle();
    expect(find.text('显著改动'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('full-compare-detail-b')));
    final saved = find.byKey(const ValueKey('recipe-version-conclusion'));
    expect(
      find.descendant(of: saved, matching: find.textContaining('显著改动')),
      findsOneWidget,
    );
    await tester.ensureVisible(saved);
    await tester.tap(saved);
    await tester.pumpAndSettle();
    expect(find.text('显著改动 · 对比上一版本'), findsOneWidget);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recipe-detail-content')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('recipe-list-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('new-recipe-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('full-comparison-content')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final side in ['a', 'b']) {
    testWidgets('完整比较可打开 $side 原始版本详情与保存结论', (tester) async {
      await openComparison(tester, serverForComparison());
      await tap(tester, find.byKey(ValueKey('full-compare-detail-$side')));
      expect(
        find.byKey(const ValueKey('recipe-detail-content')),
        findsOneWidget,
      );
      expect(find.textContaining('完整对比菜'), findsWidgets);
      expect(
        find.byKey(const ValueKey('recipe-version-conclusion')),
        side == 'b' ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('完整比较失败后重试，不依赖 AI 请求', (tester) async {
    await openComparison(tester, serverForComparison(failFirst: true));
    expect(find.byKey(const ValueKey('full-comparison-content')), findsNothing);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('显著改动'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('分页选择同菜的独立菜谱版本进入完整对比，保持点击方向及双方详情归属', (tester) async {
    const otherRecipe = '55555555-5555-4555-8555-555555555555';
    final server = serverForComparison(toRecipe: otherRecipe);
    server.on(
      'GET',
      '/v1/recipes/$recipe/versions',
      (_) => (
        200,
        RecipeVersionHistory(
          items: [
            RecipeVersionSummary(
              id: versionA,
              versionNumber: 1,
              aiAssisted: false,
              changeNote: '首版',
              createdAt: '2026-10-01T00:00:00Z',
            ),
          ],
        ).toJson(),
      ),
    );
    server.on('GET', '/v1/recipes/$recipe/comparison-candidates', (request) {
      final firstPage = request.query['cursor'] == null;
      return (
        200,
        RecipeComparisonCandidates(
          items: [
            RecipeComparisonCandidate(
              id: firstPage ? versionA : versionB,
              recipeId: firstPage ? recipe : otherRecipe,
              author: '作者',
              versionNumber: firstPage ? 1 : 2,
              aiAssisted: false,
              changeNote: firstPage ? '原版候选' : '独立菜谱候选',
              createdAt: '2026-10-01T00:00:00Z',
            ),
          ],
          nextCursor: firstPage ? 'next-page' : null,
        ).toJson(),
      );
    });
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
        .read(routerProvider)
        .push('/recipes/$recipe/history');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipe-select-comparison')));
    await tester.pumpAndSettle();
    final fullAction = find.byKey(
      const ValueKey('recipe-full-compare-selected'),
    );
    expect(tester.widget<OutlinedButton>(fullAction).onPressed, isNull);
    await tester.tap(
      find.byKey(const ValueKey('recipe-candidate-select-$versionA')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipe-history-load-more')));
    await tester.pumpAndSettle();
    expect(find.textContaining('独立菜谱候选'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('recipe-candidate-select-$versionB')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(fullAction);
    await tester.tap(fullAction);
    await tester.pumpAndSettle();
    expect(find.text('显著改动'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('full-compare-detail-b')));
    expect(find.byKey(const ValueKey('recipe-detail-content')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('历史结论相对实际上一版，区别编辑基线，首版无虚构结论；旧入口保留', (tester) async {
    final server = serverForComparison();
    server.on(
      'GET',
      '/v1/recipes/$recipe/versions',
      (_) => (
        200,
        RecipeVersionHistory(
          items: [
            RecipeVersionSummary(
              id: versionB,
              versionNumber: 2,
              previousVersionId: versionA,
              baseVersionId: editBase,
              conclusion: RecipeVersionSummaryConclusionEnum.significant,
              rulesVersion: 'rules-test-1',
              aiAssisted: false,
              changeNote: '从旧基线编辑',
              createdAt: '2026-10-02T00:00:00Z',
            ),
            RecipeVersionSummary(
              id: versionA,
              versionNumber: 1,
              aiAssisted: false,
              changeNote: '首版',
              createdAt: '2026-10-01T00:00:00Z',
            ),
          ],
        ).toJson(),
      ),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
        .read(routerProvider)
        .push('/recipes/$recipe/history');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('recipe-compare-previous-2')),
      findsOneWidget,
    );
    expect(find.textContaining('显著改动 · 对比上一版本'), findsOneWidget);
    expect(find.textContaining('编辑基线不同于上一当前版本'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('recipe-full-compare-previous-1')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey('recipe-full-compare-previous-2')),
    );
    await tester.pumpAndSettle();
    expect(find.text('显著改动'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    for (final size in const [Size(360, 780), Size(900, 480)]) {
      for (final scale in [1.3, 1.6]) {
        testWidgets('完整页 $brightness $size 字号 $scale 布局与展开无溢出', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final env = TestEnv.signedIn(server: serverForComparison());
          await tester.pumpWidget(
            ProviderScope(
              overrides: env.overrides,
              child: MaterialApp(
                theme: buildTheme(brightness),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const FullComparisonPage(
                  recipeId: recipe,
                  fromVersionId: versionA,
                  toVersionId: versionB,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final a = tester.getTopLeft(
            find.byKey(const ValueKey('full-compare-version-a')),
          );
          final b = tester.getTopLeft(
            find.byKey(const ValueKey('full-compare-version-b')),
          );
          if (size.width >= 600) {
            expect(a.dy, b.dy);
            expect(b.dx, greaterThan(a.dx));
          } else {
            expect(b.dy, greaterThan(a.dy));
          }
          await tap(tester, find.byKey(const ValueKey('full-compare-stacked')));
          await choose(tester, 'section', '食材');
          await tap(
            tester,
            find.byKey(const ValueKey('full-compare-expand-all')),
          );
          await reveal(tester, find.textContaining('7.2 g'));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
