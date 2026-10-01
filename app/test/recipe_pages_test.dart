import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'package:gram_tree/recipes/recipe_repository.dart';

import 'helpers.dart';

const _recipeId = '11111111-1111-4111-8111-111111111111';
const _firstVersionId = '22222222-2222-4222-8222-222222222222';
const _secondVersionId = '33333333-3333-4333-8333-333333333333';
const _standardIngredientId = '44444444-4444-4444-8444-444444444444';

final class _RecipeApiState {
  _RecipeApiState(this.current, this.versions);

  Map<String, dynamic> current;
  final List<Map<String, dynamic>> versions;
  bool deleted = false;
}

Map<String, dynamic> _minimalDetailJson({
  String dishName = '基础菜',
  int versionNumber = 1,
  String versionId = _firstVersionId,
  String? previousVersionId,
  String changeNote = '第一版',
  String? standardIngredientId,
  RecipeSnapshot? snapshot,
  List<RecipeImageOut>? images,
}) {
  final detail = RecipeDetail(
    author: RecipeAuthor(id: 'author-id', nickname: '味友0001'),
    createdAt: '2026-10-01T00:00:00+00:00',
    dish: DishOut(aliases: const [], id: 'dish-id', name: dishName),
    id: _recipeId,
    updatedAt: '2026-10-01T00:00:00+00:00',
    version: RecipeVersionOut(
      aiAssisted: false,
      changeNote: changeNote,
      createdAt: '2026-10-01T00:00:00+00:00',
      derived: RecipeDerived(
        activeTimeSeconds: 0,
        allergens: null,
        allergensIncomplete: false,
        cookware: null,
        nutritionPerServing: null,
        totalTimeSeconds: 0,
      ),
      editOperations: const [],
      id: versionId,
      images: images ?? const [],
      previousVersionId: previousVersionId,
      snapshot:
          snapshot ??
          RecipeSnapshot(
            difficulty: null,
            dishType: null,
            formatVersion: RecipeSnapshotFormatVersionEnum.number1,
            ingredients: [
              RecipeIngredient(
                baseQuantity: null,
                baseUnit: null,
                displayName: '水',
                functional: false,
                group: '主料',
                id: 'ingredient-1',
                ingredientId: standardIngredientId,
                optional: null,
                preparation: null,
                quantity: 100,
                quantitySource: null,
                replacement: null,
                scalingMode: RecipeIngredientScalingModeEnum.proportional,
                unit: 'g',
              ),
            ],
            servings: 2,
            steps: [
              RecipeStep(
                action: '煮',
                cookware: null,
                dependsOn: null,
                doneness: null,
                durationSeconds: 0,
                durationSource: null,
                heat: null,
                heatSource: null,
                id: 'step-1',
                ingredientIds: null,
                instruction: '把水烧开',
                notes: null,
                temperatureCelsius: null,
                temperatureSource: null,
                unattended: false,
                why: null,
              ),
            ],
            tags: null,
          ),
      versionNumber: versionNumber,
    ),
    visibility: RecipeDetailVisibilityEnum.private,
    rootRecipeId: null,
    sourceVersionId: null,
  );
  final json = Map<String, dynamic>.from(detail.toJson());
  final version = Map<String, dynamic>.from(json['version'] as Map);
  final snapshotJson = Map<String, dynamic>.from(version['snapshot'] as Map);
  // Keep the fixture close to the API's sparse nullable response, rather than
  // relying only on constructor defaults in the generated client.
  final ingredients = (snapshotJson['ingredients'] as List?)
      ?.map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
  if (ingredients != null && ingredients.isNotEmpty) {
    ingredients.first
      ..['ingredient_id'] = standardIngredientId
      ..remove('optional')
      ..remove('preparation')
      ..remove('base_quantity')
      ..remove('base_unit');
    snapshotJson['ingredients'] = ingredients;
  }
  final steps = (snapshotJson['steps'] as List?)
      ?.map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
  if (steps != null && steps.isNotEmpty) {
    steps.first
      ..['heat'] = null
      ..['temperature_celsius'] = null;
    snapshotJson['steps'] = steps;
  }
  final derived = Map<String, dynamic>.from(version['derived'] as Map)
    ..['nutrition_per_serving'] = null;
  version['snapshot'] = snapshotJson;
  version['derived'] = derived;
  json['version'] = version;
  return json;
}

