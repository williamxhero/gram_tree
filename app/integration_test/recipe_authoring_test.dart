import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'event_pipeline_support.dart' show resetLocalAppState;

void _markE2eStep(String step) {
  debugPrint('E2E step: $step');
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
    _markE2eStep('reveal: $finder');
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
    final comparison = find.byKey(const ValueKey('full-comparison-content'));
    final body = comparison.evaluate().isNotEmpty
        ? comparison
        : detail.evaluate().isNotEmpty
        ? detail
        : find.byKey(const ValueKey('recipe-editor-content'));
    final scrollable = find
        .descendant(
          of: body,
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        )
        .first;
    final position = tester.state<ScrollableState>(scrollable).position;
    // Move the viewport in bounded steps to mount lazy children, just as
    // ensureVisible positions mounted controls. This avoids platform flings
    // and input-field gesture arenas without bypassing the visible UI.
    position.jumpTo(position.minScrollExtent);
    await settle(tester);
    for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
      position.jumpTo(
        (position.pixels + 300).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
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
    await settle(tester);
    // A cached lazy child can be built yet outside the phone viewport. Check
    // actual hit testing, not only existence, before performing an action.
    for (var i = 0; i < 8 && finder.hitTestable().evaluate().isEmpty; i++) {
      position.jumpTo(
        (position.pixels + 100).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      await settle(tester);
    }
    expect(finder.hitTestable(), findsOneWidget);
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

      // iOS Keychain survives app uninstall; start this fixture signed out.
      await resetLocalAppState();
      await app.main();
      await settle(tester);
      final consent = find.text('开始之前，先说清楚我们会用到什么');
      if (consent.evaluate().isNotEmpty) {
        await tester.ensureVisible(find.byKey(const ValueKey('consent-agree')));
        await settle(tester);
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

      // A random default nickname can contain the safety threshold "74" and
      // collide with the later whole-page absence assertion. Set the actor's
      // display name through the real profile UI, preserving that assertion.
      await tapText(tester, '我的');
      await waitFor(tester, find.byKey(const ValueKey('me-nickname')));
      await tester.tap(find.byTooltip('改昵称'));
      await waitFor(tester, find.byKey(const ValueKey('nickname-input')));
      await tester.enterText(
        find.byKey(const ValueKey('nickname-input')),
        '菜谱验收作者',
      );
      await tapText(tester, '保存');
      await waitFor(tester, find.text('菜谱验收作者'));
      await tapText(tester, '今天');
      await waitFor(tester, find.text('先添加一道你常做的菜'));

      await waitFor(
        tester,
        find.byKey(const ValueKey('primary-create-button')),
      );
      await tester.tap(find.byKey(const ValueKey('primary-create-button')));
      await settle(tester);
      await waitFor(tester, find.byKey(const ValueKey('create-recipe-entry')));
      await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
      await settle(tester);
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-editor-content')),
      );
      await reveal(tester, find.byKey(const ValueKey('recipe-dish-name')));
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
      final secondSearchButton = find.byKey(
        ValueKey('recipe-search-ingredient-$secondId'),
      );
      await reveal(tester, secondSearchButton);
      await tester.tap(secondSearchButton);
      await settle(tester);
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
      final ingredientQuantity = find.byKey(
        const ValueKey('recipe-ingredient-quantity'),
      );
      await reveal(tester, ingredientQuantity);
      await tester.enterText(ingredientQuantity, '300');
      // Deterministic comparison needs authored execution structure; it must
      // not infer an action from the instruction text or the stable step ID.
      final stepAction = find.byKey(
        const ValueKey('recipe-step-action-step-1'),
      );
      await reveal(tester, stepAction);
      await tester.enterText(stepAction, '炒');
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
      final selectedFlavorText = find.descendant(
        of: selectedContribution,
        matching: find.textContaining('咸 3'),
      );
      // A summary Column spans the row, but its center may be blank. Reveal
      // the painted text whose visibility we assert, not the container center.
      await reveal(tester, selectedFlavorText);
      expect(selectedFlavorText, findsOneWidget);
      await reveal(
        tester,
        find.descendant(
          of: contributionDetail,
          matching: find.textContaining('咸 3'),
        ),
      );
      expect(find.textContaining('咸 3'), findsWidgets);
      expect(find.textContaining('鲜 2'), findsWidgets);
      final contributionSource = find.byKey(
        const ValueKey('recipe-flavor-source-ingredient-1'),
      );
      await reveal(tester, contributionSource);
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
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-editor-content')),
      );
      await reveal(tester, find.byKey(const ValueKey('recipe-dish-name')));
      expect(find.text('网页版验收菜谱'), findsWidgets);
      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-flavor-editor-ingredient-1')),
      );
      expect(find.textContaining('咸 3'), findsWidgets);
      expect(find.textContaining('鲜 2'), findsWidgets);
      await reveal(tester, find.bySemanticsLabel('这次改了什么'));
      await tester.enterText(find.bySemanticsLabel('这次改了什么'), '从第一版继续修改');
      await reveal(tester, stepAction);
      expect(
        find.descendant(of: stepAction, matching: find.text('炒')),
        findsOneWidget,
      );
      final doneness = find.byKey(
        const ValueKey('recipe-step-doneness-step-1'),
      );
      await reveal(tester, doneness);
      await tester.enterText(doneness, '中心无粉红、汁液清澈');
      await reveal(tester, ingredientQuantity);
      await tester.enterText(ingredientQuantity, '200');
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
      await tester.tap(find.byKey(const ValueKey('recipe-compare-previous-2')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('ingredient-comparison-content')),
      );
      expect(find.text('仅比较食材，尚未比较步骤'), findsOneWidget);
      expect(find.text('已按 2 人份对比'), findsOneWidget);
      expect(find.text('用量变化'), findsOneWidget);
      expect(find.textContaining('−33.3%'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('compare-show-all')));
      await settle(tester);
      await tester.tap(find.byTooltip('返回').last);
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-select-comparison')),
      );
      await tester.tap(find.byKey(const ValueKey('recipe-select-comparison')));
      await settle(tester);
      await tester.tap(find.textContaining('· 第 1 版'));
      await settle(tester);
      await tester.tap(find.textContaining('· 第 2 版'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('recipe-compare-selected')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('ingredient-comparison-content')),
      );
      await tester.tap(find.byKey(const ValueKey('compare-detail-a')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('edit-old-recipe-button')),
      );
      await reveal(tester, find.textContaining('300', findRichText: true));
      expect(find.textContaining('300', findRichText: true), findsWidgets);
      // Return through the real page controls; details deliberately use the
      // recipe list as their back destination, rather than test router calls.
      await tester.tap(find.byKey(const ValueKey('recipe-history-button')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-compare-previous-2')),
      );
      await tester.tap(find.byKey(const ValueKey('recipe-compare-previous-2')));
      await waitFor(tester, find.byKey(const ValueKey('compare-detail-b')));
      await tester.tap(find.byKey(const ValueKey('compare-detail-b')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('edit-old-recipe-button')),
      );
      await reveal(tester, find.textContaining('200', findRichText: true));
      expect(find.textContaining('200', findRichText: true), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('recipe-history-button')));
      await waitFor(tester, find.byKey(const ValueKey('recipe-version-2')));
      _markE2eStep('ingredient_comparison_completed');
      // The full comparison is additive: all ingredient-only assertions above
      // remain, then the same authored history opens the new deterministic view.
      final fullPrevious = find.byKey(
        const ValueKey('recipe-full-compare-previous-2'),
      );
      await tester.ensureVisible(fullPrevious);
      expect(
        find.descendant(
          of: fullPrevious,
          matching: find.textContaining(' · 对比上一版本'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: fullPrevious, matching: find.text('完整对比上一版本')),
        findsNothing,
      );
      await tester.tap(fullPrevious);
      await waitFor(
        tester,
        find.byKey(const ValueKey('full-comparison-content')),
      );
      expect(find.text('完整版本对比'), findsOneWidget);
      expect(find.text('已按 2 人份对比'), findsOneWidget);
      expect(find.textContaining('确定规则 · 规则版本'), findsOneWidget);
      await reveal(tester, find.byKey(const ValueKey('full-comparison-why')));
      await tester.tap(find.byKey(const ValueKey('full-comparison-why')));
      await settle(tester);
      expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
      expect(find.text('版本变化依据'), findsOneWidget);
      expect(find.textContaining('规则版本'), findsWidgets);
      expect(find.text('这次不用'), findsNothing);
      expect(find.text('以后别这样'), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
      await reveal(tester, find.byKey(const ValueKey('full-compare-show-all')));
      await tester.tap(find.byKey(const ValueKey('full-compare-show-all')));
      await settle(tester);
      await reveal(
        tester,
        find.byKey(const ValueKey('full-compare-expand-all')),
      );
      await tester.tap(find.byKey(const ValueKey('full-compare-expand-all')));
      await settle(tester);
      // The section heading can mount before its lazy step cards. Reveal the
      // asserted alignment on the changed doneness card, not the heading.
      await reveal(tester, find.text('字段变化 · 成熟判断 · 确定性对齐'));
      expect(find.textContaining('确定性对齐'), findsWidgets);
      await reveal(tester, find.text('成熟判断：中心无粉红、汁液清澈'));
      expect(find.textContaining('中心无粉红、汁液清澈'), findsWidgets);
      await tester.tap(find.byTooltip('返回').last);
      await waitFor(tester, find.byKey(const ValueKey('recipe-version-2')));
      _markE2eStep('full_comparison_completed');
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
      final delete = find.byKey(const ValueKey('delete-recipe-button'));
      await reveal(tester, delete);
      // ensureVisible jumps the scroll position; pump its new layout before tap.
      await settle(tester);
      expect(delete.hitTestable(), findsOneWidget);
      await tester.tap(delete);
      await settle(tester);
      await waitFor(tester, find.text('确认删除'));
      await tester.tap(find.text('确认删除'));
      await waitFor(tester, find.text('还没有菜谱'));
      _markE2eStep('after_delete');
    }),
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
