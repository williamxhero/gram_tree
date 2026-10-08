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

  var lastTarget = 'startup';

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    lastTarget = 'wait for $finder';
    for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsWidgets);
    await tester.pumpAndSettle();
  }

  Future<void> reveal(
    WidgetTester tester,
    Finder finder, {
    double delta = 350,
  }) async {
    lastTarget = 'reveal $finder (delta: $delta)';
    tester.testTextInput.hide();
    await tester.pump();
    final dialog = find.byType(AlertDialog);
    final scrollable = dialog.evaluate().isEmpty
        ? find
              .byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              )
              .first
        : find.descendant(of: dialog, matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(finder, delta, scrollable: scrollable);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tap(
    WidgetTester tester,
    String key, {
    bool scroll = false,
    double delta = 350,
  }) async {
    final finder = find.byKey(ValueKey(key));
    if (scroll) await reveal(tester, finder, delta: delta);
    await waitFor(tester, finder);
    lastTarget = 'tap $key';
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
  }

  testWidgets('做菜约束保存清除、重开、家庭默认份数与量具管理闭环', (tester) async {
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    var phase = 'login';
    try {
      await app.main();
      await waitFor(tester, find.byKey(const ValueKey('consent-agree')));
      await tap(tester, 'consent-agree');
      await waitFor(tester, find.byKey(const ValueKey('login-email')));
      final email =
          'constraints-e2e-${DateTime.now().microsecondsSinceEpoch}@example.com';
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
      phase = 'save and reopen cooking constraints';
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      await tap(tester, 'taste-profile-entry');
      await waitFor(
        tester,
        find.byKey(const ValueKey('taste-profile-content')),
      );
      await tap(tester, 'cooking-constraints-edit', scroll: true);
      await tester.enterText(
        find.byKey(const ValueKey('household-servings')),
        '4',
      );
      await tap(tester, 'equipment-wok', scroll: true);
      final minutes = find.byKey(const ValueKey('meal-minutes-weekday-dinner'));
      await reveal(tester, minutes);
      await tester.enterText(minutes, '30');
      final template = find.byKey(
        const ValueKey('meal-template-weekday-dinner'),
      );
      await reveal(tester, template);
      await tester.enterText(template, '荤菜,素菜,汤');
      await tap(tester, 'cooking-constraints-save');
      await waitFor(
        tester,
        find.byKey(const ValueKey('taste-profile-content')),
      );
      await reveal(tester, find.byKey(const ValueKey('cooking-constraints')));
      await waitFor(tester, find.text('家庭默认：4 人'));
      await back(tester);
      await tap(tester, 'taste-profile-entry');
      await waitFor(
        tester,
        find.byKey(const ValueKey('taste-profile-content')),
      );
      await reveal(tester, find.byKey(const ValueKey('cooking-constraints')));
      await waitFor(tester, find.text('家庭默认：4 人'));
      expect(find.text('工作日晚餐：30 分钟'), findsOneWidget);
      expect(find.text('工作日晚餐：3 道（荤菜、素菜、汤）'), findsOneWidget);

      phase = 'register and recalibrate personal measure';
      await tap(tester, 'taste-measures-manage', scroll: true);
      await tap(tester, 'measure-add');
      await tester.enterText(find.byKey(const ValueKey('measure-name')), '家用勺');
      await tester.enterText(
        find.byKey(const ValueKey('measure-capacity')),
        '12',
      );
      await tap(tester, 'measure-save');
      await waitFor(tester, find.text('家用勺'));
      await back(tester);
      await waitFor(
        tester,
        find.byKey(const ValueKey('taste-profile-content')),
      );
      await reveal(tester, find.text('家用勺 · 12.0 毫升'));
      await tap(tester, 'taste-measures-manage', scroll: true);
      await tester.tap(find.text('家用勺'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('measure-capacity')),
        '15',
      );
      await tap(tester, 'measure-save');
      await back(tester);
      await waitFor(
        tester,
        find.byKey(const ValueKey('taste-profile-content')),
      );
      await reveal(tester, find.text('家用勺 · 15.0 毫升'));
      phase = 'clear, reopen, and restore household default';
      await tap(tester, 'cooking-constraints-clear', scroll: true, delta: -350);
      await tap(tester, 'cooking-constraints-clear-confirm');
      await waitFor(
        tester,
        find.byKey(const ValueKey('taste-profile-content')),
      );
      await reveal(tester, find.byKey(const ValueKey('cooking-constraints')));
      await waitFor(tester, find.text('人数未设置，菜谱沿用作者份数'));
      await back(tester);
      await tap(tester, 'taste-profile-entry');
      await waitFor(
        tester,
        find.byKey(const ValueKey('taste-profile-content')),
      );
      await reveal(tester, find.byKey(const ValueKey('cooking-constraints')));
      await waitFor(tester, find.text('人数未设置，菜谱沿用作者份数'));
      expect(find.text('厨具未设置'), findsOneWidget);
      await tap(tester, 'cooking-constraints-edit', scroll: true);
      await tester.enterText(
        find.byKey(const ValueKey('household-servings')),
        '4',
      );
      await tap(tester, 'cooking-constraints-save');
      await waitFor(
        tester,
        find.byKey(const ValueKey('taste-profile-content')),
      );
      await reveal(tester, find.byKey(const ValueKey('cooking-constraints')));
      await waitFor(tester, find.text('家庭默认：4 人'));
      await back(tester);

      phase = 'fill recipe author fields';
      await tap(tester, 'my-recipes-list-entry');
      await tap(tester, 'new-recipe-button');
      await waitFor(tester, find.byKey(const ValueKey('recipe-dish-name')));
      await tester.enterText(
        find.byKey(const ValueKey('recipe-dish-name')),
        '家庭份数验收菜谱',
      );
      final ingredient = find.byKey(const ValueKey('recipe-ingredient-search'));
      await reveal(tester, ingredient);
      await tester.enterText(ingredient, '面粉');
      final quantity = find.byKey(const ValueKey('recipe-ingredient-quantity'));
      await reveal(tester, quantity);
      await tester.enterText(quantity, '100');
      final instruction = find.byKey(const ValueKey('recipe-step-instruction'));
      await reveal(tester, instruction);
      await tester.enterText(instruction, '烤至成熟');
      phase = 'save recipe';
      // Save is above the lazy ingredient and step rows, not below them.
      await tap(tester, 'save-recipe-button', scroll: true, delta: -350);
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-history-button')),
      );
      phase = 'household default and manual serving precedence';
      await reveal(tester, find.byKey(const ValueKey('recipe-serving-value')));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('recipe-serving-value')))
            .data,
        '4',
      );
      await tap(tester, 'recipe-serving-increase');
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('recipe-serving-value')))
            .data,
        '5',
      );
      await tap(tester, 'recipe-measure-refresh', scroll: true);
      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-serving-value')),
        delta: -350,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('recipe-serving-value')))
            .data,
        '5',
      );
      await tap(tester, 'recipe-serving-reset');
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('recipe-serving-value')))
            .data,
        '2',
      );
      phase = 'verify unchanged author quantity';
      await tap(tester, 'edit-recipe-button', scroll: true, delta: -350);
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-editor-content')),
      );
      // Saved reproducibility checks put this lazy row below a phone viewport.
      await reveal(tester, find.byKey(const ValueKey('recipe-dish-name')));
      await waitFor(tester, find.byKey(const ValueKey('recipe-dish-name')));
      await reveal(
        tester,
        find.byKey(const ValueKey('recipe-ingredient-quantity')),
      );
      final authorQuantity = tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('recipe-ingredient-quantity')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text;
      expect(num.tryParse(authorQuantity), 100);
      expect(tester.takeException(), isNull);
    } catch (error, stack) {
      IntegrationTestWidgetsFlutterBinding.instance.reportData = {
        'e2e_phase': phase,
        'e2e_target': lastTarget,
        'e2e_error': error.toString(),
        'e2e_stack': stack.toString(),
        'page_text': tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .toList(),
      };
      rethrow;
    }
  });
}
