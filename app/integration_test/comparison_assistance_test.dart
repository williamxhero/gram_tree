import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:gram_tree/ui_protocol/components/component_scaffold.dart';
import 'package:integration_test/integration_test.dart';

// Runner inputs describe the public, synthetic replay corpus, not API models.
typedef _Case = ({
  String label,
  String recipeId,
  String fromVersionId,
  String toVersionId,
  String? assistedAfterId,
});

const _cases = <_Case>[
  (
    label: 'high-a',
    recipeId: String.fromEnvironment('E2E_ASSISTANCE_HIGH_A_RECIPE_ID'),
    fromVersionId: String.fromEnvironment(
      'E2E_ASSISTANCE_HIGH_A_FROM_VERSION_ID',
    ),
    toVersionId: String.fromEnvironment('E2E_ASSISTANCE_HIGH_A_TO_VERSION_ID'),
    assistedAfterId: 'a',
  ),
  (
    label: 'high-b',
    recipeId: String.fromEnvironment('E2E_ASSISTANCE_HIGH_B_RECIPE_ID'),
    fromVersionId: String.fromEnvironment(
      'E2E_ASSISTANCE_HIGH_B_FROM_VERSION_ID',
    ),
    toVersionId: String.fromEnvironment('E2E_ASSISTANCE_HIGH_B_TO_VERSION_ID'),
    assistedAfterId: 'b',
  ),
  (
    label: 'low',
    recipeId: String.fromEnvironment('E2E_ASSISTANCE_LOW_RECIPE_ID'),
    fromVersionId: String.fromEnvironment('E2E_ASSISTANCE_LOW_FROM_VERSION_ID'),
    toVersionId: String.fromEnvironment('E2E_ASSISTANCE_LOW_TO_VERSION_ID'),
    assistedAfterId: null,
  ),
  (
    label: 'unavailable',
    recipeId: String.fromEnvironment('E2E_ASSISTANCE_UNAVAILABLE_RECIPE_ID'),
    fromVersionId: String.fromEnvironment(
      'E2E_ASSISTANCE_UNAVAILABLE_FROM_VERSION_ID',
    ),
    toVersionId: String.fromEnvironment(
      'E2E_ASSISTANCE_UNAVAILABLE_TO_VERSION_ID',
    ),
    assistedAfterId: null,
  ),
];

