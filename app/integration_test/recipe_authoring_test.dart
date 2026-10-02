import 'dart:developer' as developer;

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
    final detailList = find.byKey(const ValueKey('recipe-detail-content'));
    final list = detailList.evaluate().isNotEmpty
        ? detailList
        : find.byType(ListView).last;
    // Sliver children outside the viewport may not exist yet. Start from the
    // top so revealing an earlier control never scrolls in the wrong direction.
    for (var i = 0; i < 12; i++) {
      await tester.drag(list, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (detailList.evaluate().isNotEmpty) {
      final detailScrollable = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        finder,
        500,
        scrollable: detailScrollable,
        maxScrolls: 40,
      );
    } else {
      for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
        await tester.drag(list, const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 100));
      }
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
      await tester.enterText(ingredient, '默认食材');
      final step = find.byKey(const ValueKey('recipe-step-instruction'));
      await reveal(tester, step);
      await tester.enterText(step, '完成默认步骤');
      await settle(tester);
      await reveal(tester, find.byKey(const ValueKey('save-recipe-button')));
      await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-history-button')),
      );
      expect(find.text('网页版验收菜谱'), findsWidgets);

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
      await reveal(tester, find.bySemanticsLabel('这次改了什么'));
      await tester.enterText(find.bySemanticsLabel('这次改了什么'), '从第一版继续修改');
      await reveal(tester, find.byKey(const ValueKey('save-recipe-button')));
      await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-history-button')),
      );
      await tester.tap(find.byKey(const ValueKey('recipe-history-button')));
      await waitFor(tester, find.byKey(const ValueKey('recipe-version-2')));
      expect(find.byKey(const ValueKey('recipe-version-1')), findsOneWidget);
      expect(find.textContaining('从第一版继续修改'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await waitFor(tester, find.byKey(const ValueKey('recipe-list-button')));
      await tester.tap(find.byKey(const ValueKey('recipe-list-button')));
      await waitFor(tester, find.text('网页版验收菜谱'));
      final recipeCard = find.ancestor(
        of: find.text('网页版验收菜谱'),
        matching: find.byType(ListTile),
      );
      expect(recipeCard, findsOneWidget);
      await tester.tap(recipeCard);
      // The public, always-built content boundary signals that the HTTP detail
      // has loaded. On a small phone the delete control is a lazy sliver child;
      // scrolling is a user operation, not something waitFor can substitute for.
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-detail-content')),
      );
      await reveal(tester, find.byKey(const ValueKey('delete-recipe-button')));
      await tester.tap(find.byKey(const ValueKey('delete-recipe-button')));
      await settle(tester);
      await waitFor(tester, find.text('确认删除'));
      await tester.tap(find.text('确认删除'));
      await waitFor(tester, find.text('还没有菜谱'));
    }),
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
