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
    expect(finder, findsWidgets);
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder, double delta) async {
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
  }

  Future<void> reopen(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('taste-profile-entry')));
    await waitFor(tester, find.byKey(const ValueKey('taste-profile-content')));
  }

  Future<void> runWithDiagnostics(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    try {
      await body();
    } catch (error, stack) {
      IntegrationTestWidgetsFlutterBinding.instance.reportData = {
        'e2e_error': error.toString(),
        'e2e_stack': stack.toString(),
        'page_text': tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .toList(),
      };
      rethrow;
    }
  }

  testWidgets(
    '七项口味手动保存、重开、只读原因历史和诚实恢复默认',
    (tester) => runWithDiagnostics(tester, () async {
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
      await app.main();
      await waitFor(tester, find.byKey(const ValueKey('consent-agree')));
      await tester.tap(find.byKey(const ValueKey('consent-agree')));
      await waitFor(tester, find.byKey(const ValueKey('login-email')));
      final email =
          'taste-e2e-${DateTime.now().microsecondsSinceEpoch}@example.com';
      await tester.enterText(find.byKey(const ValueKey('login-email')), email);
      await tester.tap(find.text('发送验证码'));
      await waitFor(tester, find.byKey(const ValueKey('code-input')));
      final code = await server.get(
        '/v1/dev/latest-email-code',
        queryParameters: {'email': email},
      );
      await tester.enterText(
        find.byKey(const ValueKey('code-input')),
        code.data['code'] as String,
      );
      await waitFor(tester, find.text('先添加一道你常做的菜'));
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('taste-profile-entry')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('taste-profile-content')),
      );
      expect(find.text('咸 · 标准'), findsOneWidget);
      expect(find.text('把握低：暂用标准，还不了解你的口味'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('taste-level-salty')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('淡一点').last);
      await waitFor(tester, find.text('咸 · 淡一点'));
      expect(find.text('把握高：你手动设置'), findsOneWidget);
      await reopen(tester);
      expect(find.text('咸 · 淡一点'), findsOneWidget);
      final historyWhy = find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('taste-history-why-');
      });
      await waitFor(tester, historyWhy);
      await reveal(tester, historyWhy, 350);
      expect(historyWhy, findsOneWidget);
      expect(find.text('咸：标准 → 淡一点'), findsOneWidget);
      expect(find.text('你手动修改 · 生效'), findsOneWidget);
      await tester.tap(historyWhy);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
      expect(find.text('这次不用'), findsNothing);
      expect(find.text('以后别这样'), findsNothing);
      expect(find.text('0.75'), findsNothing);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      final reset = find.byKey(const ValueKey('taste-reset'));
      await reveal(tester, reset, -350);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('taste-reset-confirm')));
      await tester.pumpAndSettle();
      await reopen(tester);
      expect(find.text('咸 · 标准'), findsOneWidget);
      expect(find.text('把握高：你手动设置'), findsNothing);
      expect(find.text('把握低：暂用标准，还不了解你的口味'), findsWidgets);
      await reveal(tester, find.text('还没有菜系局部偏好'), 350);
      expect(find.text('还没有菜系局部偏好'), findsOneWidget);
      await reveal(tester, find.text('咸：淡一点 → 标准'), 350);
      expect(find.text('咸：淡一点 → 标准'), findsOneWidget);
      expect(find.text('咸：标准 → 淡一点'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }),
  );
}