void _mark(String step) {
  final binding = IntegrationTestWidgetsFlutterBinding.instance;
  binding.reportData = {...?binding.reportData, 'e2e_step': step};
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _waitFor(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 300 && target.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(target, findsWidgets);
  await _settle(tester);
}

Future<void> _reveal(
  WidgetTester tester,
  Finder target, {
  String contentKey = 'full-comparison-content',
}) async {
  tester.testTextInput.hide();
  await tester.pump();
  final body = find.byKey(ValueKey(contentKey));
  if (target.evaluate().isEmpty) {
    for (var i = 0; i < 20; i++) {
      await tester.drag(body, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    for (var i = 0; i < 80 && target.evaluate().isEmpty; i++) {
      await tester.drag(body, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  // Select the first painted target only after lazy children actually mount.
  expect(target, findsWidgets);
  await tester.ensureVisible(target.first);
  await _settle(tester);
  expect(target.first.hitTestable(), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _reveal(tester, target);
  await tester.tap(target.first);
  await _settle(tester);
}

Future<void> _back(WidgetTester tester) async {
  final back = find.byTooltip('返回');
  await _waitFor(tester, back);
  await tester.tap(back.last);
  await _settle(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('回放辅助对齐与一般经验解读保留确定规则、原始字段及历史；低把握和不可用可降级', (tester) async {
    try {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const email = String.fromEnvironment('E2E_ASSISTANCE_EMAIL');
      expect(
        email,
        isNotEmpty,
        reason: 'Runner must provide corpus actor email',
      );
      for (final fixture in _cases) {
        expect(
          fixture.recipeId,
          isNotEmpty,
          reason: 'Runner must provide ${fixture.label} recipe ID',
        );
        expect(fixture.fromVersionId, isNotEmpty);
        expect(fixture.toVersionId, isNotEmpty);
      }
      tester.testTextInput.register();
      addTearDown(tester.testTextInput.unregister);
      await app.main();
      await _settle(tester);
      if (find.byKey(const ValueKey('consent-agree')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const ValueKey('consent-agree')));
        await _settle(tester);
      }
      await _waitFor(tester, find.text('登录味谱'));
      await tester.enterText(find.byKey(const ValueKey('login-email')), email);
      // Public seeding also uses OTP. Honor its real resend deadline rather
      // than changing cooldown configuration or relying on fake pump time.
      const notBefore = int.fromEnvironment(
        'E2E_ASSISTANCE_LOGIN_NOT_BEFORE_MS',
      );
      while (DateTime.now().millisecondsSinceEpoch < notBefore) {
        final remaining = notBefore - DateTime.now().millisecondsSinceEpoch;
        await tester.runAsync(
          () => Future<void>.delayed(Duration(milliseconds: remaining)),
        );
      }
      await tester.tap(find.text('发送验证码'));
      await _waitFor(tester, find.text('输入验证码'));
      final server = Dio(
        BaseOptions(baseUrl: AppConfig.fromEnvironment().apiBaseUrl),
      );
      final code = await server.get<Map<String, dynamic>>(
        '/v1/dev/latest-email-code',
        queryParameters: {'email': email},
      );
      await tester.enterText(
        find.byKey(const ValueKey('code-input')),
        code.data!['code'] as String,
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('primary-create-button')),
      );
      _mark('comparison_assistance_logged_in');

      for (final fixture in _cases) {
        // Public navigation uses the same registered route as history entries.
        GoRouter.of(tester.element(find.byType(Scaffold).first)).push(
          '/recipes/${fixture.recipeId}/full-compare?from=${fixture.fromVersionId}&to=${fixture.toVersionId}',
        );
        await _waitFor(
          tester,
          find.byKey(const ValueKey('full-comparison-content')),
        );
        await _waitFor(
          tester,
          find.byKey(
            ValueKey(
              fixture.assistedAfterId == null
                  ? 'comparison-assistance-unavailable'
                  : 'comparison-assistance-ready',
            ),
          ),
        );
        expect(find.text('一般改动'), findsOneWidget);
        expect(find.textContaining('不依赖 AI'), findsOneWidget);
        const interpretation = '两版都炒熟，后一版分成两步，更适合分批操作。';
        if (fixture.assistedAfterId != null) {
          await _reveal(tester, find.text(interpretation));
          expect(find.text(interpretation), findsOneWidget);
          await _tap(
            tester,
            find.byKey(const ValueKey('comparison-interpretation-why')),
          );
          expect(find.byKey(const ValueKey('why-panel')), findsOneWidget);
          expect(find.text('AI 解读依据'), findsOneWidget);
          expect(find.textContaining('general_experience'), findsOneWidget);
          expect(find.text('已验证'), findsNothing);
          expect(find.text('这次不用'), findsNothing);
          expect(find.text('以后别这样'), findsNothing);
          await tester.tapAt(const Offset(10, 10));
          await _settle(tester);
          await _tap(
            tester,
            find.byKey(const ValueKey('comparison-assistance-why-0')),
          );
          expect(find.text('AI 辅助对齐依据'), findsOneWidget);
          expect(find.textContaining('把握程度：95%'), findsWidgets);
          expect(find.textContaining('把握程度：达到辅助展示门槛，非验证结论。'), findsOneWidget);
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('why-panel')),
              matching: find.textContaining('95%'),
            ),
            findsNothing,
          );
          expect(find.textContaining('服务端把握程度原值'), findsNothing);
          expect(find.text('这次不用'), findsNothing);
          expect(find.text('以后别这样'), findsNothing);
          await tester.tapAt(const Offset(10, 10));
          await _settle(tester);
        } else {
          expect(find.text(interpretation), findsNothing);
          expect(find.text('AI · 一般经验'), findsNothing);
          expect(find.text('AI 辅助对齐'), findsNothing);
          await _reveal(
            tester,
            find.byKey(const ValueKey('comparison-assistance-unaligned')),
          );
          expect(find.textContaining('未能对齐 · 双方原文保留'), findsOneWidget);
        }
        await _tap(tester, find.byKey(const ValueKey('full-compare-show-all')));
        await _tap(
          tester,
          find.byKey(const ValueKey('full-compare-expand-all')),
        );
        if (fixture.assistedAfterId != null) {
          final pair = find.byKey(
            const ValueKey('comparison-assistance-pair-0'),
          );
          for (final value in [
            '步骤 ID：cook',
            '步骤 ID：${fixture.assistedAfterId}',
            '动作：炒',
            '时长（秒）：100',
            '引用食材 ID：["sauce"]',
            '厨具：炒锅',
            '成熟判断：无',
          ]) {
            final original = find.descendant(
              of: pair,
              matching: find.text(value),
            );
            await _reveal(tester, original);
            expect(original, findsWidgets);
          }
        } else {
          for (final id in ['cook', 'a', 'b']) {
            await _reveal(tester, find.text('步骤 ID：$id'));
            expect(find.text('步骤 ID：$id'), findsOneWidget);
          }
        }
        // Every corpus case retains the same original remove/add/add rules,
        // even though the two accepted AI overlays show different B partners.
        for (final index in [0, 1, 2]) {
          final marker = find.byKey(
            ValueKey('comparison-why-step-$index-step'),
          );
          await _reveal(tester, marker);
          final card = find.ancestor(
            of: marker,
            matching: find.byType(ComponentCard),
          );
          expect(
            find.descendant(of: card, matching: find.text('幅度：一般')),
            findsOneWidget,
          );
        }
        final caseStep =
            'comparison_assistance_${fixture.label.replaceAll('-', '_')}';
        _mark('${caseStep}_open_a');
        await _tap(tester, find.byKey(const ValueKey('full-compare-detail-a')));
        await _waitFor(
          tester,
          find.byKey(const ValueKey('recipe-detail-content')),
        );
        // Detail deliberately returns to the recipe list, not its caller.
        // Re-enter the same comparison through the real history full entry.
        _mark('${caseStep}_a_to_history');
        await tester.tap(find.byKey(const ValueKey('recipe-history-button')));
        final fullHistory = find.byKey(
          const ValueKey('recipe-full-compare-previous-2'),
        );
        await _waitFor(tester, fullHistory);
        expect(find.text('一般改动 · 对比上一版本'), findsOneWidget);
        _mark('${caseStep}_history_to_comparison');
        await tester.ensureVisible(fullHistory);
        await tester.tap(fullHistory);
        await _waitFor(
          tester,
          find.byKey(const ValueKey('full-comparison-content')),
        );
        expect(find.text('一般改动'), findsOneWidget);
        _mark('${caseStep}_open_b');
        await _tap(tester, find.byKey(const ValueKey('full-compare-detail-b')));
        await _waitFor(
          tester,
          find.byKey(const ValueKey('recipe-detail-content')),
        );
        // Detail evidence can push the saved conclusion below a phone's lazy
        // viewport; mount it by scrolling before checking the persisted grade.
        await _reveal(
          tester,
          find.byKey(const ValueKey('recipe-version-conclusion')),
          contentKey: 'recipe-detail-content',
        );
        await _waitFor(
          tester,
          find.byKey(const ValueKey('recipe-version-conclusion')),
        );
        final saved = find.byKey(const ValueKey('recipe-version-conclusion'));
        expect(
          find.descendant(of: saved, matching: find.textContaining('一般改动')),
          findsOneWidget,
        );
        _mark('${caseStep}_b_to_saved_history');
        await tester.ensureVisible(saved);
        await tester.tap(saved);
        await _waitFor(tester, find.byKey(const ValueKey('recipe-version-2')));
        expect(find.text('一般改动 · 对比上一版本'), findsOneWidget);
        _mark('${caseStep}_history_to_b');
        await _back(tester);
        await _waitFor(
          tester,
          find.byKey(const ValueKey('recipe-detail-content')),
        );
        _mark('${caseStep}_b_to_recipe_list');
        await tester.tap(find.byKey(const ValueKey('recipe-list-button')));
        await _waitFor(tester, find.byKey(const ValueKey('new-recipe-button')));
        _mark(
          'comparison_assistance_${fixture.label.replaceAll('-', '_')}_completed',
        );
      }
      _mark('comparison_assistance_completed');
    } catch (error, stack) {
      final binding = IntegrationTestWidgetsFlutterBinding.instance;
      binding.reportData = {
        ...?binding.reportData,
        'e2e_error': error.toString(),
        'e2e_stack': stack.toString(),
      };
      rethrow;
    }
  }, timeout: const Timeout(Duration(minutes: 6)));
}
