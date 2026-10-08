import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:integration_test/integration_test.dart';

void _markE2eStep(String step) {
  final binding = IntegrationTestWidgetsFlutterBinding.instance;
  binding.reportData = {...?binding.reportData, 'e2e_step': step};
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final server = Dio(
    BaseOptions(baseUrl: AppConfig.fromEnvironment().apiBaseUrl),
  );

  Future<String> latestCode(String email) async {
    final response = await server.get<Map<String, dynamic>>(
      '/v1/dev/latest-email-code',
      queryParameters: {'email': email},
    );
    return response.data!['code'] as String;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await settle(tester);
    if (finder.evaluate().isEmpty) {
      final message = 'E2E waitFor failed: $finder';
      developer.log(message, name: 'integration_test');
      debugPrint(message);
      debugDumpApp();
      throw StateError(message);
    }
    expect(finder, findsWidgets);
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    tester.testTextInput.hide();
    await tester.pump();
    // Do not unload an expanded lazy tile while locating its mounted controls.
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await settle(tester);
      return;
    }
    // The page body the user scrolls, found by its public key.
    final detail = find.byKey(const ValueKey('recipe-detail-content'));
    final body = detail.evaluate().isNotEmpty
        ? detail
        : find.byKey(const ValueKey('recipe-editor-content'));
    // Sliver children outside the viewport may not exist yet. Start from the
    // top so revealing an earlier control never scrolls in the wrong direction.
    for (var i = 0; i < 12; i++) {
      await tester.drag(body, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
      await tester.drag(body, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (finder.evaluate().isEmpty) {
      final message = 'E2E reveal failed: $finder';
      developer.log(message, name: 'integration_test');
      debugPrint(message);
      debugDumpApp();
      throw StateError(message);
    }
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
  }

  Future<void> runWithDiagnostics(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    try {
      await body();
    } catch (error, stack) {
      final binding = IntegrationTestWidgetsFlutterBinding.instance;
      binding.reportData = {
        ...?binding.reportData,
        'e2e_error': error.toString(),
        'e2e_stack': stack.toString(),
      };
      debugPrint('E2E failure: $error');
      debugDumpApp();
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await settle(tester);
    await tester.tap(finder);
    await settle(tester);
  }

  testWidgets(
    '登录后可以新建、保存、查看历史并删除菜谱',
    (tester) => runWithDiagnostics(tester, () async {
      final email =
          'recipe-authoring-${DateTime.now().microsecondsSinceEpoch}@example.com';
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);

      await app.main();
      await settle(tester);
      final consent = find.text('开始之前，先说清楚我们会用到什么');
      if (consent.evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const ValueKey('consent-agree')));
        await settle(tester);
      } else {
        // A preceding integration target may have persisted current consent;
        // never let this branch bypass the authenticated gate silently.
        expect(find.text('登录味谱'), findsOneWidget);
      }

      await waitFor(tester, find.text('登录味谱'));
      await tester.enterText(find.byKey(const ValueKey('login-email')), email);
      await tapText(tester, '发送验证码');
      await waitFor(tester, find.text('输入验证码'));
      await tester.enterText(
        find.byKey(const ValueKey('code-input')),
        await latestCode(email),
      );
      // Only this sentence is emitted by a successful server composition; the
      // fallback layout also contains "今天还没有安排" and is not a readiness
      // signal for this full-flow acceptance test.
      await waitFor(tester, find.text('先添加一道你常做的菜'));
      expect(find.text('今天还没有安排'), findsOneWidget);

      await waitFor(
        tester,
        find.byKey(const ValueKey('primary-create-button')),
      );
      await tester.tap(find.byKey(const ValueKey('primary-create-button')));
      await settle(tester);
      await waitFor(tester, find.byKey(const ValueKey('create-recipe-entry')));
      await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
      await settle(tester);
      await waitFor(tester, find.byKey(const ValueKey('recipe-dish-name')));
      await tester.enterText(
        find.byKey(const ValueKey('recipe-dish-name')),
        '网页版验收菜谱',
      );
      final ingredient = find.byKey(const ValueKey('recipe-ingredient-search'));
      await reveal(tester, ingredient);
      await tester.enterText(ingredient, '鸡肉');
      final flavorExpand = find.byKey(
        const ValueKey('recipe-flavor-expand-ingredient-1'),
      );
      await reveal(tester, flavorExpand);
      await tester.tap(flavorExpand);
      await settle(tester);
      final salty = find.byKey(
        const ValueKey('recipe-flavor-salty-ingredient-1'),
      );
      await reveal(tester, salty);
      await tester.tap(salty);
      await settle(tester);
      await tester.tap(find.text('咸 3').last);
      await settle(tester);
      final umami = find.byKey(
        const ValueKey('recipe-flavor-umami-ingredient-1'),
      );
      await reveal(tester, umami);
      await tester.tap(umami);
      await settle(tester);
      await tester.tap(find.text('鲜 2').last);
      await settle(tester);
      final addIngredient = find.byKey(const ValueKey('recipe-add-ingredient'));
      await reveal(tester, addIngredient);
      await tester.tap(addIngredient);
      await settle(tester);
      final secondSearch = find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField &&
            widget.key is ValueKey<String> &&
            (widget.key as ValueKey<String>).value.startsWith(
              'recipe-ingredient-search-ingredient-',
            ),
      );
      await reveal(tester, secondSearch);
      final searchKey =
          (tester.widget(secondSearch).key as ValueKey<String>).value;
      final secondId = searchKey.substring('recipe-ingredient-search-'.length);
      await tester.enterText(secondSearch, '测试酱油');
      await tester.tap(
        find.byKey(ValueKey('recipe-search-ingredient-$secondId')),
      );
      final standardChoice = find.byWidgetPredicate(
        (widget) =>
            widget is ListTile &&
            widget.key is ValueKey<String> &&
            (widget.key as ValueKey<String>).value.startsWith(
              'ingredient-result-',
            ),
      );
      await waitFor(tester, standardChoice);
      await reveal(tester, standardChoice.first);
      await tester.tap(standardChoice.first);
      await settle(tester);
      final secondQuantity = find.byKey(
        ValueKey('recipe-ingredient-quantity-$secondId'),
      );
      await reveal(tester, secondQuantity);
      await tester.enterText(secondQuantity, '15');
      await tester.enterText(
        find.byKey(ValueKey('recipe-ingredient-unit-$secondId')),
        'ml',
      );
      final secondFlavor = find.byKey(
        ValueKey('recipe-flavor-expand-$secondId'),
      );
      await reveal(tester, secondFlavor);
      await tester.tap(secondFlavor);
      await settle(tester);
      final secondSalty = find.byKey(ValueKey('recipe-flavor-salty-$secondId'));
      await reveal(tester, secondSalty);
      await tester.tap(secondSalty);
      await settle(tester);
      await tester.tap(find.text('咸 3').last);
      await settle(tester);
      final step = find.byKey(const ValueKey('recipe-step-instruction'));
      await reveal(tester, step);
      await tester.enterText(step, '将鸡肉炒 2 分钟');
      await settle(tester);
      final dishName = find.byKey(const ValueKey('recipe-dish-name'));
      await reveal(tester, dishName);
      await tester.enterText(dishName, '降血糖网页版验收菜谱');
      await reveal(tester, find.byKey(const ValueKey('save-recipe-button')));
      await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
      await waitFor(tester, find.byKey(const ValueKey('recipe-save-error')));
      expect(find.textContaining('改写'), findsWidgets);
      expect(
        find.byKey(const ValueKey('recipe-editor-content')),
        findsOneWidget,
      );
      await reveal(tester, dishName);
      await tester.enterText(dishName, '网页版验收菜谱');
      await reveal(tester, find.byKey(const ValueKey('save-recipe-button')));
      await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-history-button')),
      );
      expect(find.text('网页版验收菜谱'), findsWidgets);
      final contributionDetail = find.byKey(
        const ValueKey('recipe-flavor-detail-ingredient-1'),
      );
      final selectedContribution = find.byKey(
        ValueKey('recipe-flavor-detail-$secondId'),
      );
      await reveal(tester, selectedContribution);
      expect(
        find.descendant(
          of: selectedContribution,
          matching: find.textContaining('咸 3'),
        ),
        findsOneWidget,
      );
      await reveal(tester, contributionDetail);
      expect(find.textContaining('咸 3'), findsWidgets);
      expect(find.textContaining('鲜 2'), findsWidgets);
      final contributionSource = find.byKey(
        const ValueKey('recipe-flavor-source-ingredient-1'),
      );
      await tester.tap(contributionSource);
      await settle(tester);
      expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
      expect(find.textContaining('作者按这道菜'), findsWidgets);
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
      await reveal(tester, find.byKey(const ValueKey('recipe-allergen-card')));
      expect(find.textContaining('可能不完整'), findsWidgets);
      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-food-safety-card')),
      );
      expect(find.textContaining('74'), findsWidgets);
      expect(find.byTooltip('关闭安全提醒'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('recipe-history-button')));
      await waitFor(tester, find.byKey(const ValueKey('recipe-version-1')));
      expect(find.textContaining('第 1 版'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('recipe-version-1')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('edit-old-recipe-button')),
      );
      await tester.tap(find.byKey(const ValueKey('edit-old-recipe-button')));
      await waitFor(tester, find.byKey(const ValueKey('recipe-dish-name')));
      expect(find.text('网页版验收菜谱'), findsWidgets);
      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-flavor-editor-ingredient-1')),
      );
      expect(find.textContaining('咸 3'), findsWidgets);
      expect(find.textContaining('鲜 2'), findsWidgets);
      await reveal(tester, find.bySemanticsLabel('这次改了什么'));
      await tester.enterText(find.bySemanticsLabel('这次改了什么'), '从第一版继续修改');
      final doneness = find.byKey(
        const ValueKey('recipe-step-doneness-step-1'),
      );
      await reveal(tester, doneness);
      await tester.enterText(doneness, '中心无粉红、汁液清澈');
      await reveal(tester, find.byKey(const ValueKey('save-recipe-button')));
      await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-history-button')),
      );
      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-food-safety-card')),
      );
      expect(find.textContaining('未发现'), findsWidgets);
      expect(find.textContaining('74'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('recipe-history-button')));
      await waitFor(tester, find.byKey(const ValueKey('recipe-version-2')));
      expect(find.byKey(const ValueKey('recipe-version-1')), findsOneWidget);
      expect(find.textContaining('从第一版继续修改'), findsOneWidget);
      await tester.tap(find.byTooltip('返回').last);
      await waitFor(tester, find.byKey(const ValueKey('recipe-list-button')));
      await tester.tap(find.byKey(const ValueKey('recipe-list-button')));
      await waitFor(tester, find.text('网页版验收菜谱'));
      final recipeCard = find.text('网页版验收菜谱').last;
      expect(recipeCard, findsOneWidget);
      await tester.ensureVisible(recipeCard);
      await tester.tap(recipeCard);
      // The public, always-built content boundary signals that the HTTP detail
      // has loaded. On a small phone the delete control is a lazy sliver child;
      // scrolling is a user operation, not something waitFor can substitute for.
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-detail-content')),
      );
      _markE2eStep('after_detail_loaded');
      await reveal(tester, find.byKey(const ValueKey('delete-recipe-button')));
      await tester.tap(find.byKey(const ValueKey('delete-recipe-button')));
      await settle(tester);
      await waitFor(tester, find.text('确认删除'));
      await tester.tap(find.text('确认删除'));
      await waitFor(tester, find.text('还没有菜谱'));
      _markE2eStep('after_delete');
    }),
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