Map<String, dynamic> _standardIngredientJson() => IngredientDetail(
  aliases: const ['鸡蛋'],
  attributes: IngredientAttributes(),
  category: '蛋类',
  id: _standardIngredientId,
  pinyin: 'jidan',
  pinyinInitials: 'JD',
  standardName: '鸡蛋',
  version: 'ingredient-v1',
).toJson();

_RecipeApiState _installRecipeApi(
  FakeServer server, {
  String? standardIngredientId,
}) {
  final first = _minimalDetailJson(standardIngredientId: standardIngredientId);
  final state = _RecipeApiState(first, [first]);

  server.on('GET', '/v1/ingredients/changes', (_) {
    return (
      200,
      {
        'added': [_standardIngredientJson()],
        'current_version': 'ingredient-v1',
        'merged': const [],
        'modified': const [],
        'releases': const [],
      },
    );
  });
  server.on('GET', '/v1/recipes', (_) {
    if (state.deleted) return (200, RecipeList(items: const []).toJson());
    final current = RecipeDetail.fromJson(state.current);
    final snapshot = current.version.snapshot;
    return (
      200,
      RecipeList(
        items: [
          RecipeListItem(
            activeTimeSeconds: current.version.derived.activeTimeSeconds,
            difficulty: snapshot.difficulty,
            dish: current.dish,
            id: current.id,
            servings: snapshot.servings,
            totalTimeSeconds: current.version.derived.totalTimeSeconds,
            updatedAt: current.updatedAt,
            versionNumber: current.version.versionNumber,
            visibility: RecipeListItemVisibilityEnum.private,
          ),
        ],
      ).toJson(),
    );
  });
  server.on('GET', '/v1/recipes/$_recipeId', (_) {
    if (state.deleted) return FakeServer.error(404, 'not_found', '没有找到');
    return (200, state.current);
  });
  server.on('GET', '/v1/recipes/$_recipeId/versions', (_) {
    if (state.deleted) return FakeServer.error(404, 'not_found', '没有找到');
    final summaries = [
      for (final raw in state.versions.reversed)
        () {
          final detail = RecipeDetail.fromJson(raw);
          return RecipeVersionSummary(
            aiAssisted: detail.version.aiAssisted,
            changeNote: detail.version.changeNote,
            createdAt: detail.version.createdAt,
            id: detail.version.id,
            previousVersionId: detail.version.previousVersionId,
            versionNumber: detail.version.versionNumber,
          );
        }(),
    ];
    return (200, RecipeVersionHistory(items: summaries).toJson());
  });
  server.on('GET', '/v1/recipes/$_recipeId/versions/$_firstVersionId', (_) {
    if (state.deleted) return FakeServer.error(404, 'not_found', '没有找到');
    return (200, state.versions.first);
  });
  server.on('GET', '/v1/recipes/$_recipeId/versions/$_secondVersionId', (_) {
    if (state.deleted) return FakeServer.error(404, 'not_found', '没有找到');
    return (200, state.versions.last);
  });
  server.on('POST', '/v1/recipes', (record) {
    final body = Map<String, dynamic>.from(record.body as Map);
    final snapshot = RecipeSnapshot.fromJson(
      Map<String, dynamic>.from(body['snapshot'] as Map),
    );
    final created = _minimalDetailJson(
      dishName: body['dish_name'] as String? ?? '新菜谱',
      snapshot: snapshot,
      changeNote: body['change_note'] as String? ?? '',
    );
    state.current = created;
    state.versions
      ..clear()
      ..add(created);
    return (201, created);
  });
  server.on('POST', '/v1/recipes/$_recipeId/versions', (record) {
    final body = Map<String, dynamic>.from(record.body as Map);
    final snapshot = RecipeSnapshot.fromJson(
      Map<String, dynamic>.from(body['snapshot'] as Map),
    );
    final created = _minimalDetailJson(
      dishName: RecipeDetail.fromJson(state.current).dish.name,
      snapshot: snapshot,
      versionNumber: state.versions.length + 1,
      versionId: _secondVersionId,
      previousVersionId: RecipeDetail.fromJson(state.current).version.id,
      changeNote: body['change_note'] as String? ?? '',
    );
    state.current = created;
    state.versions.add(created);
    return (201, created);
  });
  server.on('DELETE', '/v1/recipes/$_recipeId', (_) {
    state.deleted = true;
    return (204, null);
  });
  return state;
}

