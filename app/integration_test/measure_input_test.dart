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
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await settle(tester);
    expect(finder, findsWidgets);
  }

  Finder key(String name) => find.byKey(ValueKey(name));
  Future<void> tap(WidgetTester tester, String name) async {
    final finder = key(name);
    await waitFor(tester, finder);
    await tester.ensureVisible(finder);
    await settle(tester);
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    tester.testTextInput.hide();
    final detail = key('recipe-detail-content');
    final body = detail.evaluate().isNotEmpty
        ? detail
        : key('recipe-editor-content');
    for (var i = 0; i < 10; i++) {
      await tester.drag(body, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 35 && finder.evaluate().isEmpty; i++) {
      await tester.drag(body, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await waitFor(tester, finder);
    await tester.ensureVisible(finder);
    await settle(tester);
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byTooltip('返回').last);
    await settle(tester);
  }

  final inputButton = key('recipe-measure-input-ingredient-1');

  testWidgets('登记量具、缺密度兜底、确认录入和草稿恢复、重新校准删除后重开旧版', (tester) async {
    if (!kIsWeb) return;
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    await app.main();
    await settle(tester);
    if (key('consent-agree').evaluate().isNotEmpty) {
      await tap(tester, 'consent-agree');
    }
    final email =
        'measure-input-${DateTime.now().microsecondsSinceEpoch}@example.com';
    await waitFor(tester, key('login-email'));
    await tester.enterText(key('login-email'), email);
    await tester.tap(find.text('发送验证码'));
    await waitFor(tester, key('code-input'));
    final code = await server.get<Map<String, dynamic>>(
      '/v1/dev/latest-email-code',
      queryParameters: {'email': email},
    );
    await tester.enterText(key('code-input'), code.data!['code'] as String);
    await waitFor(tester, key('primary-create-button'));
    await tap(tester, 'primary-create-button');
    await tap(tester, 'create-recipe-entry');
    await waitFor(tester, key('recipe-dish-name'));
    await tester.enterText(key('recipe-dish-name'), '量具输入验收汤');
    await reveal(tester, key('recipe-ingredient-search'));
    await tester.enterText(key('recipe-ingredient-search'), '水');
    await reveal(tester, inputButton);
    await tester.tap(inputButton);
    await waitFor(tester, find.textContaining('还没有登记量具'));
    await tap(tester, 'measure-input-manage');
    await tap(tester, 'measure-add');
    await tester.enterText(key('measure-name'), '验收白瓷勺');
    await tester.enterText(key('measure-capacity'), '12');
    await tap(tester, 'measure-save');
    await waitFor(tester, find.text('验收白瓷勺'));
    await back(tester);
    await reveal(tester, inputButton);
    await tester.tap(inputButton);
    await waitFor(tester, key('measure-input-count'));
    await tester.enterText(key('measure-input-count'), '2');
    await tap(tester, 'measure-input-unit');
    await tester.tap(find.text('克').last);
    await settle(tester);
    await tap(tester, 'measure-input-preview');
    await waitFor(tester, find.textContaining('缺少密度数据，无法可靠换算成克'));
    await tap(tester, 'measure-input-unit');
    await tester.tap(find.text('毫升').last);
    await settle(tester);
    await tap(tester, 'measure-input-preview');
    await waitFor(tester, find.text('24 ml'));
    await tap(tester, 'measure-input-confirm');
    await waitFor(tester, find.text('2 验收白瓷勺'));
    await reveal(tester, key('recipe-step-instruction'));
    await tester.enterText(key('recipe-step-instruction'), '煮沸后盛入碗中');
    await settle(tester);
    // Leaving uses the existing account-scoped draft store, not a second input draft.
    await back(tester);
    await tap(tester, 'create-recipe-entry');
    await waitFor(tester, find.text('恢复未保存修改？'));
    await tester.tap(find.text('恢复').last);
    await settle(tester);
    await reveal(tester, find.text('2 验收白瓷勺'));
    await reveal(tester, key('save-recipe-button'));
    await tap(tester, 'save-recipe-button');
    await waitFor(tester, key('edit-recipe-button'));
    await tap(tester, 'edit-recipe-button');
    await reveal(tester, inputButton);
    await tester.tap(inputButton);
    await tap(tester, 'measure-input-manage');
    await waitFor(tester, find.text('验收白瓷勺'));
    await tester.tap(find.text('验收白瓷勺'));
    await waitFor(tester, key('measure-capacity'));
    await tester.enterText(key('measure-capacity'), '24');
    await tap(tester, 'measure-save');
    await waitFor(tester, find.textContaining('24'));
    await tester.tap(find.byTooltip('删除量具'));
    await waitFor(tester, find.text('删除量具？'));
    await tester.tap(find.text('确认删除').last);
    await settle(tester);
    await back(tester);
    await reveal(tester, find.text('2 验收白瓷勺'));
    await reveal(tester, key('save-recipe-button'));
    await tap(tester, 'save-recipe-button');
    await waitFor(tester, key('recipe-history-button'));
    await tap(tester, 'recipe-history-button');
    await tap(tester, 'recipe-version-1');
    await waitFor(tester, key('edit-old-recipe-button'));
    await tap(tester, 'edit-old-recipe-button');
    await reveal(tester, find.text('2 验收白瓷勺'));
    await tester.tap(find.text('量具输入依据'));
    await waitFor(tester, find.textContaining('每次容量 12 毫升'));
    expect(find.textContaining('输入 2 验收白瓷勺'), findsWidgets);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
