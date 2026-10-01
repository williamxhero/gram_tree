import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:integration_test/integration_test.dart';

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

  Future<void> settle(WidgetTester tester) =>
      tester.pumpAndSettle(const Duration(milliseconds: 200));

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await settle(tester);
    expect(finder, findsWidgets);
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    tester.testTextInput.hide();
    await tester.pump();
    final list = find.byType(ListView).last;
    // Sliver children outside the viewport may not exist yet. Start from the
    // top so revealing an earlier control never scrolls in the wrong direction.
    for (var i = 0; i < 12; i++) {
      await tester.drag(list, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.pump();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await settle(tester);
    await tester.tap(finder);
    await settle(tester);
  }

  testWidgets('登录后可以新建、保存、查看历史并删除菜谱', (tester) async {
    final email =
        'recipe-authoring-${DateTime.now().microsecondsSinceEpoch}@example.com';
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);

    await app.main();
    await settle(tester);
    if (find.text('开始之前，先说清楚我们会用到什么').evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('consent-agree')));
      await settle(tester);
    }
    if (find.text('登录味谱').evaluate().isNotEmpty) {
      await tester.enterText(find.byKey(const ValueKey('login-email')), email);
      await tapText(tester, '发送验证码');
      await waitFor(tester, find.text('输入验证码'));
      await tester.enterText(
        find.byKey(const ValueKey('code-input')),
        await latestCode(email),
      );
    }
    await waitFor(tester, find.text('今天还没有安排'));

    await waitFor(tester, find.byKey(const ValueKey('primary-create-button')));
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
    await tester.enterText(ingredient, '默认食材');
    final step = find.byKey(const ValueKey('recipe-step-instruction'));
    await reveal(tester, step);
    await tester.enterText(step, '完成默认步骤');
    await settle(tester);
    await reveal(tester, find.byKey(const ValueKey('save-recipe-button')));
    await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
    await waitFor(tester, find.byKey(const ValueKey('recipe-history-button')));
    expect(find.text('网页版验收菜谱'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('recipe-history-button')));
    await waitFor(tester, find.byKey(const ValueKey('recipe-version-1')));
    expect(find.textContaining('第 1 版'), findsOneWidget);

    // The detail route is intentionally outside the bottom-nav shell. Use the
    // router's public route boundary to return to the author's recipe list.
    final historyContext = tester.element(find.textContaining('第 1 版'));
    final path = GoRouter.of(historyContext)
        .routeInformationProvider
        .value
        .uri
        .path;
    final recipeId = path.split('/')[2];
    GoRouter.of(historyContext).go('/recipes');
    await waitFor(tester, find.text('网页版验收菜谱'));
    final listContext = tester.element(find.text('网页版验收菜谱').last);
    GoRouter.of(listContext).go('/recipes/$recipeId');
    await waitFor(tester, find.byKey(const ValueKey('delete-recipe-button')));
    await reveal(tester, find.byKey(const ValueKey('delete-recipe-button')));
    await tester.tap(find.byKey(const ValueKey('delete-recipe-button')));
    await settle(tester);
    await waitFor(tester, find.text('确认删除'));
    await tester.tap(find.text('确认删除'));
    await waitFor(tester, find.text('还没有菜谱'));
  });
}
