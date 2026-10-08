import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'event_pipeline_support.dart' show resetLocalAppState;

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
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    final email =
        'quantification-e2e-${DateTime.now().microsecondsSinceEpoch}@example.com';
    var step = 'login';
    try {
      // iOS Keychain sessions survive app uninstall between test targets.
      await resetLocalAppState();
      await app.main();
      await waitFor(tester, find.byKey(const ValueKey('consent-agree')));
      // iOS safe-area insets can place this action below the small viewport.
      await reveal(tester, 'consent-agree');
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
        '量化验收盐用量',
      );
      for (final (key, value) in [
        ('recipe-ingredient-search', '盐'),
        ('recipe-ingredient-quantity', '0'),
        ('recipe-ingredient-unit', '少许'),
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
      // Wait on the request control, which stays mounted while loading. A
      // successful proposal can be below the lazy viewport on a small phone;
      // waiting for its offscreen button alone can never discover that row.
      await waitFor(
        tester,
        find.byWidgetPredicate(
          (widget) =>
              widget is OutlinedButton &&
              widget.key == const ValueKey('recipe-quantify') &&
              widget.onPressed != null,
        ),
      );
      expect(find.byKey(const ValueKey('recipe-save-error')), findsNothing);
      step = 'reveal_quantification';
      await reveal(tester, 'quantification-accept-all');
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
      expect(find.textContaining('0 少许'), findsOneWidget);
      expect(find.textContaining('按两人份主料量估算盐用量'), findsWidgets);
      expect(find.textContaining('把握程度：中'), findsWidgets);
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
      step = 'accepted_quantity_original';
      expect(find.textContaining('0 少许'), findsOneWidget);
      expect(find.textContaining('按两人份主料量估算盐用量'), findsOneWidget);
      expect(find.textContaining('两人份盐 3 克'), findsOneWidget);
      expect(find.textContaining('把握程度：中'), findsOneWidget);
      expect(find.textContaining('偏淡时每次补 1 克'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tap(tester, 'recipe-history-button');
      await waitFor(tester, find.byKey(const ValueKey('recipe-version-1')));
      await tester.tap(find.byKey(const ValueKey('recipe-version-1')));
      await tester.pumpAndSettle();
      expect(find.text('还有 1 处需要确定'), findsOneWidget);
      await reveal(tester, 'recipe-ingredient-amount-ingredient-1');
      expect(find.textContaining('少许'), findsWidgets);
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
