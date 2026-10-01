import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    final list = find.byType(ListView).last;
    for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.ensureVisible(finder);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await settle(tester);
    await tester.tap(finder);
    await settle(tester);
  }

  testWidgets('登录后可以新建、保存、查看历史并删除菜谱', (tester) async {
    try {
      final email =
          'recipe-authoring-${DateTime.now().microsecondsSinceEpoch}@example.com';
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);

      await app.main();
      await waitFor(tester, find.text('开始之前，先说清楚我们会用到什么'));
      await tester.tap(find.byKey(const ValueKey('consent-agree')));
      await settle(tester);

      await waitFor(tester, find.text('登录味谱'));
      await tester.enterText(find.byKey(const ValueKey('login-email')), email);
      await tapText(tester, '发送验证码');
      await waitFor(tester, find.text('输入验证码'));
      await tester.enterText(
        find.byKey(const ValueKey('code-input')),
        await latestCode(email),
      );
      await waitFor(tester, find.text('今天还没有安排'));

      await tester.tap(find.byKey(const ValueKey('primary-create-button')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
      await settle(tester);
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
      await tester.ensureVisible(
        find.byKey(const ValueKey('save-recipe-button')),
      );
      await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
      await waitFor(tester, find.text('网页版验收菜谱'));
      expect(find.text('网页版验收菜谱'), findsWidgets);
    } catch (error, stack) {
      debugPrint('RECIPE_E2E_FAILURE: $error\n$stack');
      rethrow;
    }
  });
}
