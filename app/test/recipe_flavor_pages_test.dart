import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

const standardId = '44444444-4444-4444-8444-444444444444';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  tester.testTextInput.hide();
  // Keep a mounted expansion open instead of unloading its lazy list row.
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder);
    await settle(tester);
    return;
  }
  final detail = find.byKey(const ValueKey('recipe-detail-content'));
  final body = detail.evaluate().isNotEmpty
      ? detail
      : find.byKey(const ValueKey('recipe-editor-content'));
  for (var i = 0; i < 8; i++) {
    await tester.drag(body, const Offset(0, 500));
    await tester.pump(const Duration(milliseconds: 50));
  }
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.drag(body, const Offset(0, -250));
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await settle(tester);
}

const recipeId = '11111111-1111-4111-8111-111111111111';

Map<String, dynamic> detail(RecipeSnapshot snapshot) => RecipeDetail(
  id: recipeId,
  dish: DishOut(id: recipeId, name: '贡献验收菜', aliases: const []),
  author: RecipeAuthor(id: testUser().id, nickname: '味友0001'),
  visibility: RecipeDetailVisibilityEnum.private,
  createdAt: '2026-10-01T00:00:00+00:00',
  updatedAt: '2026-10-01T00:00:00+00:00',
  version: RecipeVersionOut(
    id: '22222222-2222-4222-8222-222222222222',
    versionNumber: 1,
    snapshot: snapshot,
    derived: RecipeDerived(activeTimeSeconds: 0, totalTimeSeconds: 0),
    images: const [],
    aiAssisted: false,
    editOperations: const [],
    changeNote: '',
    createdAt: '2026-10-01T00:00:00+00:00',
  ),
).toJson();

