import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gram_tree/util/ids.dart';

import 'event_pipeline_support.dart'
    show accessTokenOf, containerOf, devServer, signInFreshUser;

const _dish = '网页场景验收鸡肉';
const _prepInstruction = '切好鸡肉，备好盐';
const _instruction = '炒熟鸡肉，关火后加盐';
const _note = '观察中心熟透后再出锅';

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _pump(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _wait(WidgetTester tester, Finder finder) async {
  final binding = IntegrationTestWidgetsFlutterBinding.instance;
  binding.reportData = {
    ...?binding.reportData,
    'e2e_wait_for': finder.toString(),
  };
  for (var i = 0; i < 150 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
  await _pump(tester);
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  if (tester.testTextInput.isRegistered) tester.testTextInput.hide();
  final body = _key('recipe-detail-content');
  if (finder.evaluate().isEmpty) {
    for (var i = 0; i < 12; i++) {
      await tester.drag(body, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 45 && finder.evaluate().isEmpty; i++) {
      await tester.drag(body, const Offset(0, -250));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  await _wait(tester, finder);
  await tester.ensureVisible(finder.last);
  await _pump(tester);
  expect(finder.last.hitTestable(), findsOneWidget);
}

Future<void> _tap(
  WidgetTester tester,
  Finder finder, {
  bool inRecipe = false,
}) async {
  if (inRecipe) {
    await _reveal(tester, finder);
  } else {
    await _wait(tester, finder);
    await tester.ensureVisible(finder.last);
    await _pump(tester);
  }
  await tester.tap(finder.last.hitTestable());
  await _pump(tester);
}

Future<void> _revealCooking(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).first;
  if (finder.evaluate().isEmpty) {
    for (var i = 0; i < 12; i++) {
      await tester.drag(scrollable, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: scrollable,
    maxScrolls: 20,
  );
  await _pump(tester);
  expect(finder.last.hitTestable(), findsOneWidget);
}

Future<void> _tapCooking(WidgetTester tester, Finder finder) async {
  await _revealCooking(tester, finder);
  await tester.tap(finder.last.hitTestable());
  await _pump(tester);
}

Future<void> _back(WidgetTester tester) =>
    _tap(tester, _key('recipe-list-button'));

Future<void> _openRecipe(WidgetTester tester) async {
  await _tap(tester, find.text(_dish).last);
  await _wait(tester, _key('recipe-detail-content'));
  await _wait(tester, _key('scenario-detail-brief'));
}

Map<String, dynamic> _recipeInput() => {
  'dish_name': _dish,
  'snapshot': {
    'format_version': 1,
    'servings': 2,
    'ingredients': [
      {
        'id': 'salt',
        'display_name': '盐',
        'quantity': 10,
        'unit': 'g',
        'flavor_contribution': {'salty': 3},
        'flavor_source': {'source': 'author_filled'},
      },
      {'id': 'chicken', 'display_name': '鸡肉', 'quantity': 200, 'unit': 'g'},
    ],
    'steps': [
      {
        'id': 'prep',
        'action': '切',
        'instruction': _prepInstruction,
        'ingredient_ids': ['chicken'],
        'duration_seconds': 60,
      },
      {
        'id': 'cook',
        'depends_on': ['prep'],
        'action': '炒',
        'instruction': _instruction,
        'ingredient_ids': ['chicken', 'salt'],
        'duration_seconds': 120,
        'heat': '中火',
        'cookware': '炒锅',
        'doneness': '中心熟透',
        'notes': _note,
      },
    ],
  },
};

Future<Map<String, dynamic>> _get(String path, Options auth) async =>
    (await devServer.get<Map<String, dynamic>>(path, options: auth)).data!;

Future<Map<String, dynamic>> _post(
  String path,
  Map<String, dynamic> data,
  Options auth,
) async => (await devServer.post<Map<String, dynamic>>(
  path,
  data: data,
  options: auth,
)).data!;

Future<void> _saltProfile(Options auth, double coefficient) async {
  await devServer.patch<Map<String, dynamic>>(
    '/v1/me/taste-profile',
    data: {
      'flavors': {'salty': coefficient},
    },
    options: auth,
  );
}

Future<void> _seedHistory(Options auth, Map<String, dynamic> recipe) async {
  await _saltProfile(auth, 0.75);
  final projection = await _post(
    '/v1/recipes/${recipe['id']}/personalized',
    {},
    auth,
  );
  expect((projection['ingredients'] as List).first['display_quantity'], 7.5);
  final version = Map<String, dynamic>.from(recipe['version'] as Map);
  // A cooking record freezes the quantities actually executed, not author input.
  version['snapshot'] = projection['snapshot'];
  final executed = {...recipe, 'version': version};
  String? latestRecord;
  for (var i = 0; i < 10; i++) {
    final record = await _post('/v1/records', {
      'client_id': newUuidV4(),
      'dish_name': _dish,
      'source': 'cooking_session',
      'verification': 'unverified',
      'recipe_id': recipe['id'],
      'recipe_version_id': version['id'],
      'snapshot': {'format_version': 1, 'detail': executed},
      'source_context': {
        'completed_steps': ['prep', 'cook'],
        'skipped_steps': <String>[],
      },
    }, auth);
    latestRecord = record['id'] as String;
  }
  await _post('/v1/records/$latestRecord/revisions', {
    'revision_id': newUuidV4(),
    'field': 'feedback',
    'value': {
      'taste_tags': ['肉太干'],
    },
  }, auth);
  await _saltProfile(auth, 1.25);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('真实登录后首次详细、熟练差异、失败提醒和口味变化预览贯穿页面', (tester) async {
    if (kIsWeb) {
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
    }
    try {
      await signInFreshUser(tester);
      final auth = Options(
        headers: {
          'Authorization': 'Bearer ${accessTokenOf(containerOf(tester))}',
        },
      );
      final recipe = await _post('/v1/recipes', _recipeInput(), auth);
      final recipeId = recipe['id'] as String;

      await _tap(tester, find.text('我的'));
      await _tap(tester, _key('my-recipes-list-entry'));
      await _openRecipe(tester);
      await _reveal(tester, find.text('详细步骤'));
      await _reveal(tester, find.textContaining(_note));
      await _tap(tester, _key('scenario-detail-brief'), inRecipe: true);
      await _reveal(tester, find.text('紧凑清单'));
      expect((await _get('/v1/ui/preferences', auth))['detail'], 'auto');
      await _back(tester);
      await _openRecipe(tester);
      await _reveal(tester, find.text('详细步骤'));
      await _back(tester);

      await _seedHistory(auth, recipe);
      await _openRecipe(tester);
      final differenceId = 'scene:difference:$recipeId';
      await _reveal(tester, _key(differenceId));
      await _reveal(tester, find.text('紧凑清单'));
      expect(find.textContaining('上次 7.5 g'), findsNothing);
      await _tap(tester, _key('$differenceId:expand'), inRecipe: true);
      await _reveal(tester, find.textContaining('上次 7.5 g'));
      expect(find.textContaining('本次 12.5 g'), findsWidgets);
      await _reveal(tester, _key('scenario-expand-steps'));
      expect(find.textContaining(_instruction), findsNothing);
      await _tap(tester, _key('scenario-expand-steps'), inRecipe: true);
      await _reveal(tester, find.textContaining(_instruction));
      await _reveal(tester, _key('scene:failure:$recipeId:dry_meat:cook:at'));
      await _reveal(tester, _key('recipe-food-safety-card'));
      await _reveal(tester, _key('recipe-allergen-card'));

      final history = await _get('/v1/me/taste-profile/changes', auth);
      final change = (history['items'] as List).cast<Map>().firstWhere(
        (row) =>
            row['field'] == 'flavors.salty' &&
            (row['new_value'] as Map)['coefficient'] == 1.25,
      );
      final changeId = change['id'] as String;
      final tasteId = 'scene:taste:$changeId';
      final currentProfile = await _get('/v1/me/taste-profile', auth);
      await _reveal(tester, find.text('盐  12.5 g'));
      await _tap(
        tester,
        _key('$tasteId:show_before_taste_change'),
        inRecipe: true,
      );
      await _reveal(tester, find.text('盐  7.5 g'));
      expect(find.text('盐  10 g'), findsNothing);
      expect(await _get('/v1/me/taste-profile', auth), currentProfile);
      await _tap(
        tester,
        _key('scenario-restore-current-taste'),
        inRecipe: true,
      );
      await _reveal(tester, find.text('盐  12.5 g'));
      await _tap(tester, _key('$tasteId:open_taste_change'), inRecipe: true);
      await _wait(tester, find.byType(AlertDialog));
      await _tap(tester, find.text('取消'));
      expect(await _get('/v1/me/taste-profile', auth), currentProfile);

      final mark = find.descendant(
        of: _key(differenceId),
        matching: find.text('按场景调整'),
      );
      await _tap(tester, mark, inRecipe: true);
      await _wait(tester, _key('why-panel'));
      await _tap(tester, find.text('这次不用'));
      await _reveal(tester, _key('scenario-detail-brief'));
      expect(_key(differenceId), findsNothing);
      expect(await _get('/v1/me/taste-profile', auth), currentProfile);
      await _back(tester);
      await _openRecipe(tester);
      await _reveal(tester, _key(differenceId));
      await _tap(tester, mark, inRecipe: true);
      await _tap(tester, find.text('以后别这样'));
      await _back(tester);
      await _openRecipe(tester);
      await _reveal(tester, _key('scenario-detail-brief'));
      expect(_key(differenceId), findsNothing);
      await _reveal(tester, _key('recipe-food-safety-card'));
      await _reveal(tester, _key('recipe-allergen-card'));
      expect(await _get('/v1/me/taste-profile', auth), currentProfile);
      await _tap(tester, _key('$tasteId:open_taste_change'), inRecipe: true);
      await _wait(tester, find.byType(AlertDialog));
      await _tap(tester, _key('scenario-confirm-revert'));
      await _reveal(tester, find.text('盐  7.5 g'));
      final revertedProfile = await _get('/v1/me/taste-profile', auth);
      expect((revertedProfile['flavors'] as Map)['salty']['coefficient'], 0.75);
      expect(_key('scenario-restore-current-taste'), findsNothing);

      await _tap(tester, _key('start-cooking-button'), inRecipe: true);
      await _wait(tester, find.text('先准备食材'));
      await _tap(tester, find.text('开始第一步'));
      final before = 'scene:failure:$recipeId:dry_meat:cook:before';
      final at = 'scene:failure:$recipeId:dry_meat:cook:at';
      await _revealCooking(tester, _key('cooking-reminders-cook-before'));
      expect(_key(before), findsOneWidget);
      expect(_key(at), findsNothing);
      await _revealCooking(tester, find.text('计时 60 秒'));
      await _revealCooking(tester, find.text('记录问题'));
      await _revealCooking(tester, find.text('下一步'));
      // A real flip must move the active step despite reminder cards adding
      // their own nested scrollables above the normal cooking controls.
      await tester.fling(
        find.byType(Scrollable).first,
        const Offset(-350, 0),
        1000,
      );
      await _pump(tester);
      await _revealCooking(tester, find.text('步骤 2 / 2'));
      await _revealCooking(tester, _key('cooking-reminders-cook-at'));
      expect(_key(at), findsOneWidget);
      expect(_key(before), findsNothing);
      await _tapCooking(tester, find.text('记录问题'));
      await _wait(tester, find.byType(AlertDialog));
      await _tap(tester, find.text('取消'));
      await _tapCooking(tester, find.text('记录临时调整'));
      await _wait(tester, find.byType(AlertDialog));
      await _tap(tester, find.text('取消'));
      await _tapCooking(tester, find.text('计时 120 秒'));
      await _revealCooking(tester, find.text('步骤计时'));
      await _tapCooking(tester, find.text('完成'));
      await _wait(tester, _key('cooking-complete'));
      expect(find.text('已完成 $_dish'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } catch (error, stack) {
      final binding = IntegrationTestWidgetsFlutterBinding.instance;
      binding.reportData = {
        ...?binding.reportData,
        'e2e_error': error.toString(),
        'e2e_stack': stack.toString(),
      };
      rethrow;
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
