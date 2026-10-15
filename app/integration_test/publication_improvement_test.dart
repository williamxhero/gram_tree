import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/router.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:gramtree_api/gramtree_api.dart';
import 'package:integration_test/integration_test.dart';

import '../test/cooking_controls_support.dart';
import '../test/lazy_list_controls_support.dart';
import 'event_pipeline_support.dart' show containerOf, resetLocalAppState;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final transport = Dio(
    BaseOptions(baseUrl: AppConfig.fromEnvironment().apiBaseUrl),
  );
  final api = GramtreeApi(dio: transport, interceptors: const []);
  Finder key(String name) => find.byKey(ValueKey(name));
  final privateValues = <String>{};
  String safeDiagnostic(Object value) {
    var text = value.toString();
    for (final secret in privateValues) {
      if (secret.isNotEmpty) text = text.replaceAll(secret, '<redacted>');
    }
    return text.replaceAll(RegExp(r'Bearer\s+[^\s]+'), 'Bearer <redacted>');
  }

  void step(String name) => binding.reportData = {'e2e_step': name};
  Future<void> ready(WidgetTester tester, Finder finder) async {
    binding.reportData = {
      ...?binding.reportData,
      'waiting_for': finder.toString(),
    };
    for (var n = 0; n < 300 && finder.evaluate().isEmpty; n++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsWidgets, reason: 'Timed out waiting for $finder');
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await revealLazyListControl(
      tester,
      finder,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await reveal(tester, finder);
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
  }

  Future<String> code(String email) async =>
      (await transport.get<Map<String, dynamic>>(
            '/v1/dev/latest-email-code',
            queryParameters: {'email': email},
          )).data!['code']
          as String;
  Future<TokenPair> actor(String email) async {
    await api.getAuthApi().sendEmailCode(
      emailCodeRequest: EmailCodeRequest(
        email: email,
        purpose: EmailCodeRequestPurposeEnum.login,
      ),
    );
    return (await api.getAuthApi().emailLogin(
      emailLoginRequest: EmailLoginRequest(
        email: email,
        code: await code(email),
      ),
    )).data!;
  }

  Future<void> denied(Future<dynamic> Function() request) async {
    int? status;
    try {
      await request();
    } on DioException catch (error) {
      status = error.response?.statusCode;
    }
    expect(status, 404);
  }

  testWidgets(
    'real publication, exact-source improvement, explicit microadjust and withdrawal isolation',
    (tester) async {
      step('publication-login');
      try {
        tester.testTextInput.register();
        addTearDown(tester.testTextInput.unregister);
        await resetLocalAppState();
        await app.main();
        await tester.pumpAndSettle();
        if (key('consent-agree').evaluate().isNotEmpty) {
          await tap(tester, key('consent-agree'));
        }
        await ready(tester, key('login-email'));
        final stamp = DateTime.now().microsecondsSinceEpoch;
        final email = 'publication-owner-$stamp@example.com';
        await tester.enterText(key('login-email'), email);
        await tester.tap(find.text('发送验证码'));
        await ready(tester, key('code-input'));
        await tester.enterText(key('code-input'), await code(email));
        await ready(tester, find.text('今天'));
        final container = containerOf(tester);
        final owner = container.read(sessionStoreProvider).current!;
        final ownerHeaders = {'Authorization': 'Bearer ${owner.accessToken}'};
        final reader = await actor('publication-reader-$stamp@example.com');
        final readerHeaders = {'Authorization': 'Bearer ${reader.accessToken}'};
        privateValues.addAll([
          owner.accessToken,
          owner.refreshToken,
          reader.accessToken,
          reader.refreshToken,
        ]);
        step('publication-create-fixture');
        // Generated endpoints establish an ordinary reproducible recipe; all
        // publication/improvement/lifecycle mutations below are visible UI actions.
        final original = (await api.getRecipesApi().createRecipe(
          headers: ownerHeaders,
          recipeCreate: RecipeCreate(
            dishName: '公开验收盐水$stamp',
            snapshot: RecipeSnapshot.fromJson({
              'format_version': 1,
              'servings': 2,
              'total_time_seconds': 0,
              'active_time_seconds': 0,
              'ingredients': [
                {
                  'id': 'ingredient-1',
                  'display_name': '盐',
                  'quantity': 100,
                  'unit': 'g',
                  'functional': false,
                  'optional': false,
                  'scaling_mode': 'proportional',
                },
              ],
              'steps': [
                {
                  'id': 'step-1',
                  'instruction': '将盐拌匀至溶解',
                  'action': '拌',
                  'ingredient_ids': ['ingredient-1'],
                  'duration_seconds': 0,
                  'unattended': false,
                  'cookware': '碗',
                  'doneness': '溶解',
                  'depends_on': <String>[],
                },
              ],
            }),
          ),
        )).data!;
        await denied(
          () => api.getRecipesApi().getRecipe(
            recipeId: original.id,
            headers: readerHeaders,
          ),
        );
        // Navigation is fixture setup, not a substitute for publication actions.
        container
            .read(routerProvider)
            .go('/recipes/${original.id}?versionId=${original.version.id}');
        await ready(tester, key('publication-panel'));
        await reveal(tester, key('draft-auto-public'));
        expect(find.textContaining('做过后会自动公开'), findsWidgets);
        await tap(tester, key('publication-condition-not_cooked'));
        await ready(tester, find.byTooltip('暂离'));
        await revealCookingControl(tester, find.text('开始第一步'));
        await ready(tester, find.text('开始第一步'));
        await tester.tap(find.text('开始第一步').hitTestable());
        await tester.pumpAndSettle();
        await revealCookingControl(tester, key('cooking-action'));
        await ready(tester, key('cooking-action'));
        await revealCookingControl(tester, find.text('完成'));
        await tester.tap(find.text('完成').hitTestable());
        await tester.pumpAndSettle();
        await ready(tester, key('cooking-complete'));
        await ready(tester, key('publication-license-notice'));
        expect(find.textContaining('CC BY-NC-SA 4.0'), findsWidgets);

        step('improvement-switch-reader');
        await container.read(sessionStoreProvider).save(reader);
        step('improvement-open-exact-source');
        container
            .read(routerProvider)
            .go('/recipes/${original.id}?versionId=${original.version.id}');
        await ready(tester, key('improve-recipe-button'));
        expect(find.text('删除菜谱'), findsNothing);
        step('improvement-create-draft');
        await tap(tester, key('improve-recipe-button'));
        await ready(tester, key('recipe-editor-content'));
        step('improvement-edit-quantity');
        // The full editor uses a lazy list; waiting alone cannot build this field.
        await reveal(tester, key('recipe-ingredient-quantity'));
        await tester.enterText(key('recipe-ingredient-quantity'), '98');
        step('improvement-preview-first-save');
        await tap(tester, key('save-recipe-button'));
        await ready(tester, key('improvement-save-branch'));
        step('improvement-cancel-microadjust');
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        expect(key('recipe-editor-content'), findsOneWidget);
        step('improvement-preview-second-save');
        await tap(tester, key('save-recipe-button'));
        await ready(tester, key('improvement-save-branch'));
        step('improvement-save-branch');
        await tester.tap(key('improvement-save-branch'));
        step('improvement-source-attribution');
        await ready(tester, key('recipe-detail-content'));
        await reveal(tester, key('source-attribution'));
        await reveal(tester, key('source-attribution-chain'));
        expect(find.textContaining('改良自'), findsWidgets);
        await tester.tap(key('source-attribution-chain'));
        await ready(tester, find.text('到根菜谱的来源链'));
        expect(find.textContaining('第 1 版'), findsWidgets);
        await tester.tap(find.text('关闭'));
        await tester.pumpAndSettle();

        step('withdraw-switch-owner');
        await container
            .read(sessionStoreProvider)
            .save(
              TokenPair(
                accessToken: owner.accessToken,
                refreshToken: owner.refreshToken,
                accessExpiresIn: 1800,
                user: owner.user,
              ),
            );
        container
            .read(routerProvider)
            .go('/recipes/${original.id}?versionId=${original.version.id}');
        step('withdraw-open-owner-recipe');
        await ready(tester, key('publication-lifecycle'));
        step('withdraw-confirm');
        await tap(tester, key('publication-lifecycle'));
        await ready(tester, key('publication-confirm-lifecycle'));
        await tester.tap(key('publication-confirm-lifecycle'));
        await tester.pumpAndSettle();
        step('withdraw-reader-denied');
        await denied(
          () => api.getRecipesApi().getRecipe(
            recipeId: original.id,
            headers: readerHeaders,
          ),
        );
        step('restore-confirm');
        await tap(tester, key('publication-lifecycle'));
        await ready(tester, key('publication-confirm-lifecycle'));
        await tester.tap(key('publication-confirm-lifecycle'));
        await tester.pumpAndSettle();
        expect(
          (await api.getRecipesApi().getRecipe(
            recipeId: original.id,
            headers: readerHeaders,
          )).data!.id,
          original.id,
        );
        step('complete');
      } catch (error, stack) {
        binding.reportData = {
          ...?binding.reportData,
          'error': safeDiagnostic(error),
          'visible_text': find
              .byType(Text)
              .evaluate()
              .map((element) => (element.widget as Text).data)
              .whereType<String>()
              .take(40)
              .map(safeDiagnostic)
              .toList(),
          'stack': safeDiagnostic(stack),
        };
        rethrow;
      }
    },
  );
}
