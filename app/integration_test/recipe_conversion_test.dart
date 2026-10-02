import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
      debugPrint('E2E waitFor timeout: $finder');
      debugDumpApp();
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

  testWidgets(
    '网页端覆盖份数恢复、模具互斥、显示切换和来源明细',
    (tester) => runWithDiagnostics(tester, () async {
      // This is a web acceptance flow. SPEC-002.3 has no phone-only capability,
      // so Android CI reuses its dedicated mobile-capability tests instead.
      if (!kIsWeb) return;

      final email =
          'recipe-conversion-${DateTime.now().microsecondsSinceEpoch}@example.com';
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);

      await app.main();
      await settle(tester);
      final consent = find.text('开始之前，先说清楚我们会用到什么');
      if (consent.evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const ValueKey('consent-agree')));
        await settle(tester);
      }
      await waitFor(tester, find.text('登录味谱'));
      await tester.enterText(find.byKey(const ValueKey('login-email')), email);
      await tapText(tester, '发送验证码');
      await waitFor(tester, find.text('输入验证码'));
      await tester.enterText(
        find.byKey(const ValueKey('code-input')),
        await latestCode(email),
      );
      await waitFor(tester, find.text('先添加一道你常做的菜'));

      await tester.tap(find.byKey(const ValueKey('primary-create-button')));
      await settle(tester);
      await waitFor(tester, find.byKey(const ValueKey('create-recipe-entry')));
      await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
      await waitFor(tester, find.byKey(const ValueKey('recipe-dish-name')));
      await tester.enterText(
        find.byKey(const ValueKey('recipe-dish-name')),
        '网页版换算验收菜谱',
      );

      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-ingredient-quantity')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('recipe-ingredient-quantity')),
        '100',
      );
      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-step-instruction')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('recipe-step-instruction')),
        '烤至成熟',
      );
      await reveal(tester, find.byKey(const ValueKey('save-recipe-button')));
      await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
      // The serving control is the first stable, user-visible detail-page
      // boundary needed by this conversion acceptance flow.
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-serving-control')),
      );
      _markE2eStep('after_detail_loaded');
      await tester.tap(find.byKey(const ValueKey('edit-recipe-button')));
      await waitFor(tester, find.byKey(const ValueKey('recipe-dish-name')));
      await reveal(tester, find.byKey(const ValueKey('base-mold-enable')));
      await tester.tap(find.byKey(const ValueKey('base-mold-enable')));
      await settle(tester);
      await reveal(tester, find.byKey(const ValueKey('base-mold-diameter')));
      await tester.enterText(
        find.byKey(const ValueKey('base-mold-diameter')),
        '6',
      );
      await reveal(tester, find.byKey(const ValueKey('save-recipe-button')));
      await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-serving-control')),
      );
      _markE2eStep('after_base_mold_saved');

      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-serving-increase')),
      );
      await tester.tap(find.byKey(const ValueKey('recipe-serving-increase')));
      await settle(tester);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('recipe-serving-value')))
            .data,
        '3',
      );
      await tester.tap(find.byKey(const ValueKey('recipe-serving-reset')));
      await settle(tester);
      expect(
        find.byKey(const ValueKey('recipe-serving-value')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('recipe-mode-mold')));
      await settle(tester);
      expect(
        find.byKey(const ValueKey('recipe-serving-control')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('recipe-measure-mode')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('target-mold-diameter')),
        '8',
      );
      await settle(tester);
      await waitFor(tester, find.byKey(const ValueKey('recipe-mold-ratio')));

      await tester.tap(find.text('汤匙/茶匙'));
      await settle(tester);
      expect(find.byKey(const ValueKey('recipe-measure-mode')), findsOneWidget);
      await tester.tap(find.text('克/毫升'));
      await settle(tester);
      expect(find.byKey(const ValueKey('recipe-measure-mode')), findsOneWidget);

      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-source-mark-ingredient-1')),
      );
      await tester.tap(
        find.byKey(const ValueKey('recipe-source-mark-ingredient-1')),
      );
      await settle(tester);
      expect(find.text('原来：100 g'), findsOneWidget);
      expect(find.text('模具比例'), findsWidgets);
      _markE2eStep('after_source_detail');
    }),
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
