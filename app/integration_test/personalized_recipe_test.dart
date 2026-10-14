import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsWidgets);
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await waitFor(tester, finder);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    tester.testTextInput.hide();
    final detail = find.byKey(const ValueKey('recipe-detail-content'));
    final body = detail.evaluate().isNotEmpty
        ? detail
        : find.byKey(const ValueKey('recipe-editor-content'));
    if (finder.evaluate().isEmpty) {
      for (var i = 0; i < 12; i++) {
        await tester.drag(body, const Offset(0, 500));
        await tester.pump(const Duration(milliseconds: 100));
      }
      for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
        await tester.drag(body, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    expect(finder, findsWidgets);
    await tester.ensureVisible(finder.last);
    await settle(tester);
  }

  testWidgets('网页端真实少盐档案贯穿个性化、原版切换与做菜准备', (tester) async {
    if (!kIsWeb) return;
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);

    await app.main();
    await settle(tester);
    final consent = find.byKey(const ValueKey('consent-agree'));
    if (consent.evaluate().isNotEmpty) {
      await tester.tap(consent);
      await settle(tester);
    }
    await waitFor(tester, find.text('登录味谱'));
    final email =
        'personalized-e2e-${DateTime.now().microsecondsSinceEpoch}@example.com';
    await tester.enterText(find.byKey(const ValueKey('login-email')), email);
    await tapText(tester, '发送验证码');
    await waitFor(tester, find.byKey(const ValueKey('code-input')));
    final code = await server.get<Map<String, dynamic>>(
      '/v1/dev/latest-email-code',
      queryParameters: {'email': email},
    );
    await tester.enterText(
      find.byKey(const ValueKey('code-input')),
      code.data!['code'] as String,
    );
    // The composed home page may replace the fallback empty-state wording.
    await waitFor(tester, find.byKey(const ValueKey('primary-create-button')));

    await tapText(tester, '我的');
    await waitFor(tester, find.byKey(const ValueKey('taste-profile-entry')));
    await tester.tap(find.byKey(const ValueKey('taste-profile-entry')));
    await waitFor(tester, find.byKey(const ValueKey('taste-level-salty')));
    await tester.tap(find.byKey(const ValueKey('taste-level-salty')));
    await settle(tester);
    await tapText(tester, '淡一点');
    await waitFor(tester, find.textContaining('把握高'));
    await tester.tap(find.byType(BackButton).last);
    await settle(tester);
    await tapText(tester, '今天');
    await waitFor(tester, find.byKey(const ValueKey('primary-create-button')));
    await tester.tap(find.byKey(const ValueKey('primary-create-button')));
    await settle(tester);
    await waitFor(tester, find.byKey(const ValueKey('create-recipe-entry')));
    await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
    await waitFor(tester, find.byKey(const ValueKey('recipe-dish-name')));
    await tester.enterText(
      find.byKey(const ValueKey('recipe-dish-name')),
      '网页版个性化验收菜谱',
    );
    await reveal(
      tester,
      find.byKey(const ValueKey('recipe-ingredient-search')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('recipe-ingredient-search')),
      '盐',
    );
    await reveal(
      tester,
      find.byKey(const ValueKey('recipe-ingredient-quantity')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('recipe-ingredient-quantity')),
      '10',
    );
    await reveal(tester, find.text('这道菜的味型贡献'));
    await tester.tap(find.text('这道菜的味型贡献'));
    await settle(tester);
    final saltyContribution = find.ancestor(
      of: find.text('咸味贡献'),
      matching: find.byType(DropdownButtonFormField<int>),
    );
    await reveal(tester, saltyContribution);
    await tester.tap(saltyContribution);
    await settle(tester);
    await tapText(tester, '咸 3');
    await reveal(tester, find.byKey(const ValueKey('recipe-step-instruction')));
    await tester.enterText(
      find.byKey(const ValueKey('recipe-step-instruction')),
      '煮熟后加盐',
    );
    await reveal(tester, find.byKey(const ValueKey('save-recipe-button')));
    await tester.tap(find.byKey(const ValueKey('save-recipe-button')));
    await waitFor(tester, find.byKey(const ValueKey('recipe-history-button')));

    final personalized = find.text('按我的口味');
    await waitFor(tester, personalized);
    await reveal(tester, personalized);
    await waitFor(tester, find.textContaining('已按口味档案第'));
    expect(
      tester.getSemantics(personalized.last),
      isSemantics(isSelected: true),
    );
    await reveal(tester, find.text('盐  7.5 g'));
    await reveal(tester, personalized);
    final original = find.text('原版').last;
    await tester.tap(original);
    await settle(tester);
    expect(tester.getSemantics(original), isSemantics(isSelected: true));
    expect(find.text('原版'), findsWidgets);
    await reveal(tester, find.text('10 克'));
    await reveal(tester, find.textContaining('煮熟后加盐'));
    await reveal(tester, personalized);
    await tester.tap(personalized.last);
    await settle(tester);
    await reveal(tester, find.text('盐  7.5 g'));
    final start = find.byKey(const ValueKey('start-cooking-button'));
    await reveal(tester, start);
    expect(tester.widget<FilledButton>(start).onPressed, isNotNull);
    await tester.tap(start);
    await waitFor(tester, find.text('先准备食材'));
    expect(find.text('7.5 g'), findsOneWidget);
    expect(find.text('10 g'), findsNothing);
    await tapText(tester, '开始第一步');
    await waitFor(tester, find.text('煮熟后加盐'));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
