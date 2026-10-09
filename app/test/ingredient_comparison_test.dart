import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

const recipeId = '11111111-1111-4111-8111-111111111111';
const versionA = '22222222-2222-4222-8222-222222222222';
const versionB = '33333333-3333-4333-8333-333333333333';

RecipeIngredient _ingredient(String id, String name, num quantity) =>
    RecipeIngredient(
      id: id,
      displayName: name,
      quantity: quantity,
      unit: 'g',
      baseQuantity: quantity,
      baseUnit: RecipeIngredientBaseUnitEnum.g,
    );

RecipeIngredientComparison comparisonFixture() => RecipeIngredientComparison(
  scope: RecipeIngredientComparisonScopeEnum.ingredients,
  fromVersion: ComparisonVersion(
    recipeId: recipeId,
    versionId: versionA,
    versionNumber: 1,
    author: '作者',
    dishName: '比较菜',
    servings: 2,
  ),
  toVersion: ComparisonVersion(
    recipeId: recipeId,
    versionId: versionB,
    versionNumber: 2,
    author: '作者',
    dishName: '比较菜',
    servings: 4,
  ),
  normalizedServings: 2,
  ingredients: [
    IngredientComparisonRow(
      before: _ingredient('salt', '盐', 3),
      after: _ingredient('salt', '盐', 2),
      pairing: IngredientComparisonRowPairingEnum.stableId,
      changes: [
        ComparisonChange(
          kind: ComparisonChangeKindEnum.quantity,
          field: 'base_quantity',
          before: 3,
          after: 2,
          relativeChange: -1 / 3,
          unit: 'g',
          basis: '按保存的基础量比较',
        ),
      ],
    ),
    IngredientComparisonRow(
      before: _ingredient('water', '水', 100),
      after: _ingredient('water', '水', 100),
      pairing: IngredientComparisonRowPairingEnum.stableId,
      changes: [],
    ),
  ],
  snapshotFields: [],
);

RecipeDetail detailFixture(String version, int number) => RecipeDetail(
  author: RecipeAuthor(id: 'author', nickname: '作者'),
  createdAt: '2026-10-01T00:00:00Z',
  updatedAt: '2026-10-01T00:00:00Z',
  dish: DishOut(id: 'dish', name: '比较菜', aliases: []),
  id: recipeId,
  visibility: RecipeDetailVisibilityEnum.private,
  version: RecipeVersionOut(
    id: version,
    versionNumber: number,
    aiAssisted: false,
    changeNote: '比较版本',
    createdAt: '2026-10-01T00:00:00Z',
    editOperations: [],
    images: [],
    derived: RecipeDerived(activeTimeSeconds: 0, totalTimeSeconds: 0),
    snapshot: RecipeSnapshot(
      servings: 2,
      formatVersion: RecipeSnapshotFormatVersionEnum.number1,
      ingredients: [_ingredient('salt', '盐', number == 1 ? 3 : 2)],
      steps: [],
    ),
  ),
);