Future<void> _openNewEditor(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('primary-create-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
  await tester.pumpAndSettle();
}

Future<void> _openMyRecipes(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('primary-create-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('my-recipes-entry')));
  await tester.pumpAndSettle();
}

Finder _fieldsWithLabel(String label) => find.bySemanticsLabel(label);

Finder _iconWithKeyPrefix(String prefix) => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return widget is IconButton &&
      key is ValueKey<String> &&
      key.value.startsWith(prefix);
});

Finder _textFieldWithKeyPrefix(String prefix) =>
    find.byWidgetPredicate((widget) {
      final key = widget.key;
      return widget is TextFormField &&
          key is ValueKey<String> &&
          key.value.startsWith(prefix);
    });

Future<void> _enterDishName(WidgetTester tester, String name) async {
  await tester.enterText(find.byKey(const ValueKey('recipe-dish-name')), name);
  final ingredient = find.byKey(const ValueKey('recipe-ingredient-search'));
  await _scrollUntilVisible(tester, ingredient);
  await tester.enterText(ingredient, '默认食材');
  final step = find.byKey(const ValueKey('recipe-step-instruction'));
  await _scrollUntilVisible(tester, step);
  await tester.enterText(step, '完成默认步骤');
  await tester.pumpAndSettle();
}

Future<void> _scrollToBottom(WidgetTester tester) async {
  final list = find.byType(ListView).last;
  for (var i = 0; i < 3; i++) {
    await tester.drag(list, const Offset(0, -3000));
    await tester.pumpAndSettle();
  }
}

Future<void> _scrollToTop(WidgetTester tester) async {
  final list = find.byType(ListView).last;
  for (var i = 0; i < 3; i++) {
    await tester.drag(list, const Offset(0, 3000));
    await tester.pumpAndSettle();
  }
}

