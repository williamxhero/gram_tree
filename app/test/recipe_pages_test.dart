import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'package:gram_tree/storage/local_store.dart';
import 'package:gram_tree/ui_protocol/source_mark.dart';

import 'fixtures/conversion_cases.g.dart';
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

void _replaceRecipeSnapshot(_RecipeApiState state, Map<String, dynamic> patch) {
  final detail = Map<String, dynamic>.from(state.current);
  final version = Map<String, dynamic>.from(detail['version'] as Map);
  final snapshot = Map<String, dynamic>.from(version['snapshot'] as Map)
    ..addAll(patch);
  version['snapshot'] = snapshot;
  detail['version'] = version;
  state.current = detail;
  state.versions
    ..clear()
    ..add(detail);
}

Future<List<Map<String, dynamic>>> _loadFixture(
  WidgetTester tester,
  String asset,
) async {
  // rootBundle hangs under `flutter test --platform chrome`, so the shared
  // tables are embedded by tool/gen_conversion_fixtures.sh (kept in sync by
  // conversion_fixtures_sync_test.dart).
  final contents = embeddedConversionCases[asset];
  if (contents == null) {
    fail('fixture not embedded, run tool/gen_conversion_fixtures.sh: $asset');
  }
  final decoded = jsonDecode(contents) as List;
  return [for (final item in decoded) Map<String, dynamic>.from(item as Map)];
}

Future<void> _fixtureSettle(WidgetTester tester) async {
  // Never use pumpAndSettle here: the app has long-lived timers and the web
  // test binding can otherwise wait forever. A short, fixed pump budget is
  // enough for FakeServer responses and the resulting frame updates.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _setTargetMoldFromFixture(
  WidgetTester tester,
  Map<String, dynamic> target,
) async {
  final shape = target['shape'] as String;
  final shapeLabel = switch (shape) {
    'round' => '圆模',
    'square' => '方模',
    'rectangular' => '长方模',
    _ => '自定义尺寸',
  };
  final shapeField = find.byKey(const ValueKey('target-mold-shape'));
  await tester.ensureVisible(shapeField);
  await tester.tap(shapeField);
  await _fixtureSettle(tester);
  await tester.tap(find.text(shapeLabel).last);
  await _fixtureSettle(tester);
  if (shape == 'round') {
    await tester.enterText(
      find.byKey(const ValueKey('target-mold-diameter')),
      '${target['diameter']}',
    );
  } else if (shape == 'square') {
    await tester.enterText(
      find.byKey(const ValueKey('target-mold-width')),
      '${target['width'] ?? target['side']}',
    );
  } else {
    await tester.enterText(
      find.byKey(const ValueKey('target-mold-length')),
      '${target['length']}',
    );
    await _fixtureSettle(tester);
    final width = find.byKey(const ValueKey('target-mold-width'));
    await tester.ensureVisible(width);
    await tester.tap(width);
    await tester.enterText(width, '${target['width']}');
    await _fixtureSettle(tester);
  }
  await _fixtureSettle(tester);
}

String _fixtureQuantityText(num value) {
  final number = value.toDouble();
  return number == number.roundToDouble()
      ? number.toInt().toString()
      : number.toString();
}

String _fixtureUnitText(String unit) => switch (unit) {
  'g' => '克',
  'ml' => '毫升',
  _ => unit,
};

String _fixtureRuleText(String rule) => switch (rule) {
  'proportional' => '按比例换算',
  'unchanged' => '保持原值不变',
  'round' => '按个取整',
  'mold_ratio' => '模具比例',
  _ => rule,
};

String _fixtureDisplayBasis(String rule) => switch (rule) {
  'standard_measure' => '按比例换算；常用量具换算；菜谱基础值未改变',
  'personal_measure' => '按比例换算；个人量具只改变显示，菜谱基础值未改变',
  'no_density' => '没有密度数据，保留克数',
  _ => rule,
};

Future<void> _expectFixtureIngredient(
  WidgetTester tester,
  Map<String, dynamic> expected, {
  required bool expectConversionSource,
}) async {
  final id = expected['id'] as String;
  final amount = find.byKey(ValueKey('recipe-ingredient-amount-$id'));
  await _scrollUntilVisible(tester, amount);
  final actual = tester.widget<Text>(amount);
  final expectedText =
      '${_fixtureQuantityText(expected['display_quantity'] as num)} '
      '${_fixtureUnitText(expected['unit'] as String)}';
  expect(actual.data, expectedText, reason: 'ingredient=$id');

  final source = find.byKey(ValueKey('recipe-source-mark-$id'));
  if (!expectConversionSource) {
    expect(source, findsNothing, reason: 'ingredient=$id should be unchanged');
    return;
  }
  expect(source, findsOneWidget, reason: 'ingredient=$id source mark');
  final mark = tester.widget<SourceMark>(source);
  expect(mark.value, expectedText, reason: 'ingredient=$id source value');
  expect(
    mark.originalValue,
    '${_fixtureQuantityText(expected['original_quantity'] as num)} '
    '${expected['unit'] as String}',
    reason: 'ingredient=$id source original value',
  );
  expect(
    mark.basisText,
    _fixtureRuleText(expected['rule'] as String),
    reason: 'ingredient=$id conversion rule',
  );
}

