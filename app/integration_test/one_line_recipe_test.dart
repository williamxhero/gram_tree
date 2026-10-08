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

  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    tester.testTextInput.hide();
    await tester.pump();
    if (finder.evaluate().isEmpty) {
      await tester.drag(
        find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
        const Offset(0, 10000),
      );
      await tester.pumpAndSettle();
    }
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    expect(finder.hitTestable(), findsOneWidget);
    await tester.tap(finder);
    await tester.pumpAndSettle();
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
        'page_text': tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .toList(),
      };
      rethrow;
    }
  }

  testWidgets(
    '一句话先检索，再生成、编辑保存私有第一版',
    (tester) => runWithDiagnostics(tester, () async {
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
      await app.main();
      await waitFor(tester, find.byKey(const ValueKey('consent-agree')));
      await tester.tap(find.byKey(const ValueKey('consent-agree')));
      await waitFor(tester, find.byKey(const ValueKey('login-email')));
      final email =
          'ai-e2e-${DateTime.now().microsecondsSinceEpoch}@example.com';
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
      await tester.tap(find.byKey(const ValueKey('primary-create-button')));
      await tester.pumpAndSettle();
      await tap(tester, 'one-line-recipe-entry');
      await tester.enterText(
        find.byKey(const ValueKey('one-line-input')),
        '想做一道小朋友能吃的、不辣的宫保鸡丁',
      );
      await tap(tester, 'one-line-search');
      await waitFor(tester, find.byKey(const ValueKey('ai-design-new')));
      expect(find.text('没有找到相似的私有菜谱。'), findsOneWidget);
      await tap(tester, 'ai-design-new');
      await tap(tester, 'ai-skip-questions');
      await waitFor(tester, find.textContaining('AI 辅助 · 尚未做过验证'));
      await tap(tester, 'ai-edit-draft');
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-editor-content')),
      );
      expect(find.text('AI 辅助 · 尚未做过验证'), findsOneWidget);
      final quantity = find.byKey(
        const ValueKey('recipe-ingredient-quantity-chicken'),
      );
      await tester.scrollUntilVisible(
        quantity,
        300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await tester.enterText(quantity, '320');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('save-recipe-button')),
        -300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await tap(tester, 'save-recipe-button');
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-detail-content')),
      );
      expect(find.text('宫保鸡丁'), findsWidgets);
      expect(find.text('AI 辅助 · 尚未做过验证'), findsOneWidget);
      // #135: no cooking records, same confirmed immutable version, no chat.
      for (final (question, label) in [
        ('鸡肉为什么要炒熟？', '已回答 · 一般经验'),
        ('这版用我没说明的锅会怎样？', '不确定 · 一般经验'),
        ('预测明天的股票价格', '无法回答 · 一般经验'),
        ('模拟解释超时，没有录好的回答', '能力不可用 · 一般经验'),
        ('鸡肉为什么要炒熟？', '已回答 · 一般经验'),
      ]) {
        await tap(tester, 'recipe-answer-input');
        await tester.enterText(
          find.byKey(const ValueKey('recipe-answer-input')),
          question,
        );
        await tap(tester, 'recipe-answer-submit');
        await waitFor(tester, find.byKey(const ValueKey('recipe-answer-why')));
        expect(find.text(label), findsOneWidget);
        expect(find.textContaining('这是一般经验，还没有足够记录验证'), findsWidgets);
        if (label.startsWith('能力不可用')) {
          expect(find.textContaining('查看、表单编辑和规则换算仍可使用'), findsOneWidget);
        }
        await tester.tap(find.byKey(const ValueKey('recipe-answer-close')));
        await tester.pumpAndSettle();
        expect(find.text(question), findsOneWidget);
      }
      await tap(tester, 'recipe-serving-increase');
      expect(find.text('3'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('edit-recipe-button')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-editor-content')),
      );
      final confirmedQuantity = find.byKey(
        const ValueKey('recipe-ingredient-quantity-chicken'),
      );
      await tester.scrollUntilVisible(
        confirmedQuantity,
        300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      expect(
        find.descendant(of: confirmedQuantity, matching: find.text('320')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }),
  );
}
