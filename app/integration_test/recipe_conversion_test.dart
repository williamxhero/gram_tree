import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:gram_tree/recipes/measure_display.dart';
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

  Future<Offset> reveal(
    WidgetTester tester,
    Finder finder, {
    bool tapAfterReveal = false,
  }) async {
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
    if (tapAfterReveal) {
      await tester.tap(finder);
    }
    return tester.getCenter(finder);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await waitFor(tester, finder);
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
      Future<String> directToken(String accountEmail) async {
        await server.post(
          '/v1/auth/email/code',
          data: {'email': accountEmail, 'purpose': 'login'},
        );
        final response = await server.post<Map<String, dynamic>>(
          '/v1/auth/email/login',
          data: {'email': accountEmail, 'code': await latestCode(accountEmail)},
        );
        return response.data!['access_token'] as String;
      }

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
        find.byKey(const ValueKey('recipe-ingredient-search')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('recipe-ingredient-search')),
        '面粉',
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
      // The history action is a stable readiness boundary after saving.
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-history-button')),
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
        find.byKey(const ValueKey('recipe-history-button')),
      );
      _markE2eStep('after_base_mold_saved');

      // Serving conversion: use the keyed controls instead of matching nearby
      // text, and verify both adjustment and restoration on the real detail page.
      await reveal(tester, find.byKey(const ValueKey('recipe-serving-value')));
      final originalServing = tester
          .widget<Text>(find.byKey(const ValueKey('recipe-serving-value')))
          .data;
      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-serving-increase')),
        tapAfterReveal: true,
      );
      await settle(tester);
      final increasedServing = tester
          .widget<Text>(find.byKey(const ValueKey('recipe-serving-value')))
          .data;
      expect(increasedServing, isNot(originalServing));
      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-serving-reset')),
        tapAfterReveal: true,
      );
      await settle(tester);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('recipe-serving-value')))
            .data,
        originalServing,
      );
      _markE2eStep('after_serving_increase_reset');

      // Mold conversion: the recipe was saved with a six-inch base mold above;
      // changing the target to eight inches should expose the area-scaled value.
      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-mode-mold')),
        tapAfterReveal: true,
      );
      await settle(tester);
      await reveal(tester, find.byKey(const ValueKey('target-mold-diameter')));
      await tester.enterText(
        find.byKey(const ValueKey('target-mold-diameter')),
        '8',
      );
      await settle(tester);
      await reveal(tester, find.text('177.78 克'));
      expect(find.text('177.78 克'), findsWidgets);
      await tapText(tester, '按场景调整');
      await waitFor(tester, find.byKey(const ValueKey('why-panel')));
      expect(find.text('原来：100 g'), findsOneWidget);
      expect(find.text('现在：177.78 克'), findsOneWidget);
      expect(find.textContaining('模具比例'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
      _markE2eStep('after_mold_eight_inch');

      // Display mode switching is also an HTTP-backed contract. The local
      // fallback keeps the page usable, while the real server response is
      // asserted below with a separately authenticated contract account.
      await reveal(tester, find.byKey(const ValueKey('recipe-measure-mode')));
      final displaySelector = find.byKey(
        const ValueKey('recipe-display-mode-selector'),
      );
      await tapText(tester, '汤匙/茶匙');
      await waitFor(tester, displaySelector);
      expect(
        tester
            .widget<SegmentedButton<MeasureDisplayMode>>(displaySelector)
            .selected,
        {MeasureDisplayMode.standard},
      );
      await tapText(tester, '克/毫升');
      await waitFor(tester, displaySelector);
      expect(
        tester
            .widget<SegmentedButton<MeasureDisplayMode>>(displaySelector)
            .selected,
        {MeasureDisplayMode.base},
      );
      _markE2eStep('after_display_mode_switching');

      final contractEmail =
          'recipe-contract-${DateTime.now().microsecondsSinceEpoch}@example.com';
      final token = await directToken(contractEmail);
      final auth = Options(headers: {'Authorization': 'Bearer $token'});
      final created = await server.post<Map<String, dynamic>>(
        '/v1/recipes',
        data: {
          'dish_name': 'HTTP换算合同菜谱',
          'dish_aliases': <String>[],
          'snapshot': {
            'format_version': 1,
            'servings': 2,
            'base_mold': {'shape': 'round', 'unit': 'in', 'diameter': 6},
            'ingredients': [
              {
                'id': 'flour',
                'display_name': '面粉',
                'quantity': 100,
                'unit': 'g',
                'scaling_mode': 'proportional',
              },
            ],
            'steps': <Map<String, dynamic>>[],
          },
          'change_note': '',
          'ai_assisted': false,
        },
        options: auth,
      );
      expect(created.statusCode, 201);
      final recipeId = created.data!['id'] as String;
      final display = await server.get<Map<String, dynamic>>(
        '/v1/recipes/$recipeId/display',
        queryParameters: {'mode': 'base'},
        options: auth,
      );
      expect(display.data!['display']['recipe_id'], recipeId);
      expect(display.data!['display']['mode'], 'base');
      final mold = await server.post<Map<String, dynamic>>(
        '/v1/recipes/$recipeId/mold',
        data: {
          'target_mold': {'shape': 'round', 'unit': 'in', 'diameter': 8},
        },
        options: auth,
      );
      expect(mold.data!['conversion']['area_ratio'], 1.78);
      _markE2eStep('after_http_contract');
    }),
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
