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
    await tester.tap(find.byKey(const ValueKey('recipe-compare-select-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipe-compare-select-2')));
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
    testWidgets('食材比较只看变化、展开全部、依据和响应布局 $size', (tester) async {
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