Future<void> _expectFixtureDisplayOutput(
  WidgetTester tester,
  Map<String, dynamic> input,
  Map<String, dynamic> expected,
) async {
  expect(find.byKey(const ValueKey('recipe-measure-mode')), findsOneWidget);
  final amount = find.byKey(
    const ValueKey('recipe-ingredient-amount-display-ingredient'),
  );
  await _scrollUntilVisible(tester, amount);
  // The fixture's Chinese unit words are already the app's locale. Only
  // normalize canonical g/ml tokens if a fixture adds one; never normalize
  // quantities, fractions, or measure names.
  final expectedText = (expected['text'] as String)
      .replaceAll(' g', ' 克')
      .replaceAll(' ml', ' 毫升');
  for (var i = 0; i < 40; i++) {
    if (tester.widget<Text>(amount).data == expectedText) break;
    await tester.pump(const Duration(milliseconds: 50));
  }
  final actual = tester.widget<Text>(amount);
  expect(actual.data, expectedText);
  expect(
    actual.data,
    contains(
      _fixtureUnitText(
        input['mode'] == 'base'
            ? input['base_unit'] as String
            : expected['display_unit'] as String,
      ),
    ),
  );
  final source = find.byKey(
    const ValueKey('recipe-source-mark-display-ingredient'),
  );
  final rule = expected['rule'] as String;
  if (rule == 'base') {
    expect(source, findsNothing);
  } else {
    expect(source, findsOneWidget);
    final mark = tester.widget<SourceMark>(source);
    expect(mark.value, expectedText);
    expect(mark.basisText, _fixtureDisplayBasis(rule));
  }
  if (input['mode'] == 'home') {
    final measure = Map<String, dynamic>.from(input['measure'] as Map);
    expect(find.textContaining(measure['name'] as String), findsWidgets);
  }
}

Future<void> _expectFixtureStep(
  WidgetTester tester, {
  required int index,
  required Map<String, dynamic> source,
  required Map<String, dynamic> expected,
  required bool mold,
}) async {
  final tile = find.byKey(ValueKey('recipe-step-$index'));
  await _scrollUntilVisible(tester, tile);
  final expansion = tester.widget<ExpansionTile>(tile);
  final title = expansion.title;
  expect(title, isA<Text>());
  expect((title as Text).data, '${index + 1}. ${expected['instruction']}');
  final subtitle = expansion.subtitle;
  expect(subtitle, isA<Text>());
  final subtitleText = (subtitle as Text).data ?? '';
  expect(subtitleText, contains('${expected['duration_seconds']} 秒'));
  final temperature = expected['temperature_celsius'];
  if (temperature != null) {
    expect(subtitleText, contains('$temperature'));
  }
  final heat = expected['heat'];
  if (heat != null) expect(subtitleText, contains(heat as String));

  final warning = find.byKey(
    ValueKey(
      mold
          ? 'recipe-step-doneness-warning-${source['id']}'
          : 'recipe-step-batch-warning-${source['id']}',
    ),
  );
  final warningExpected = mold
      ? expected['doneness_warning'] == true
      : expected['batch_warning'] == true;
  if (!warningExpected) {
    expect(warning, findsNothing, reason: 'step=${source['id']} warning');
    return;
  }
  await tester.tap(tile);
  await _fixtureSettle(tester);
  expect(warning, findsOneWidget, reason: 'step=${source['id']} warning');
  if (!mold) {
    expect(find.text(expected['batch_warning_text'] as String), findsOneWidget);
  } else {
    if (expected['has_time_advisory'] == true) {
      expect(find.textContaining('时间不按模具比例放大'), findsOneWidget);
    }
    expect(find.textContaining('请以成熟判断为准'), findsOneWidget);
  }
}

Future<void> _resetPage(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await _fixtureSettle(tester);
}

