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

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(finder, findsWidgets);
  }

  Future<void> reveal(WidgetTester tester, String key) async {
    tester.testTextInput.hide();
    await tester.pump();
    final finder = find.byKey(ValueKey(key));
    final scrollable = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    // Reset upward before looking for lazy rows, including controls above the
    // current position after the proposal panel changes the page height.
    for (var i = 0; i < 12; i++) {
      await tester.drag(scrollable, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: scrollable,
      maxScrolls: 60,
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    expect(finder.hitTestable(), findsOneWidget);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await reveal(tester, key);
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  testWidgets('量化确认创建新版本并在统一为什么面板保留依据', (tester) async {
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    final email =
        'quantification-e2e-${DateTime.now().microsecondsSinceEpoch}@example.com';
    var step = 'login';
    try {
      await app.main();
      await waitFor(tester, find.byKey(const ValueKey('consent-agree')));
      await tester.tap(find.byKey(const ValueKey('consent-agree')));
      await waitFor(tester, find.byKey(const ValueKey('login-email')));
      await tester.enterText(find.byKey(const ValueKey('login-email')), email);
      await tester.tap(find.text('发送验证码'));
      await waitFor(tester, find.byKey(const ValueKey('code-input')));
      final code = (await server.get(
        '/v1/dev/latest-email-code',
        queryParameters: {'email': email},
      )).data['code'];
      await tester.enterText(
        find.byKey(const ValueKey('code-input')),
        code as String,
      );
      await waitFor(
        tester,
        find.byKey(const ValueKey('primary-create-button')),
      );
      await tester.tap(find.byKey(const ValueKey('primary-create-button')));
      await tester.pumpAndSettle();
      await tap(tester, 'create-recipe-entry');
      await waitFor(tester, find.byKey(const ValueKey('recipe-dish-name')));
      await tester.enterText(
        find.byKey(const ValueKey('recipe-dish-name')),
        '量化验收凉拌水',
      );
      for (final (key, value) in [
        ('recipe-ingredient-search', '水'),
        ('recipe-ingredient-quantity', '1'),
        ('recipe-ingredient-unit', '碗'),
        ('recipe-step-instruction', '搅拌均匀'),
      ]) {
        await reveal(tester, key);
        await tester.enterText(find.byKey(ValueKey(key)), value);
        await tester.pumpAndSettle();
      }
      await tap(tester, 'save-recipe-button');
      await waitFor(tester, find.byKey(const ValueKey('edit-recipe-button')));
      expect(find.text('还有 1 处需要确定'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('edit-recipe-button')));
      await waitFor(tester, find.byKey(const ValueKey('recipe-quantify')));
      step = 'request_quantification';
      await tap(tester, 'recipe-quantify');
      await waitFor(
        tester,
        find.byKey(const ValueKey('quantification-accept-all')),
      );
      await reveal(
        tester,
        'quantification-why-ingredients:ingredient-1:quantity:ambiguous:field',
      );
      await tester.tap(
        find.byKey(
          const ValueKey(
            'quantification-why-ingredients:ingredient-1:quantity:ambiguous:field',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('1 碗'), findsOneWidget);
      expect(find.textContaining('以常见中号碗容量为基准'), findsWidgets);
      expect(find.textContaining('把握程度：低'), findsWidgets);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tap(tester, 'quantification-accept-all');
      await waitFor(tester, find.text('所有执行字段已具体化 · 可复刻'));
      await tap(tester, 'save-recipe-button');
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-detail-content')),
      );
      await tap(tester, 'recipe-source-mark-ingredient-1');
      expect(find.textContaining('中号碗约 300 毫升'), findsOneWidget);
      expect(find.textContaining('把握程度：低'), findsOneWidget);
      expect(find.textContaining('按实际碗容量用量杯测量'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tap(tester, 'recipe-history-button');
      await waitFor(tester, find.byKey(const ValueKey('recipe-version-1')));
      await tester.tap(find.byKey(const ValueKey('recipe-version-1')));
      await tester.pumpAndSettle();
      expect(find.text('还有 1 处需要确定'), findsOneWidget);
      await reveal(tester, 'recipe-ingredient-amount-ingredient-1');
      expect(find.textContaining('碗'), findsWidgets);
      IntegrationTestWidgetsFlutterBinding.instance.reportData = {
        'e2e_step': 'after_quantification_evidence',
      };
      expect(tester.takeException(), isNull);
    } catch (error) {
      IntegrationTestWidgetsFlutterBinding.instance.reportData = {
        'e2e_step': step,
        'error': error.toString(),
        'page_text': find
            .byType(Text)
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .whereType<String>()
            .join('\n'),
      };
      rethrow;
    }
  });
}