void main() {
  testWidgets('选择标准食材后能修改这道菜的贡献并查看真实来源', (tester) async {
    final server = FakeServer();
    Map<String, dynamic>? current;
    server.on(
      'POST',
      '/v1/recipes/safety/check',
      (_) => (
        200,
        RecipeSafetyCheckOut(
          result: RecipeSafetyResult(
            rulesVersion: 'test-v1',
            checkedAt: '2026-10-01T00:00:00+00:00',
            canSave: true,
            findings: const [],
          ),
        ).toJson(),
      ),
    );
    server.on('POST', '/v1/recipes', (record) {
      final payload = record.body as Map;
      current = detail(
        RecipeSnapshot.fromJson(
          Map<String, dynamic>.from(payload['snapshot'] as Map),
        ),
      );
      return (201, current);
    });
    server.on('GET', '/v1/recipes/$recipeId', (_) => (200, current));
    server.on('POST', '/v1/recipes/$recipeId/versions', (record) {
      final payload = record.body as Map;
      current = detail(
        RecipeSnapshot.fromJson(
          Map<String, dynamic>.from(payload['snapshot'] as Map),
        ),
      );
      return (201, current);
    });
    final ingredient = IngredientDetail(
      id: standardId,
      standardName: '生抽',
      aliases: const ['酱油'],
      pinyin: 'shengchou',
      pinyinInitials: 'SC',
      category: '调料',
      version: '1.0.0',
      attributes: IngredientAttributes(
        flavor: FlavorAttribute(
          source_: 'AI 起草、待核对',
          status: AttributeStatus.aiDraft,
          estimate: true,
          value: FlavorProfile(salty: 3, umami: 2),
        ),
        functional: BoolAttribute(
          source_: '人工整理',
          status: AttributeStatus.verified,
          estimate: false,
          value: true,
        ),
      ),
    );
    server.on(
      'GET',
      '/v1/ingredients/changes',
      (_) => (
        200,
        {
          'added': [ingredient.toJson()],
          'current_version': '1.0.0',
          'merged': const [],
          'modified': const [],
          'releases': const [],
        },
      ),
    );
    final env = TestEnv.signedIn(server: server);
    await pumpApp(tester, env: env);
    await tester.tap(find.byKey(const ValueKey('primary-create-button')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
    await settle(tester);
    final search = find.byKey(const ValueKey('recipe-ingredient-search'));
    await reveal(tester, search);
    await tester.enterText(search, '生抽');
    await tester.tap(find.byKey(const ValueKey('recipe-search-ingredient')));
    await settle(tester);
    final result = find.byKey(
      const ValueKey('ingredient-result-$standardId-ingredient-1'),
    );
    await reveal(tester, result);
    await tester.tap(result);
    await settle(tester);
    final flavor = find.byKey(
      const ValueKey('recipe-flavor-editor-ingredient-1'),
    );
    await reveal(tester, flavor);
    expect(find.textContaining('咸 3'), findsWidgets);
    expect(find.textContaining('鲜 2'), findsWidgets);
    final mark = find.byKey(
      const ValueKey('recipe-flavor-source-ingredient-1'),
    );
    await reveal(tester, mark);
    await tester.tap(mark);
    await settle(tester);
    expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
    expect(find.textContaining('待核对'), findsWidgets);
    expect(find.text('已验证'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);
    final edit = find.byKey(
      const ValueKey('recipe-flavor-expand-ingredient-1'),
    );
    await reveal(tester, edit);
    await tester.tap(edit);
    await settle(tester);
    final salty = find.byKey(
      const ValueKey('recipe-flavor-salty-ingredient-1'),
    );
    await reveal(tester, salty);
    await tester.tap(salty);
    await settle(tester);
    await tester.tap(find.text('咸 1').last);
    await settle(tester);
    expect(find.textContaining('咸 1'), findsWidgets);
    expect(find.text('作者填写'), findsWidgets);
    final advanced = find.byKey(
      const ValueKey('recipe-ingredient-advanced-ingredient-1'),
    );
    await reveal(tester, advanced);
    await tester.tap(advanced);
    await settle(tester);
    final functional = find.byKey(
      const ValueKey('recipe-ingredient-functional-ingredient-1'),
    );
    await reveal(tester, functional);
    await tester.tap(functional);
    await settle(tester);
    expect(find.text('不作功能性用料'), findsWidgets);
    // Restarting the actual page exercises restoration, not the draft serializer.
    await restartApp(tester, env);
    await tester.tap(find.byKey(const ValueKey('primary-create-button')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
    await settle(tester);
    expect(find.text('恢复未保存修改？'), findsOneWidget);
    await tester.tap(find.text('恢复'));
    await settle(tester);
    await reveal(tester, flavor);
    expect(find.textContaining('咸 1'), findsWidgets);
    expect(find.textContaining('鲜 2'), findsWidgets);
    expect(find.text('不作功能性用料'), findsWidgets);
    final name = find.byKey(const ValueKey('recipe-dish-name'));
    await reveal(tester, name);
    await tester.enterText(name, '贡献验收菜');
    final quantity = find.byKey(const ValueKey('recipe-ingredient-quantity'));
    await reveal(tester, quantity);
    await tester.enterText(quantity, '15');
    final step = find.byKey(const ValueKey('recipe-step-instruction'));
    await reveal(tester, step);
    await tester.enterText(step, '拌匀');
    final save = find.byKey(const ValueKey('save-recipe-button'));
    await reveal(tester, save);
    await tester.tap(save);
    await settle(tester);
    final summary = find.byKey(
      const ValueKey('recipe-flavor-detail-ingredient-1'),
    );
    await reveal(tester, summary);
    expect(find.textContaining('咸 1'), findsWidgets);
    expect(find.textContaining('鲜 2'), findsWidgets);
    expect(find.text('不作功能性用料'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('edit-recipe-button')));
    await settle(tester);
    await reveal(tester, flavor);
    expect(find.textContaining('咸 1'), findsWidgets);
    expect(find.textContaining('鲜 2'), findsWidgets);
    expect(find.text('不作功能性用料'), findsWidgets);
    // Clearing every axis is an explicit unknown value, including after save.
    await reveal(tester, edit);
    if (salty.evaluate().isEmpty) {
      await tester.tap(edit);
      await settle(tester);
    }
    for (final axis in const {
      'salty': '咸',
      'sweet': '甜',
      'sour': '酸',
      'spicy': '辣',
      'umami': '鲜',
      'numbing': '麻',
      'oily': '油',
    }.entries) {
      final field = find.byKey(
        ValueKey('recipe-flavor-${axis.key}-ingredient-1'),
      );
      await reveal(tester, field);
      await tester.tap(field);
      await settle(tester);
      await tester.tap(find.text('${axis.value} 未填写').last);
      await settle(tester);
    }
    await reveal(tester, save);
    await tester.tap(save);
    await settle(tester);
    await reveal(tester, summary);
    expect(find.text('味型贡献未填写'), findsWidgets);
    expect(find.textContaining('咸 0'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('edit-recipe-button')));
    await settle(tester);
    await reveal(tester, flavor);
    expect(find.text('味型贡献未填写'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
  });
}