Future<void> _openRecipeDetailForFixture(
  WidgetTester tester,
  FakeServer server,
) async {
  await pumpApp(tester, env: TestEnv.signedIn(server: server), settle: false);
  await _fixtureSettle(tester);
  await tester.tap(find.byKey(const ValueKey('primary-create-button')));
  await _fixtureSettle(tester);
  await tester.tap(find.byKey(const ValueKey('my-recipes-entry')));
  await _fixtureSettle(tester);
  await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
  await _fixtureSettle(tester);
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
    'mold mode converts the original recipe and restores serving mode',
    (tester) async {
      final server = FakeServer();
      final state = _installRecipeApi(server);
      final version = state.current['version'] as Map;
      final snapshot = version['snapshot'] as Map;
      snapshot['base_mold'] = {'shape': 'round', 'unit': 'in', 'diameter': 6};
      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await _openMyRecipes(tester);
      await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
      await tester.pumpAndSettle();
      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('recipe-mode-mold')),
      );
      await tester.tap(find.byKey(const ValueKey('recipe-serving-increase')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recipe-mode-mold')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('recipe-serving-control')),
        findsNothing,
      );
      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('recipe-measure-mode')),
      );
      expect(find.byKey(const ValueKey('recipe-measure-mode')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('target-mold-diameter')),
        '8',
      );
      await tester.pumpAndSettle();
      await _scrollUntilVisible(tester, find.text('177.78 克'));
      await tester.tap(find.text('按场景调整'));
      await tester.pumpAndSettle();
      expect(find.text('原来：100 g'), findsOneWidget);
      expect(find.textContaining('模具比例'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await _scrollToTop(tester);
      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('recipe-mode-serving')),
      );
      await tester.tap(find.byKey(const ValueKey('recipe-mode-serving')));
      await tester.pumpAndSettle();
      await _scrollToBottom(tester);
      expect(find.text('100 克'), findsWidgets);
      expect((snapshot['ingredients'] as List).first['quantity'], 100);
    },
  );

  testWidgets('mold conversion uses the configured round deviation threshold', (
    tester,
  ) async {
    final server = FakeServer();
    final state = _installRecipeApi(server);
    _replaceRecipeSnapshot(state, {
      'base_mold': {'shape': 'round', 'unit': 'in', 'diameter': 6},
      'ingredients': [
        {
          'id': 'ingredient-1',
          'display_name': '鸡蛋',
          'quantity': 1,
          'unit': '个',
          'scaling_mode': 'round',
        },
      ],
    });
    final env = TestEnv.signedIn(
      server: server,
      params: {'recipe.scaling_round_deviation_threshold': 1.5},
    );
    await pumpApp(tester, env: env);
    await _openMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
    await tester.pumpAndSettle();
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('recipe-mode-mold')),
    );
    await tester.tap(find.byKey(const ValueKey('recipe-mode-mold')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('target-mold-diameter')),
      '4',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('recipe-mold-control')), findsOneWidget);
    expect(find.byKey(const ValueKey('recipe-mold-ratio')), findsOneWidget);
    // 1 egg × (4/6)^2 rounds from 0.44 to 1, a 125% deviation. The
    // non-default 150% threshold must suppress the warning; the old hardcoded
    // 20% value would render it.
    expect(
      find.byKey(const ValueKey('recipe-mold-warning-ingredient-1')),
      findsNothing,
    );
  });

  testWidgets('editor records an immutable base mold in the snapshot', (
    tester,
  ) async {
    final server = FakeServer();
    final state = _installRecipeApi(server);
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openNewEditor(tester);
    await _enterDishName(tester, '基准模具编辑测试');
    await _scrollToTop(tester);
    await tester.tap(find.byKey(const ValueKey('base-mold-enable')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('base-mold-diameter')),
      '8',
    );
    await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
    await tester.pumpAndSettle();
    final mold = (state.current['version'] as Map)['snapshot'] as Map;
    expect(mold['base_mold'], {
      'shape': 'round',
      'unit': 'in',
      'diameter': 8.0,
    });
  });
  testWidgets(
    'small phone scrolls loaded detail before deleting from history',
    (tester) async {
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

  testWidgets('successful save clears the editor draft', (tester) async {
    final server = FakeServer();
    _installRecipeApi(server);
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openNewEditor(tester);
    await _enterDishName(tester, '保存后清理草稿');
    await tester.pump(const Duration(milliseconds: 400));
    await _scrollToTop(tester);
    await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-recipe-button')));
    await tester.pumpAndSettle();
    expect(find.text('恢复未保存修改？'), findsNothing);
  });

  testWidgets('corrupt and cross-scope drafts are ignored', (tester) async {
    final local = MemoryLocalStore(consentedStore());
    await local.setString(
      'recipe_draft:v1:${testUser().id}:new',
      jsonEncode({
        'format_version': 1,
        'account_id': testUser().id,
        'recipe_key': 'new',
        'baseline_version_id': null,
        'payload': {'snapshot': 'corrupt'},
      }),
    );
    final detail = RecipeDetail.fromJson(_minimalDetailJson());
    final payload = {
      'dish_name': '别的范围',
      'aliases': const <String>[],
      'change_note': '',
      'image_ids': const <String>[],
      'snapshot': detail.version.snapshot.toJson(),
    };
    await local.setString(
      'recipe_draft:v1:other-account:new',
      jsonEncode({
        'format_version': 1,
        'account_id': 'other-account',
        'recipe_key': 'new',
        'baseline_version_id': null,
        'payload': payload,
      }),
    );
    await local.setString(
      'recipe_draft:v1:${testUser().id}:other-recipe',
      jsonEncode({
        'format_version': 1,
        'account_id': testUser().id,
        'recipe_key': 'other-recipe',
        'baseline_version_id': null,
        'payload': payload,
      }),
    );
    final server = FakeServer();
    _installRecipeApi(server);
    await pumpApp(
      tester,
      env: TestEnv.signedIn(server: server, local: local),
    );
    await _openNewEditor(tester);
    expect(find.text('恢复未保存修改？'), findsNothing);
    expect(find.byKey(const ValueKey('recipe-dish-name')), findsOneWidget);
  });

  testWidgets('draft baseline and recipe scopes stay isolated', (tester) async {
    final local = MemoryLocalStore(consentedStore());
    final detail = RecipeDetail.fromJson(_minimalDetailJson());
    final payload = {
      'dish_name': '草稿范围',
      'aliases': const <String>[],
      'change_note': '',
      'image_ids': const <String>[],
      'snapshot': detail.version.snapshot.toJson(),
    };
    await local.setString(
      'recipe_draft:v1:${testUser().id}:$_recipeId',
      jsonEncode({
        'format_version': 1,
        'account_id': testUser().id,
        'recipe_key': _recipeId,
        'baseline_version_id': 'stale-version',
        'payload': payload,
      }),
    );
    await local.setString(
      'recipe_draft:v1:${testUser().id}:new',
      jsonEncode({
        'format_version': 1,
        'account_id': testUser().id,
        'recipe_key': 'new',
        'baseline_version_id': null,
        'payload': payload,
      }),
    );
    final server = FakeServer();
    _installRecipeApi(server);
    final env = TestEnv.signedIn(server: server, local: local);
    await pumpApp(tester, env: env);
    await _openMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-recipe-button')));
    await tester.pumpAndSettle();
    expect(find.text('恢复未保存修改？'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await restartApp(tester, env);
    await _openNewEditor(tester);
    expect(find.text('恢复未保存修改？'), findsOneWidget);
  });

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
    server.on('GET', '/v1/recipes', (_) {
      if (listPage++ == 0) {
        return (
          200,
          RecipeList(items: [firstItem], nextCursor: 'list-next').toJson(),
        );
      }
      return (200, RecipeList(items: [secondItem]).toJson());
    });
    var historyPage = 0;
    server.on('GET', '/v1/recipes/$_recipeId/versions', (_) {
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
      expect(
        find.byKey(const ValueKey('recipe-history-button')),
        findsOneWidget,
      );
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
    ('浅色字号 1.3', Brightness.light, 1.3),
    ('深色字号 1.3', Brightness.dark, 1.3),
    ('浅色字号 1.6', Brightness.light, 1.6),
    ('深色字号 1.6', Brightness.dark, 1.6),
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

  testWidgets('editor searches and selects a standard ingredient', (
    tester,
  ) async {
    final server = FakeServer();
    _installRecipeApi(server);
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openNewEditor(tester);
    await _enterDishName(tester, '标准食材选择测试');
    await _scrollToTop(tester);
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('recipe-ingredient-search')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('recipe-ingredient-search')),
      '鸡蛋',
    );
    final searchButton = find.byKey(const ValueKey('recipe-search-ingredient'));
    await tester.ensureVisible(searchButton);
    await tester.tap(searchButton, warnIfMissed: false);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(
            ValueKey('ingredient-result-$_standardIngredientId-ingredient-1'),
          )
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    final result = find.byKey(
      ValueKey('ingredient-result-$_standardIngredientId-ingredient-1'),
    );
    expect(result, findsOneWidget);
    await tester.ensureVisible(result);
    await tester.tap(result, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('鸡蛋'), findsWidgets);
    await _scrollToTop(tester);
    await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
    await tester.pumpAndSettle();
    await _scrollToBottom(tester);
    expect(find.text('鸡蛋'), findsOneWidget);
  });

  testWidgets('recipe detail displays a free-text replacement', (tester) async {
    final server = FakeServer();
    final state = _installRecipeApi(server);
    final detail = Map<String, dynamic>.from(state.current);
    final version = Map<String, dynamic>.from(detail['version'] as Map);
    final snapshot = Map<String, dynamic>.from(version['snapshot'] as Map);
    final ingredients = [
      for (final raw in (snapshot['ingredients'] as List))
        Map<String, dynamic>.from(raw as Map),
    ];
    ingredients.first['replacement'] = '土豆';
    snapshot['ingredients'] = ingredients;
    version['snapshot'] = snapshot;
    detail['version'] = version;
    state.current = detail;
    state.versions[0] = detail;

    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
    await tester.pumpAndSettle();
    await _scrollToBottom(tester);
    expect(find.textContaining('替代品：土豆'), findsOneWidget);
  });

  testWidgets('editing a free-text replacement preserves it', (tester) async {
    final server = FakeServer();
    final state = _installRecipeApi(server);
    final detail = Map<String, dynamic>.from(state.current);
    final version = Map<String, dynamic>.from(detail['version'] as Map);
    final snapshot = Map<String, dynamic>.from(version['snapshot'] as Map);
    final ingredients = [
      for (final raw in (snapshot['ingredients'] as List))
        Map<String, dynamic>.from(raw as Map),
    ];
    ingredients.first['replacement'] = '土豆';
    snapshot['ingredients'] = ingredients;
    version['snapshot'] = snapshot;
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
    await _scrollToBottom(tester);
    expect(find.textContaining('替代品：土豆'), findsOneWidget);
  });

  testWidgets('editor shows unrecorded ingredients and step references', (
    tester,
  ) async {
    final server = FakeServer();
    _installRecipeApi(server);
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openNewEditor(tester);
    await _enterDishName(tester, '未收录引用测试');
    await _scrollToTop(tester);
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('recipe-ingredient-search')),
    );
    expect(find.text('未收录'), findsOneWidget);
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('recipe-step-ref-step-1-ingredient-1')),
    );
    await tester.tap(
      find.byKey(const ValueKey('recipe-step-ref-step-1-ingredient-1')),
    );
    await _scrollToTop(tester);
    await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
    await tester.pumpAndSettle();
    await _scrollToBottom(tester);
    expect(find.textContaining('引用食材：默认食材'), findsOneWidget);
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
    expect(find.byKey(const ValueKey('recipe-history-button')), findsOneWidget);
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

  testWidgets(
    'recipe detail converts servings locally and resets with provenance',
    (tester) async {
      final server = FakeServer();
      final state = _installRecipeApi(server);
      final detail = Map<String, dynamic>.from(state.current);
      final version = Map<String, dynamic>.from(detail['version'] as Map);
      final snapshot = Map<String, dynamic>.from(version['snapshot'] as Map);
      final ingredients = [
        for (final raw in (snapshot['ingredients'] as List))
          Map<String, dynamic>.from(raw as Map),
      ];
      ingredients.first['scaling_mode'] = 'proportional';
      snapshot['ingredients'] = ingredients;
      final steps = [
        for (final raw in (snapshot['steps'] as List))
          Map<String, dynamic>.from(raw as Map),
      ];
      steps.first['ingredient_ids'] = ['ingredient-1'];
      snapshot['steps'] = steps;
      version['snapshot'] = snapshot;
      detail['version'] = version;
      state.current = detail;
      state.versions[0] = detail;

      await pumpApp(tester, env: TestEnv.signedIn(server: server));
      await _openMyRecipes(tester);
      await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('recipe-serving-control')),
        findsOneWidget,
      );
      expect(find.text('按场景调整'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('recipe-serving-increase')));
      await tester.pumpAndSettle();
      await _scrollToBottom(tester);
      expect(find.text('150 克'), findsWidgets);
      expect(find.text('按场景调整'), findsOneWidget);
      await _scrollToTop(tester);
      await tester.tap(find.byKey(const ValueKey('recipe-serving-reset')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('recipe-serving-value')),
        findsOneWidget,
      );
      expect(find.text('2'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('recipe-serving-increase')));
      await tester.pumpAndSettle();
      await _scrollToBottom(tester);
      await tester.tap(find.text('按场景调整'));
      await tester.pumpAndSettle();
      expect(find.text('原来：100 g'), findsOneWidget);
      expect(find.text('现在：150 克'), findsOneWidget);
    },
  );

  testWidgets('recipe detail switches display mode without changing source', (
    tester,
  ) async {
    final server = FakeServer();
    _installRecipeApi(server);
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('recipe-measure-mode')),
    );
    expect(find.byKey(const ValueKey('recipe-measure-mode')), findsOneWidget);
    await _scrollUntilVisible(tester, find.text('汤匙/茶匙'));
    await tester.tap(find.text('汤匙/茶匙'));
    await tester.pumpAndSettle();
    await _scrollToBottom(tester);
    expect(find.text('100 克'), findsWidgets);
    expect(server.calls('POST', '/v1/recipes'), isEmpty);
  });

  testWidgets('recipe detail selects a personal measure and retains grams', (
    tester,
  ) async {
    final server = FakeServer();
    _installRecipeApi(server, standardIngredientId: _standardIngredientId);
    final densityIngredient = IngredientDetail(
      aliases: const ['水'],
      attributes: IngredientAttributes(
        density: DensityAttribute(
          estimate: false,
          source_: 'fixture',
          status: AttributeStatus.verified,
          value: 1,
        ),
      ),
      category: '饮品',
      id: _standardIngredientId,
      pinyin: 'shui',
      pinyinInitials: 'S',
      standardName: '水',
      version: 'ingredient-v1',
    );
    server.on(
      'GET',
      '/v1/ingredients/changes',
      (_) => (
        200,
        {
          'added': [densityIngredient.toJson()],
          'current_version': 'ingredient-v1',
          'merged': const [],
          'modified': const [],
          'releases': const [],
        },
      ),
    );
    server.on(
      'GET',
      '/v1/me/measures',
      (_) => (
        200,
        {
          'items': [
            {
              'id': '66666666-6666-4666-8666-666666666666',
              'name': '白瓷勺',
              'kind': 'spoon',
              'capacity_ml': 15,
              'created_at': '2026-10-02T00:00:00Z',
              'updated_at': '2026-10-02T00:00:00Z',
            },
          ],
          'next_cursor': null,
        },
      ),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
    await tester.pumpAndSettle();

    await _scrollUntilVisible(tester, find.text('自家量具'));
    await tester.tap(find.text('自家量具'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recipe-measure-picker')), findsOneWidget);
    await _scrollToBottom(tester);
    expect(find.textContaining('白瓷勺'), findsWidgets);
    expect(find.textContaining('100 克'), findsWidgets);
  });

  testWidgets('recipe detail exposes no-density fallback provenance', (
    tester,
  ) async {
    final server = FakeServer();
    final state = _installRecipeApi(server);
    final detail = Map<String, dynamic>.from(state.current);
    final version = Map<String, dynamic>.from(detail['version'] as Map);
    final snapshot = Map<String, dynamic>.from(version['snapshot'] as Map);
    final ingredients = [
      for (final raw in (snapshot['ingredients'] as List))
        Map<String, dynamic>.from(raw as Map),
    ];
    ingredients.first['quantity'] = 20;
    snapshot['ingredients'] = ingredients;
    version['snapshot'] = snapshot;
    detail['version'] = version;
    state.current = detail;
    state.versions[0] = detail;

    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
    await tester.pumpAndSettle();
    await _scrollUntilVisible(tester, find.text('汤匙/茶匙'));
    await tester.tap(find.text('汤匙/茶匙'));
    await _scrollToBottom(tester);

    expect(find.text('20 克'), findsWidgets);
    expect(find.text('按场景调整'), findsNothing);
    expect(find.text('作者填写'), findsWidgets);
    await tapVisible(tester, find.text('作者填写').last);
    expect(find.text('原来：20 g'), findsOneWidget);
    expect(find.text('现在：20 克'), findsOneWidget);
    expect(find.textContaining('没有密度数据，保留克数'), findsOneWidget);
  });

  testWidgets('recipe detail picks among multiple home measures', (
    tester,
  ) async {
    final server = FakeServer();
    final state = _installRecipeApi(
      server,
      standardIngredientId: _standardIngredientId,
    );
    final detail = Map<String, dynamic>.from(state.current);
    final version = Map<String, dynamic>.from(detail['version'] as Map);
    final snapshot = Map<String, dynamic>.from(version['snapshot'] as Map);
    final ingredients = [
      for (final raw in (snapshot['ingredients'] as List))
        Map<String, dynamic>.from(raw as Map),
    ];
    ingredients.first['quantity'] = 6;
    snapshot['ingredients'] = ingredients;
    version['snapshot'] = snapshot;
    detail['version'] = version;
    state.current = detail;
    state.versions[0] = detail;
    final densityIngredient = IngredientDetail(
      aliases: const ['水'],
      attributes: IngredientAttributes(
        density: DensityAttribute(
          estimate: false,
          source_: 'fixture',
          status: AttributeStatus.verified,
          value: 0.8,
        ),
      ),
      category: '饮品',
      id: _standardIngredientId,
      pinyin: 'shui',
      pinyinInitials: 'S',
      standardName: '水',
      version: 'ingredient-v1',
    );
    server.on(
      'GET',
      '/v1/ingredients/changes',
      (_) => (
        200,
        {
          'added': [densityIngredient.toJson()],
          'current_version': 'ingredient-v1',
          'merged': const [],
          'modified': const [],
          'releases': const [],
        },
      ),
    );
    server.on(
      'GET',
      '/v1/me/measures',
      (_) => (
        200,
        {
          'items': [
            {
              'id': '66666666-6666-4666-8666-666666666666',
              'name': '白瓷勺',
              'kind': 'spoon',
              'capacity_ml': 15,
              'created_at': '2026-10-02T00:00:00Z',
              'updated_at': '2026-10-02T00:00:00Z',
            },
            {
              'id': '77777777-7777-4777-8777-777777777777',
              'name': '陶瓷碗',
              'kind': 'bowl',
              'capacity_ml': 30,
              'created_at': '2026-10-02T00:00:00Z',
              'updated_at': '2026-10-02T00:00:00Z',
            },
          ],
          'next_cursor': null,
        },
      ),
    );

    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await _openMyRecipes(tester);
    await tester.tap(find.byKey(const ValueKey('recipe-card-$_recipeId')));
    await tester.pumpAndSettle();
    await _scrollUntilVisible(tester, find.text('自家量具'));
    await tester.tap(find.text('自家量具'));
    await _scrollToBottom(tester);
    expect(find.textContaining('约 1/2 白瓷勺（6 克）'), findsOneWidget);

    await _scrollToTop(tester);
    await _scrollUntilVisible(
      tester,
      find.byKey(const ValueKey('recipe-measure-picker')),
    );
    await tester.tap(find.byKey(const ValueKey('recipe-measure-picker')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.textContaining('陶瓷碗').last);
    await _scrollToBottom(tester);
    expect(find.textContaining('约 1/4 陶瓷碗（6 克）'), findsOneWidget);
    expect((snapshot['ingredients'] as List).first['quantity'], 6);
    expect(server.calls('POST', '/v1/recipes'), isEmpty);
  });

  testWidgets('recipe detail executes every shared serving fixture case', (
    tester,
  ) async {
    final cases = await _loadFixture(
      tester,
      'assets/serving_conversion_cases.json',
    );
    for (final caseData in cases) {
      final input = Map<String, dynamic>.from(caseData['input'] as Map);
      final expected = Map<String, dynamic>.from(caseData['expected'] as Map);
      final server = FakeServer();
      final state = _installRecipeApi(server);
      _replaceRecipeSnapshot(state, {
        'servings': input['original_servings'],
        'ingredients': input['ingredients'],
        'steps': input['steps'],
      });
      await _openRecipeDetailForFixture(tester, server);
      await _scrollUntilVisible(
        tester,
        find.byKey(const ValueKey('recipe-serving-control')),
      );
      final original = input['original_servings'] as int;
      final target = input['target_servings'] as int;
      final stepControl = target >= original
          ? find.byKey(const ValueKey('recipe-serving-increase'))
          : find.byKey(const ValueKey('recipe-serving-decrease'));
      for (var i = 0; i < (target - original).abs(); i++) {
        await tester.tap(stepControl);
        await _fixtureSettle(tester);
      }
      final servingValue = find.byKey(const ValueKey('recipe-serving-value'));
      expect(servingValue, findsOneWidget);
      expect(tester.widget<Text>(servingValue).data, '$target');

      final expectedWarnings = {
        for (final raw in (expected['warnings'] as List))
          (Map<String, dynamic>.from(raw as Map)['ingredient_id'] as String),
      };
      final expectedIngredients = [
        for (final raw in (expected['ingredients'] as List))
          Map<String, dynamic>.from(raw as Map),
      ];
      expect(
        expectedIngredients,
        hasLength((input['ingredients'] as List).length),
      );
      for (final raw in (input['ingredients'] as List)) {
        final id = (raw as Map)['id'] as String;
        final warning = find.byKey(ValueKey('recipe-serving-warning-$id'));
        if (expectedWarnings.contains(id)) {
          expect(warning, findsOneWidget, reason: 'ingredient=$id warning');
        } else {
          expect(warning, findsNothing, reason: 'ingredient=$id warning');
        }
      }
      for (final ingredient in expectedIngredients) {
        await _expectFixtureIngredient(
          tester,
          ingredient,
          expectConversionSource: target != original,
        );
      }

      final sourceSteps = [
        for (final raw in (input['steps'] as List))
          Map<String, dynamic>.from(raw as Map),
      ];
      final expectedSteps = [
        for (final raw in (expected['steps'] as List))
          Map<String, dynamic>.from(raw as Map),
      ];
      expect(expectedSteps, hasLength(sourceSteps.length));
      for (var index = 0; index < expectedSteps.length; index++) {
        expect(expectedSteps[index]['id'], sourceSteps[index]['id']);
        await _expectFixtureStep(
          tester,
          index: index,
          source: sourceSteps[index],
          expected: expectedSteps[index],
          mold: false,
        );
      }

      if (target != original) {
        final reset = find.byKey(const ValueKey('recipe-serving-reset'));
        await _scrollUntilVisible(tester, reset, delta: const Offset(0, 500));
        await tester.tap(reset);
        await _fixtureSettle(tester);
        expect(tester.widget<Text>(servingValue).data, '$original');
      }
      await _resetPage(tester);
    }
  });

  testWidgets('recipe detail executes every shared mold fixture case', (
    tester,
  ) async {
    final cases = await _loadFixture(
      tester,
      'assets/mold_conversion_cases.json',
    );
    for (final caseData in cases) {
      final input = Map<String, dynamic>.from(caseData['input'] as Map);
      final expected = Map<String, dynamic>.from(caseData['expected'] as Map);
      final server = FakeServer();
      final state = _installRecipeApi(server);
      _replaceRecipeSnapshot(state, {
        'base_mold': input['original_mold'],
        'ingredients': input['ingredients'],
        'steps': input['steps'],
      });
      await _openRecipeDetailForFixture(tester, server);
      final moldMode = find.byKey(const ValueKey('recipe-mode-mold'));
      await _scrollUntilVisible(tester, moldMode);
      await tester.tap(moldMode);
      await _fixtureSettle(tester);
      await _setTargetMoldFromFixture(
        tester,
        Map<String, dynamic>.from(input['target_mold'] as Map),
      );
      expect(find.byKey(const ValueKey('recipe-mold-control')), findsOneWidget);
      final ratio = find.byKey(const ValueKey('recipe-mold-ratio'));
      expect(ratio, findsOneWidget);
      expect(
        tester.widget<Text>(ratio).data,
        contains((expected['area_ratio'] as num).toDouble().toStringAsFixed(2)),
      );

      final expectedIngredients = [
        for (final raw in (expected['ingredients'] as List))
          Map<String, dynamic>.from(raw as Map),
      ];
      expect(
        expectedIngredients,
        hasLength((input['ingredients'] as List).length),
      );
      for (final ingredient in expectedIngredients) {
        await _expectFixtureIngredient(
          tester,
          ingredient,
          expectConversionSource: true,
        );
      }

      final sourceSteps = [
        for (final raw in (input['steps'] as List))
          Map<String, dynamic>.from(raw as Map),
      ];
      final expectedStep = expected['step'];
      if (expectedStep == null) {
        expect(sourceSteps, isEmpty);
      } else {
        final step = Map<String, dynamic>.from(expectedStep as Map);
        expect(sourceSteps, hasLength(1));
        await _expectFixtureStep(
          tester,
          index: 0,
          source: sourceSteps.single,
          expected: {...sourceSteps.single, ...step},
          mold: true,
        );
      }
      await _resetPage(tester);
    }
  });

  testWidgets('recipe detail rounds shared half-up boundary cases', (
    tester,
  ) async {
    // Same table the server conversion tests use, so offline App rounding and
    // server Decimal ROUND_HALF_UP cannot drift apart at .xx5 boundaries.
    final cases = await _loadFixture(
      tester,
      'assets/rounding_boundary_cases.json',
    );
    for (final caseData in cases) {
      final input = Map<String, dynamic>.from(caseData['input'] as Map);
      final expected = Map<String, dynamic>.from(caseData['expected'] as Map);
      final source = Map<String, dynamic>.from(
        (input['ingredients'] as List).single as Map,
      );
      final mold = caseData['kind'] == 'mold';
      final server = FakeServer();
      final state = _installRecipeApi(server);
      _replaceRecipeSnapshot(state, {
        if (mold) 'base_mold': input['original_mold'],
        if (!mold) 'servings': input['original_servings'],
        'ingredients': input['ingredients'],
        'steps': input['steps'],
      });
      await _openRecipeDetailForFixture(tester, server);
      if (mold) {
        final moldMode = find.byKey(const ValueKey('recipe-mode-mold'));
        await _scrollUntilVisible(tester, moldMode);
        await tester.tap(moldMode);
        await _fixtureSettle(tester);
        await _setTargetMoldFromFixture(
          tester,
          Map<String, dynamic>.from(input['target_mold'] as Map),
        );
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('recipe-mold-ratio')))
              .data,
          contains(
            (expected['area_ratio'] as num).toDouble().toStringAsFixed(2),
          ),
        );
      } else {
        await _scrollUntilVisible(
          tester,
          find.byKey(const ValueKey('recipe-serving-control')),
        );
        final steps =
            (input['target_servings'] as int) -
            (input['original_servings'] as int);
        expect(steps, isPositive);
        for (var i = 0; i < steps; i++) {
          await tester.tap(
            find.byKey(const ValueKey('recipe-serving-increase')),
          );
          await _fixtureSettle(tester);
        }
      }
      await _expectFixtureIngredient(tester, {
        'id': source['id'],
        'unit': source['unit'],
        'original_quantity': source['quantity'],
        'display_quantity': expected['display_quantity'],
        'rule': mold ? 'mold_ratio' : 'proportional',
      }, expectConversionSource: true);
      await _resetPage(tester);
    }
  });

  testWidgets(
    'recipe detail executes every shared measure display fixture case',
    (tester) async {
      final cases = await _loadFixture(
        tester,
        'assets/measure_display_cases.json',
      );
      const densityId = '99999999-9999-4999-8999-999999999999';
      for (final caseData in cases) {
        final input = Map<String, dynamic>.from(caseData['input'] as Map);
        final expected = Map<String, dynamic>.from(caseData['expected'] as Map);
        final server = FakeServer();
        final state = _installRecipeApi(
          server,
          standardIngredientId: densityId,
        );
        final density = input['density'] as num?;
        final ingredient = <String, dynamic>{
          'id': 'display-ingredient',
          'display_name': '显示测试食材',
          'quantity': input['base_quantity'],
          'unit': input['base_unit'],
          'scaling_mode': 'proportional',
          if (density != null) 'ingredient_id': densityId,
        };
        _replaceRecipeSnapshot(state, {
          'ingredients': [ingredient],
          'steps': const [],
        });
        if (density != null) {
          final densityJson = _standardIngredientJson();
          densityJson['id'] = densityId;
          densityJson['attributes'] = {
            'density': {
              'estimate': false,
              'value': density,
              'source': 'display fixture',
              'status': 'verified',
            },
          };
          server.on(
            'GET',
            '/v1/ingredients/changes',
            (_) => (
              200,
              {
                'added': [densityJson],
                'current_version': 'ingredient-v1',
                'merged': const [],
                'modified': const [],
                'releases': const [],
              },
            ),
          );
        }
        final measure = input['measure'];
        if (measure != null) {
          final measureJson = Map<String, dynamic>.from(measure as Map)
            ..['id'] = 'fixture-measure'
            ..['created_at'] = '2026-10-02T00:00:00Z'
            ..['updated_at'] = '2026-10-02T00:00:00Z';
          server.on(
            'GET',
            '/v1/me/measures',
            (_) => (
              200,
              {
                'items': [measureJson],
                'next_cursor': null,
              },
            ),
          );
        }
        await _openRecipeDetailForFixture(tester, server);
        await _scrollUntilVisible(
          tester,
          find.byKey(const ValueKey('recipe-measure-mode')),
        );
        final mode = input['mode'] as String;
        final label = switch (mode) {
          'base' => '克/毫升',
          'standard' => '汤匙/茶匙',
          _ => '自家量具',
        };
        await tester.tap(find.text(label));
        await _fixtureSettle(tester);
        expect(
          find.byKey(const ValueKey('recipe-display-mode-selector')),
          findsOneWidget,
        );
        if (mode == 'home') {
          await _scrollUntilVisible(
            tester,
            find.byKey(const ValueKey('recipe-measure-picker')),
          );
        }
        await _expectFixtureDisplayOutput(tester, input, expected);
        await _resetPage(tester);
      }
    },
  );
}