void main() {
  for (final kind in ['unit', 'unchanged', 'added', 'removed']) {
    testWidgets('未知基础量保留原始用量和单位且不显示百分比 $kind', (tester) async {
      final server = FakeServer();
      final before = RecipeIngredient(
        id: 'water',
        displayName: '水',
        quantity: 1,
        unit: '碗',
      );
      final after = RecipeIngredient(
        id: 'water',
        displayName: '水',
        quantity: kind == 'unchanged' ? 1 : 2,
        unit: '碗',
      );
      final data = comparisonFixture().toJson();
      data['ingredients'] = [
        {
          'before': kind == 'added' ? null : before.toJson(),
          'after': kind == 'removed' ? null : after.toJson(),
          'pairing': 'stable_id',
          'changes': kind == 'unchanged'
              ? []
              : [
                  {
                    'kind': kind,
                    'field': kind == 'unit' ? 'quantity_unit' : 'ingredient',
                    'before': {'quantity': 1, 'unit': '碗'},
                    'after': {'quantity': 2, 'unit': '碗'},
                    'basis': '基础量未知，保留原始用量；不能可靠归一或换算',
                  },
                ],
        },
      ];
      server.on('GET', '/v1/recipes/$recipeId/compare', (_) => (200, data));
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
          .read(routerProvider)
          .push('/recipes/$recipeId/compare?from=$versionA&to=$versionB');
      await tester.pumpAndSettle();
      if (kind == 'unchanged') {
        await tester.tap(find.byKey(const ValueKey('compare-show-all')));
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(find.text('食材明细'), 100);
      if (kind != 'added') {
        expect(find.text(kind == 'unit' ? 'A：1 碗' : 'A：水 1 碗'), findsOneWidget);
      }
      if (kind != 'removed') {
        expect(
          find.text(kind == 'unit' ? 'B：2 碗' : 'B：水 ${after.quantity} 碗'),
          findsOneWidget,
        );
      }
      await tester.tap(find.text('食材明细'));
      await tester.pumpAndSettle();
      if (kind != 'added') expect(find.textContaining('水 1 碗'), findsWidgets);
      if (kind != 'removed') {
        expect(find.textContaining('水 ${after.quantity} 碗'), findsWidgets);
      }
      expect(find.textContaining('无 碗'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('历史可分页选择同菜的两个独立菜谱版本，保留 A 到 B 方向', (tester) async {
    const otherRecipe = '44444444-4444-4444-8444-444444444444';
    final server = FakeServer();
    server.on(
      'GET',
      '/v1/recipes/$recipeId/versions',
      (_) => (
        200,
        RecipeVersionHistory(
          items: [
            RecipeVersionSummary(
              id: versionA,
              versionNumber: 1,
              aiAssisted: false,
              changeNote: '本菜谱原版',
              createdAt: '2026-10-01T00:00:00Z',
            ),
          ],
        ).toJson(),
      ),
    );
    server.on(
      'GET',
      '/v1/recipes/$recipeId/comparison-candidates',
      (request) => (
        200,
        {
          'items': [
            {
              'id': request.query['cursor'] == null ? versionA : versionB,
              'recipe_id': request.query['cursor'] == null
                  ? recipeId
                  : otherRecipe,
              'author': '作者',
              'version_number': 1,
              'ai_assisted': false,
              'change_note': request.query['cursor'] == null
                  ? '本菜谱原版'
                  : '独立菜谱少盐版',
              'created_at': '2026-10-01T00:00:00Z',
            },
          ],
          'next_cursor': request.query['cursor'] == null ? 'next-page' : null,
        },
      ),
    );
    server.on(
      'GET',
      '/v1/recipes/$recipeId/compare',
      (request) =>
          request.query['from_version_id'] == versionA &&
              request.query['to_version_id'] == versionB
          ? (200, comparisonFixture().toJson())
          : FakeServer.error(422, 'invalid_request', '比较方向错误'),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
        .read(routerProvider)
        .push('/recipes/$recipeId/history');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipe-select-comparison')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('recipe-candidate-select-$versionA')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipe-history-load-more')));
    await tester.pumpAndSettle();
    expect(find.textContaining('独立菜谱少盐版'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('recipe-candidate-select-$versionB')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipe-compare-selected')));
    await tester.pumpAndSettle();
    expect(find.text('已按 2 人份对比'), findsOneWidget);
    expect(find.text('用量变化'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('历史可选两版、和上一版比较、打开为什么及两版详情', (tester) async {
    final server = FakeServer();
    server.on(
      'GET',
      '/v1/recipes/$recipeId/versions',
      (_) => (
        200,
        RecipeVersionHistory(
          items: [
            RecipeVersionSummary(
              id: versionB,
              previousVersionId: versionA,
              versionNumber: 2,
              aiAssisted: false,
              changeNote: '少盐',
              createdAt: '2026-10-02T00:00:00Z',
            ),
            RecipeVersionSummary(
              id: versionA,
              versionNumber: 1,
              aiAssisted: false,
              changeNote: '原版',
              createdAt: '2026-10-01T00:00:00Z',
            ),
          ],
        ).toJson(),
      ),
    );
    server.on(
      'GET',
      '/v1/recipes/$recipeId/comparison-candidates',
      (_) => (
        200,
        RecipeComparisonCandidates(
          items: [
            for (final entry in [(versionB, 2), (versionA, 1)])
              RecipeComparisonCandidate(
                id: entry.$1,
                recipeId: recipeId,
                author: '作者',
                versionNumber: entry.$2,
                aiAssisted: false,
                changeNote: entry.$2 == 1 ? '原版' : '少盐',
                createdAt: '2026-10-01T00:00:00Z',
              ),
          ],
        ).toJson(),
      ),
    );
    server.on(
      'GET',
      '/v1/recipes/$recipeId/compare',
      (_) => (200, comparisonFixture().toJson()),
    );
    for (final entry in [(versionA, 1), (versionB, 2)]) {
      server.on(
        'GET',
        '/v1/recipes/$recipeId/versions/${entry.$1}',
        (_) => (200, detailFixture(entry.$1, entry.$2).toJson()),
      );
    }
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    container.read(routerProvider).push('/recipes/$recipeId/history');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipe-select-comparison')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('recipe-candidate-select-$versionA')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('recipe-candidate-select-$versionB')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipe-compare-selected')));
    await tester.pumpAndSettle();
    expect(find.text('已按 2 人份对比'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('为什么'), 100);
    await tester.tap(find.text('为什么'));
    await tester.pumpAndSettle();
    expect(find.text('按保存的基础量比较'), findsWidgets);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    for (final key in ['a', 'b']) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('compare-detail-$key')),
        -200,
      );
      await tester.tap(find.byKey(ValueKey('compare-detail-$key')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('recipe-detail-content')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
    await goBack(tester);
    await tester.tap(find.byKey(const ValueKey('recipe-select-comparison')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipe-compare-previous-2')));
    await tester.pumpAndSettle();
    expect(find.text('食材版本对比'), findsOneWidget);
  });

  testWidgets('不可比较版本显示等价错误并可重试', (tester) async {
    final server = FakeServer();
    var retry = false;
    server.on(
      'GET',
      '/v1/recipes/$recipeId/compare',
      (_) => retry
          ? (200, comparisonFixture().toJson())
          : FakeServer.error(404, 'not_found', '没有找到'),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first))
        .read(routerProvider)
        .push('/recipes/$recipeId/compare?from=$versionA&to=$versionB');
    await tester.pumpAndSettle();
    expect(find.text('无法比较这些版本，请确认两版仍可查看'), findsOneWidget);
    expect(find.text('比较菜'), findsNothing);
    retry = true;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('已按 2 人份对比'), findsOneWidget);
  });
  for (final size in [const Size(360, 780), const Size(1000, 700)]) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.3, 1.6]) {
        testWidgets('食材比较只看变化、展开全部、依据和响应布局 $size $brightness $scale', (
          tester,
        ) async {
          final server = FakeServer();
          server.on(
            'GET',
            '/v1/recipes/$recipeId/compare',
            (_) => (200, comparisonFixture().toJson()),
          );
          await pumpApp(
            tester,
            env: TestEnv.signedIn(server: server),
            size: size,
            brightness: brightness,
            textScale: scale,
          );
          final container = ProviderScope.containerOf(
            tester.element(find.byType(Scaffold).first),
          );
          container
              .read(routerProvider)
              .push('/recipes/$recipeId/compare?from=$versionA&to=$versionB');
          await tester.pumpAndSettle();
          expect(find.text('仅比较食材，尚未比较步骤'), findsOneWidget);
          expect(find.text('已按 2 人份对比'), findsOneWidget);
          expect(find.text('用量变化'), findsOneWidget);
          expect(find.text('水'), findsNothing);
          expect(find.textContaining('−33.3%'), findsOneWidget);
          final from = tester.getTopLeft(
            find.byKey(const ValueKey('compare-version-a')),
          );
          final to = tester.getTopLeft(
            find.byKey(const ValueKey('compare-version-b')),
          );
          if (size.width > size.height) {
            expect(to.dx, greaterThan(from.dx));
            expect(to.dy, from.dy);
          } else {
            expect(to.dy, greaterThan(from.dy));
          }
          await tester.tap(find.byKey(const ValueKey('compare-show-all')));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(find.text('水'), 200);
          expect(find.text('水'), findsOneWidget);
          expect(find.text('无食材变化'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