Future<void> _scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Offset delta = const Offset(0, -500),
}) async {
  final list = find.byType(ListView).last;
  for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
    await tester.drag(list, delta);
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets(
    'small phone scrolls loaded detail before deleting from history',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final server = FakeServer();
      _installRecipeApi(server);
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await _openMyRecipes(tester);
      await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('recipe-detail-content')),
        findsOneWidget,
      );
      // Regression for the emulator failure: this control is not built at the
      // top of a short viewport. Its absence here is not a failed detail load.
      expect(find.byKey(const ValueKey('delete-recipe-button')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('recipe-history-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recipe-version-1')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('edit-old-recipe-button')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('edit-old-recipe-button')));
      await tester.pumpAndSettle();
      await _scrollToTop(tester);
      await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
      await tester.pumpAndSettle();
      final request =
          server.calls('POST', '/v1/recipes/$_recipeId/versions').single.body
              as Map;
      expect(request['base_version_id'], _firstVersionId);
      expect(request['image_ids'], isEmpty);
      await tester.tap(find.byKey(const ValueKey('recipe-list-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('recipe-detail-content')),
        findsOneWidget,
      );
      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('delete-recipe-button')),
      );
      await tester.tap(find.byKey(const ValueKey('delete-recipe-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认删除'));
      await tester.pumpAndSettle();
      expect(find.text('还没有菜谱'), findsOneWidget);
    },
  );

  testWidgets('recipe list and history retry after a page load error', (
    tester,
  ) async {
    final server = FakeServer();
    final state = _installRecipeApi(server);
    final current = RecipeDetail.fromJson(state.current);
    final list = RecipeList(
      items: [
        RecipeListItem(
          activeTimeSeconds: current.version.derived.activeTimeSeconds,
          difficulty: current.version.snapshot.difficulty,
          dish: current.dish,
          id: current.id,
          servings: current.version.snapshot.servings,
          totalTimeSeconds: current.version.derived.totalTimeSeconds,
          updatedAt: current.updatedAt,
          versionNumber: current.version.versionNumber,
          visibility: RecipeListItemVisibilityEnum.private,
        ),
      ],
    ).toJson();
    var listAvailable = false;
    server.on('GET', '/v1/recipes', (_) {
      return listAvailable
          ? (200, list)
          : FakeServer.error(503, 'unavailable', '暂时不可用');
    });
    var historyAvailable = false;
    final history = RecipeVersionHistory(
      items: [
        RecipeVersionSummary(
          aiAssisted: false,
          changeNote: current.version.changeNote,
          createdAt: current.version.createdAt,
          id: current.version.id,
          previousVersionId: null,
          versionNumber: 1,
        ),
      ],
    ).toJson();
    server.on('GET', '/v1/recipes/$_recipeId/versions', (_) {
      return historyAvailable
          ? (200, history)
          : FakeServer.error(503, 'unavailable', '暂时不可用');
    });
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openMyRecipes(tester);
    await tester.pumpAndSettle();
    expect(server.calls('GET', '/v1/recipes'), isNotEmpty);
    expect(find.text('菜谱暂时加载不了'), findsOneWidget);
    listAvailable = true;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('recipe-card-$_recipeId')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipe-history-button')));
    await tester.pumpAndSettle();
    expect(find.text('菜谱暂时加载不了'), findsOneWidget);
    historyAvailable = true;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recipe-version-1')), findsOneWidget);
  });

  testWidgets('recipe list and history load cursor pages', (tester) async {
    final server = FakeServer();
    final state = _installRecipeApi(server);
    final current = RecipeDetail.fromJson(state.current);
    final firstItem = RecipeListItem(
      activeTimeSeconds: current.version.derived.activeTimeSeconds,
      difficulty: current.version.snapshot.difficulty,
      dish: current.dish,
      id: current.id,
      servings: current.version.snapshot.servings,
      totalTimeSeconds: current.version.derived.totalTimeSeconds,
      updatedAt: current.updatedAt,
      versionNumber: current.version.versionNumber,
      visibility: RecipeListItemVisibilityEnum.private,
    );
    final secondItem = RecipeListItem(
      activeTimeSeconds: firstItem.activeTimeSeconds,
      difficulty: firstItem.difficulty,
      dish: DishOut(aliases: const [], id: 'dish-2', name: '第二道菜'),
      id: '22222222-2222-4222-8222-222222222222',
      servings: firstItem.servings,
      totalTimeSeconds: firstItem.totalTimeSeconds,
      updatedAt: firstItem.updatedAt,
      versionNumber: firstItem.versionNumber,
      visibility: RecipeListItemVisibilityEnum.private,
    );
    var listPage = 0;
    server.on('GET', '/v1/recipes', (request) {
      if (listPage++ == 0) {
        return (
          200,
          RecipeList(items: [firstItem], nextCursor: 'list-next').toJson(),
        );
      }
      expect(request.query['cursor'], 'list-next');
      return (200, RecipeList(items: [secondItem]).toJson());
    });
    var historyPage = 0;
    server.on('GET', '/v1/recipes/$_recipeId/versions', (request) {
      final version = RecipeVersionSummary(
        aiAssisted: false,
        changeNote: historyPage == 0 ? '第一版' : '第二版',
        createdAt: current.version.createdAt,
        id: historyPage == 0 ? _firstVersionId : _secondVersionId,
        previousVersionId: historyPage == 0 ? null : _firstVersionId,
        versionNumber: historyPage + 1,
      );
      if (historyPage++ == 0) {
        return (
          200,
          RecipeVersionHistory(
            items: [version],
            nextCursor: 'history-next',
          ).toJson(),
        );
      }
      expect(request.query['cursor'], 'history-next');
      return (200, RecipeVersionHistory(items: [version]).toJson());
    });

    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('recipe-load-more')));
    await tester.pumpAndSettle();
    expect(find.text('第二道菜'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipe-history-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recipe-history-load-more')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recipe-version-2')), findsOneWidget);
  });

  testWidgets(
    'editing an existing photo version does not submit its image as staged',
    (tester) async {
      final server = FakeServer();
      final state = _installRecipeApi(server);
      final image = RecipeImageOut(
        byteSize: 12,
        contentType: 'image/jpeg',
        expiresInSeconds: 900,
        id: '55555555-5555-4555-8555-555555555555',
        url: '/private-image',
        versionId: _firstVersionId,
        width: 10,
        height: 10,
      );
      final detail = Map<String, dynamic>.from(state.current);
      final version = Map<String, dynamic>.from(detail['version'] as Map)
        ..['images'] = [image.toJson()];
      detail['version'] = version;
      state.current = detail;
      state.versions[0] = detail;

      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await _openMyRecipes(tester);
      await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('edit-recipe-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
      await tester.pumpAndSettle();

      final request =
          server.calls('POST', '/v1/recipes/$_recipeId/versions').single.body
              as Map;
      expect(request['base_version_id'], _firstVersionId);
      expect(request['image_ids'], isEmpty);
    },
  );
  testWidgets('minimal nullable detail renders through the generated client', (
    tester,
  ) async {
    final server = FakeServer();
    _installRecipeApi(server);
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openMyRecipes(tester);

    await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
    await tester.pumpAndSettle();
    await _scrollToBottom(tester);

    expect(find.text('基础菜'), findsWidgets);
    expect(find.text('水'), findsOneWidget);
    expect(find.textContaining('把水烧开'), findsOneWidget);
    expect(find.text('暂无营养估算'), findsOneWidget);
  });

  for (final (name, brightness, scale) in [
    ('浅色字号 2', Brightness.light, 2.0),
    ('深色字号 2', Brightness.dark, 2.0),
    ('浅色字号 3', Brightness.light, 3.0),
    ('深色字号 3', Brightness.dark, 3.0),
  ]) {
    testWidgets('菜谱详情在$name下仍可打开原理区', (tester) async {
      final server = FakeServer();
      _installRecipeApi(server);
      await pumpApp(
        tester,
        env: TestEnv.signedIn(server: server),
        brightness: brightness,
        textScale: scale,
      );
      await _openMyRecipes(tester);
      await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
      await tester.pumpAndSettle();
      await _scrollToBottom(tester);

      await tester.tap(find.byKey(const ValueKey('recipe-step-0')));
      await tester.pumpAndSettle();
      expect(find.textContaining('把水烧开'), findsOneWidget);
    });
  }

  testWidgets(
    'recipe detail renders incomplete data dependencies and sources',
    (tester) async {
      final server = FakeServer();
      final state = _installRecipeApi(server);
      final detail = Map<String, dynamic>.from(state.current);
      final version = Map<String, dynamic>.from(detail['version'] as Map);
      final derived = Map<String, dynamic>.from(version['derived'] as Map)
        ..['allergens'] = const <String>[]
        ..['allergens_incomplete'] = true
        ..['nutrition_per_serving'] = {
          'energy_kcal': null,
          'protein_g': null,
          'fat_g': null,
          'carbohydrate_g': null,
          'sodium_mg': null,
          'estimated': true,
          'incomplete': true,
        };
      final snapshot = Map<String, dynamic>.from(version['snapshot'] as Map);
      final steps = [
        for (final raw in (snapshot['steps'] as List))
          Map<String, dynamic>.from(raw as Map),
        {
          'id': 'step-2',
          'action': '煮',
          'instruction': '继续煮开',
          'ingredient_ids': const <String>[],
          'duration_seconds': 30,
          'unattended': false,
          'depends_on': ['step-1'],
          'duration_source': {
            'source': 'ai_estimated',
            'original': '一会儿',
            'confidence': 0.5,
            'basis': '测试依据',
          },
          'why': '让味道融合',
        },
      ];
      snapshot['steps'] = steps;
      version['derived'] = derived;
      version['snapshot'] = snapshot;
      detail['version'] = version;
      state.current = detail;
      state.versions[0] = detail;

      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await _openMyRecipes(tester);
      await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
      await tester.pumpAndSettle();
      await _scrollToBottom(tester);
      expect(find.textContaining('可能不完整'), findsWidgets);
      expect(find.textContaining('依赖的前置步骤：1. 把水烧开'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('recipe-step-1')));
      await tester.tap(find.byKey(const ValueKey('recipe-step-1')));
      await tester.pumpAndSettle();
      expect(find.text('AI 估算'), findsOneWidget);
    },
  );

  testWidgets('loaded standard ingredient keeps its ID in a new version', (
    tester,
  ) async {
    final server = FakeServer();
    _installRecipeApi(server, standardIngredientId: _standardIngredientId);
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-recipe-button')));
    await tester.pumpAndSettle();
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('recipe-ingredient-quantity')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('recipe-ingredient-quantity')),
      '200',
    );
    await _scrollToTop(tester);
    await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
    await tester.pumpAndSettle();

    final request =
        server.calls('POST', '/v1/recipes/$_recipeId/versions').single.body
            as Map;
    final snapshot = request['snapshot'] as Map;
    final ingredient = (snapshot['ingredients'] as List).first as Map;
    expect(ingredient['ingredient_id'], _standardIngredientId);
    final step = (snapshot['steps'] as List).first as Map;
    expect(step.containsKey('temperature_celsius'), isFalse);
    expect(step.containsKey('heat'), isFalse);
    expect(step.containsKey('cookware'), isFalse);
  });

  test('free-text replacement serializes a nullable ingredient ID', () {
    final replacement = RecipeReplacementDraft(
      ingredientId: null,
      displayName: '土豆',
    ).toModel();
    final json = replacement.toJson();
    expect(json['display_name'], '土豆');
    expect(json.containsKey('ingredient_id'), isFalse);
  });

  testWidgets('editor can add and reorder multiple ingredients and steps', (
    tester,
  ) async {
    final server = FakeServer();
    _installRecipeApi(server);
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openNewEditor(tester);
    await _enterDishName(tester, '排序测试');
    await _scrollToTop(tester);

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('recipe-add-ingredient')),
    );
    await tester.tap(find.byKey(const ValueKey('recipe-add-ingredient')));
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('recipe-add-step')),
    );
    await tester.tap(find.byKey(const ValueKey('recipe-add-step')));
    await tester.pumpAndSettle();
    await _scrollToBottom(tester);
    await _scrollUntilVisible(
      tester,
      _textFieldWithKeyPrefix('recipe-ingredient-search-'),
      delta: const Offset(0, 500),
    );
    final secondIngredientField = _textFieldWithKeyPrefix(
      'recipe-ingredient-search-',
    ).last;
    await tester.enterText(secondIngredientField, '第二食材');
    await _scrollToBottom(tester);
    final secondStepField = _textFieldWithKeyPrefix('recipe-step-instruction-')
        .last;
    final secondStepFieldKey =
        tester.widget<TextFormField>(secondStepField).key! as ValueKey<String>;
    final secondStepId = secondStepFieldKey.value.substring(
      'recipe-step-instruction-'.length,
    );
    await tester.enterText(secondStepField, '第二步');
    await _scrollUntilVisible(
      tester,
      _iconWithKeyPrefix('recipe-move-ingredient-up-'),
      delta: const Offset(0, 500),
    );
    await tester.tap(_iconWithKeyPrefix('recipe-move-ingredient-up-').last);
    final secondStepMove = find.byKey(
      ValueKey('recipe-move-step-up-$secondStepId'),
    );
    await _scrollUntilVisible(tester, secondStepMove);
    await tester.tap(secondStepMove);
    await tester.pumpAndSettle();

    await _scrollToTop(tester);
    await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
    await tester.pumpAndSettle();
    final request = server.calls('POST', '/v1/recipes').single.body as Map;
    final snapshot = request['snapshot'] as Map;
    final ingredients = snapshot['ingredients'] as List;
    final steps = snapshot['steps'] as List;
    expect((ingredients.first as Map)['display_name'], '第二食材');
    expect((steps.first as Map)['instruction'], '第二步');
  });

  testWidgets('editor can delete extra ingredients and steps', (tester) async {
    final server = FakeServer();
    _installRecipeApi(server);
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openNewEditor(tester);
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('recipe-add-ingredient')),
    );
    await tester.tap(find.byKey(const ValueKey('recipe-add-ingredient')));
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('recipe-add-step')),
    );
    await tester.tap(find.byKey(const ValueKey('recipe-add-step')));
    await tester.pumpAndSettle();
    await _scrollToBottom(tester);
    await _scrollUntilVisible(
      tester,
      _iconWithKeyPrefix('recipe-delete-ingredient-'),
      delta: const Offset(0, 500),
    );
    await tester.tap(_iconWithKeyPrefix('recipe-delete-ingredient-').last);
    await _scrollUntilVisible(
      tester,
      _iconWithKeyPrefix('recipe-delete-step-'),
    );
    await tester.tap(_iconWithKeyPrefix('recipe-delete-step-').last);
    await tester.pumpAndSettle();
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('recipe-ingredient-search')),
      delta: const Offset(0, 500),
    );
    expect(
      find.byKey(const ValueKey('recipe-ingredient-search')),
      findsOneWidget,
    );
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('recipe-step-instruction')),
      delta: const Offset(0, 500),
    );
    expect(
      find.byKey(const ValueKey('recipe-step-instruction')),
      findsOneWidget,
    );
  });

  testWidgets('server save errors stay visible in the editor', (tester) async {
    final server = FakeServer();
    server.on(
      'POST',
      '/v1/recipes',
      (_) => FakeServer.error(422, 'invalid_recipe', '菜谱结构有误：步骤说明不完整'),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openNewEditor(tester);
    await _enterDishName(tester, '服务端拒绝');
    await _scrollToTop(tester);
    await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('recipe-save-error')), findsOneWidget);
    expect(find.textContaining('菜谱结构有误：步骤说明不完整'), findsOneWidget);
    expect(find.byKey(const ValueKey('recipe-dish-name')), findsOneWidget);
  });

  testWidgets(
    'save, history, old-version edit, list, and delete remain connected',
    (tester) async {
      final server = FakeServer();
      final state = _installRecipeApi(server);
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await _openNewEditor(tester);
      await _enterDishName(tester, '版本链测试');
      await _scrollToTop(tester);
      await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('recipe-history-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('recipe-history-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recipe-version-1')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('recipe-version-1')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('edit-old-recipe-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('edit-old-recipe-button')));
      await tester.pumpAndSettle();
      await tester.enterText(_fieldsWithLabel('这次改了什么'), '从第一版继续修改');
      await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
      await tester.pumpAndSettle();
      expect(state.versions, hasLength(2));
      await _scrollToBottom(tester);
      expect(
        find.byKey(const ValueKey('delete-recipe-button')),
        findsOneWidget,
      );

      await _scrollToTop(tester);
      await tester.tap(find.byKey(const ValueKey('recipe-list-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('recipe-card-$_recipeId')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
      await tester.pumpAndSettle();
      await _scrollToBottom(tester);
      await tester.tap(find.byKey(const ValueKey('delete-recipe-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认删除'));
      await tester.pumpAndSettle();
      expect(find.text('还没有菜谱'), findsOneWidget);
    },
  );
}
