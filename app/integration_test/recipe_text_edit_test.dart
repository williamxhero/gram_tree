import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'event_pipeline_support.dart' show resetLocalAppState;

const _request = '想做一道小朋友能吃的、不辣的宫保鸡丁';
const _edit = '把步骤说明写清楚，不改食材和用量';
const _original = '中火炒鸡腿肉并加入盐，用食品温度计检查鸡肉中心温度达到 74°C';
const _clarified = '中火翻炒鸡肉，直到中心达到 74°C，盛出。';
const _manualWhy = '确认中心达到 74°C 后盛出，避免加热不足。';

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
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .first;
    // Reset the visible scroll position before seeking a lazy historical row.
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

  Future<void> settledChoice(WidgetTester tester, String key) async {
    await tap(tester, key);
    // Await the actual completed selection check, not the old visible values.
    await waitFor(
      tester,
      find.byWidgetPredicate(
        (widget) =>
            widget is OutlinedButton &&
            widget.key == ValueKey(key) &&
            widget.onPressed != null,
      ),
    );
    await reveal(tester, key);
  }

  Future<void> generate(WidgetTester tester, {int remaining = 50}) async {
    await waitFor(tester, find.byKey(const ValueKey('primary-create-button')));
    await tester.tap(find.byKey(const ValueKey('primary-create-button')));
    await tester.pumpAndSettle();
    await tap(tester, 'one-line-recipe-entry');
    await tester.enterText(
      find.byKey(const ValueKey('one-line-input')),
      _request,
    );
    await tap(tester, 'one-line-search');
    await waitFor(tester, find.byKey(const ValueKey('ai-design-new')));
    await tap(tester, 'ai-design-new');
    await tap(tester, 'ai-skip-questions');
    // Existing-recipe cards can scroll this lazy row out on a narrow phone.
    // Reveal it before checking completion; keep the same enabled-state guard.
    await reveal(tester, 'one-line-search');
    await waitFor(
      tester,
      find.byWidgetPredicate(
        (widget) =>
            widget is FilledButton &&
            widget.key == const ValueKey('one-line-search') &&
            widget.onPressed != null,
      ),
    );
    await reveal(tester, 'text-edit-input');
    await waitFor(tester, find.text('今日修改剩余 $remaining 次'));
  }

  Future<void> preview(WidgetTester tester) async {
    await reveal(tester, 'text-edit-input');
    await tester.enterText(
      find.byKey(const ValueKey('text-edit-input')),
      _edit,
    );
    await tap(tester, 'text-edit-preview');
    await waitFor(
      tester,
      find.byWidgetPredicate(
        (widget) =>
            widget is OutlinedButton &&
            widget.key == const ValueKey('text-edit-preview') &&
            widget.onPressed != null,
      ),
    );
    await reveal(tester, 'text-edit-confirm');
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('text-edit-confirm')))
          .onPressed,
      isNull,
      reason: '尚未逐条确认的建议不能保存',
    );
  }

  Future<void> backToShell(WidgetTester tester) async {
    for (
      var i = 0;
      i < 6 &&
          find
              .byKey(const ValueKey('primary-create-button'))
              .evaluate()
              .isEmpty;
      i++
    ) {
      // Exercise platform Back: pageBack() requires the English "Back" tooltip,
      // while recipe detail has a custom localized list-navigation action.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('primary-create-button')), findsOneWidget);
  }

  testWidgets('两个本人入口逐条预览确认保存，再打开旧版和新版', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    var phase = 'login';
    try {
      // iOS Keychain sessions survive app uninstall between test targets.
      await resetLocalAppState();
      await app.main();
      await waitFor(tester, find.byKey(const ValueKey('consent-agree')));
      // iOS safe-area insets can place this action below the small viewport.
      await reveal(tester, 'consent-agree');
      await tester.tap(find.byKey(const ValueKey('consent-agree')));
      await waitFor(tester, find.byKey(const ValueKey('login-email')));
      final email =
          'text-edit-e2e-${DateTime.now().microsecondsSinceEpoch}@example.com';
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

      phase = 'create-original';
      await generate(tester);
      await tap(tester, 'ai-edit-draft');
      await tap(tester, 'save-recipe-button');
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-detail-content')),
      );
      await tap(tester, 'edit-recipe-button');
      await waitFor(tester, find.byKey(const ValueKey('text-edit-input')));

      phase = 'owned-editor-preview';
      await preview(tester);
      await tap(tester, 'text-edit-why-clarify-cook');
      expect(find.textContaining(_original), findsWidgets);
      expect(find.textContaining('需确认中心温度'), findsWidgets);
      expect(find.text('以后别这样'), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await settledChoice(tester, 'text-edit-reject-clarify-cook');
      await reveal(tester, 'text-edit-operation-remind-cook');
      expect(find.text('依赖被拒绝，已默认拒绝：clarify-cook'), findsOneWidget);
      await settledChoice(tester, 'text-edit-modify-explain-cook');
      await reveal(tester, 'text-edit-after-explain-cook');
      await tester.enterText(
        find.byKey(const ValueKey('text-edit-after-explain-cook')),
        _manualWhy,
      );
      await reveal(tester, 'text-edit-confirm');
      await waitFor(
        tester,
        find.byWidgetPredicate(
          (widget) =>
              widget is FilledButton &&
              widget.key == const ValueKey('text-edit-confirm') &&
              widget.onPressed != null,
        ),
      );
      await tap(tester, 'text-edit-confirm');
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-detail-content')),
      );
      await tap(tester, 'recipe-step-1');
      expect(find.textContaining(_original), findsOneWidget);
      expect(find.textContaining(_manualWhy), findsOneWidget);

      phase = 'reopen-old-and-new';
      await tap(tester, 'recipe-history-button');
      await waitFor(tester, find.byKey(const ValueKey('recipe-version-1')));
      await tap(tester, 'recipe-version-1');
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-detail-content')),
      );
      await tap(tester, 'recipe-step-1');
      expect(find.textContaining(_original), findsOneWidget);
      expect(find.textContaining(_manualWhy), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, 'recipe-version-2');
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-detail-content')),
      );
      await tap(tester, 'recipe-step-1');
      expect(find.textContaining(_manualWhy), findsOneWidget);
      await backToShell(tester);

      phase = 'generation-result-preview';
      await generate(tester, remaining: 49);
      await preview(tester);
      await settledChoice(tester, 'text-edit-accept-clarify-cook');
      await settledChoice(tester, 'text-edit-reject-explain-cook');
      await settledChoice(tester, 'text-edit-reject-remind-cook');
      await reveal(tester, 'text-edit-confirm');
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('text-edit-confirm')),
            )
            .onPressed,
        isNotNull,
      );
      await tap(tester, 'text-edit-confirm');
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-detail-content')),
      );
      await reveal(tester, 'recipe-step-1');
      expect(find.textContaining(_clarified), findsOneWidget);
      await tap(tester, 'recipe-history-button');
      await waitFor(tester, find.byKey(const ValueKey('recipe-version-1')));
      expect(
        find.byKey(const ValueKey('recipe-version-2')),
        findsNothing,
        reason: '生成修改预览不得提前创建版本',
      );
      await tap(tester, 'recipe-version-1');
      await waitFor(
        tester,
        find.byKey(const ValueKey('recipe-detail-content')),
      );
      await reveal(tester, 'recipe-step-1');
      expect(find.textContaining(_clarified), findsOneWidget);
      expect(tester.takeException(), isNull);
    } catch (error, stack) {
      IntegrationTestWidgetsFlutterBinding.instance.reportData = {
        'phase': phase,
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
