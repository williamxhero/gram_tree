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
  const profilePath = '/v1/me/taste-profile';

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(finder, findsWidgets);
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final scroll = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    // Lazy rows may be either above or below the current viewport after a save.
    for (var i = 0; i < 12; i++) {
      await tester.drag(scroll, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: scroll,
      maxScrolls: 60,
    );
    await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await reveal(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> loginPage(WidgetTester tester, String email) async {
    await waitFor(tester, find.byKey(const ValueKey('login-email')));
    await tester.enterText(find.byKey(const ValueKey('login-email')), email);
    await tester.tap(find.text('发送验证码'));
    await waitFor(tester, find.byKey(const ValueKey('code-input')));
    final code =
        (await server.get(
              '/v1/dev/latest-email-code',
              queryParameters: {'email': email},
            )).data['code']
            as String;
    await tester.enterText(find.byKey(const ValueKey('code-input')), code);
    await waitFor(tester, find.text('先添加一道你常做的菜'));
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('taste-profile-entry')));
    await waitFor(tester, find.byKey(const ValueKey('taste-profile-content')));
  }

  Future<Options> loginApi(String email) async {
    final device = Options(headers: {'X-Device-ID': email});
    await server.post(
      '/v1/auth/email/code',
      data: {'email': email, 'purpose': 'login'},
      options: device,
    );
    final code = (await server.get(
      '/v1/dev/latest-email-code',
      queryParameters: {'email': email},
    )).data['code'];
    final tokens = (await server.post(
      '/v1/auth/email/login',
      data: {'email': email, 'code': code},
      options: device,
    )).data;
    return Options(
      headers: {'Authorization': 'Bearer ${tokens['access_token']}'},
    );
  }

  testWidgets('标准食材和分类偏好保存、改选、删除、历史与跨账号隔离', (tester) async {
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    final serial = DateTime.now().microsecondsSinceEpoch;
    var step = 'HTTP privacy';
    try {
      // Browser acceptance also exercises the public invalid-reference seam;
      // credentials come only from the public login API, never App internals.
      final owner = await loginApi('prefs-api-owner-$serial@example.com');
      final other = await loginApi('prefs-api-other-$serial@example.com');
      final baseline = (await server.get(profilePath, options: owner)).data;
      final saved = (await server.patch(
        profilePath,
        data: {
          'ingredient_preferences': [
            {'category': '蔬菜', 'preference': 'avoided'},
          ],
        },
        options: owner,
      )).data;
      expect(saved['version'], baseline['version'] + 1);
      final rejected = await server.patch(
        profilePath,
        data: {
          'flavors': {'salty': 0.75},
          'ingredient_preferences': [
            {
              'ingredient_id': 'ffffffff-ffff-4fff-8fff-ffffffffffff',
              'preference': 'liked',
            },
          ],
        },
        options: owner.copyWith(validateStatus: (_) => true),
      );
      expect(rejected.statusCode, 422);
      expect((await server.get(profilePath, options: owner)).data, saved);
      final history =
          (await server.get(
                '$profilePath/changes',
                options: owner,
              )).data['items']
              as List;
      expect(history.single['reason'], '你手动修改');
      expect(history.single['version'], saved['version']);
      expect(
        (await server.get(
          profilePath,
          options: other,
        )).data['ingredient_preferences'],
        isEmpty,
      );
      expect(
        (await server.get(
          '$profilePath/changes/${history.single['id']}',
          options: other.copyWith(validateStatus: (_) => true),
        )).statusCode,
        404,
      );

      step = 'UI login';
      await app.main();
      await waitFor(tester, find.byKey(const ValueKey('consent-agree')));
      await tester.tap(find.byKey(const ValueKey('consent-agree')));
      await loginPage(tester, 'prefs-ui-owner-$serial@example.com');
      step = 'ingredient search';
      await tapKey(tester, 'taste-preference-add');
      await tester.enterText(
        find.byKey(const ValueKey('taste-ingredient-search')),
        '香菜',
      );
      await tester.tap(
        find.byKey(const ValueKey('taste-ingredient-search-submit')),
      );
      await waitFor(tester, find.text('香菜'));
      final result = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('taste-search-'),
      );
      expect(result, findsOneWidget);
      final searchKey = (tester.widget(result).key as ValueKey<String>).value;
      final ingredientId = searchKey.substring('taste-search-'.length);
      await tester.tap(result);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('taste-preference-save')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('taste-profile-content')),
      );
      await reveal(tester, find.text('香菜 · 喜欢'));
      expect(find.text('香菜 · 喜欢'), findsOneWidget);

      step = 'category select';
      await tapKey(tester, 'taste-preference-add');
      await tester.tap(find.byKey(const ValueKey('taste-preference-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('蔬菜').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('taste-preference-choice')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('忌口').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('taste-preference-save')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('taste-profile-content')),
      );
      await reveal(tester, find.text('蔬菜 · 忌口'));

      step = 'reopen and edit';
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('taste-profile-entry')));
      await waitFor(
        tester,
        find.byKey(const ValueKey('taste-profile-content')),
      );
      await reveal(tester, find.text('香菜 · 喜欢'));
      expect(find.text('蔬菜 · 忌口'), findsOneWidget);
      await tapKey(tester, 'taste-preference-kind-ingredient:$ingredientId');
      await tester.tap(find.text('不喜欢').last);
      await tester.pumpAndSettle();
      await waitFor(
        tester,
        find.byKey(const ValueKey('taste-profile-content')),
      );
      await reveal(tester, find.text('香菜 · 不喜欢'));

      step = 'delete and history';
      await tapKey(tester, 'taste-preference-delete-ingredient:$ingredientId');
      await tester.tap(
        find.byKey(const ValueKey('taste-preference-delete-confirm')),
      );
      await waitFor(
        tester,
        find.byKey(const ValueKey('taste-profile-content')),
      );
      await reveal(tester, find.text('蔬菜 · 忌口'));
      expect(find.text('香菜 · 不喜欢'), findsNothing);
      await reveal(tester, find.text('食材偏好：未设置 → 香菜 · 喜欢'));
      expect(find.textContaining('你手动修改'), findsWidgets);
      expect(find.text(ingredientId), findsNothing);

      step = 'cross-account UI';
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('设置'));
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('退出登录'));
      await tester.tap(find.text('退出登录'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '退出登录'));
      await loginPage(tester, 'prefs-ui-other-$serial@example.com');
      await reveal(tester, find.text('还没有食材偏好'));
      expect(find.text('蔬菜 · 忌口'), findsNothing);
      await reveal(tester, find.text('还没有修改记录'));
      expect(find.text('食材偏好：未设置 → 香菜 · 喜欢'), findsNothing);
      expect(tester.takeException(), isNull);
    } catch (error, stack) {
      IntegrationTestWidgetsFlutterBinding.instance.reportData = {
        'step': step,
        'error': error.toString(),
        'stack': stack.toString(),
        'page_text': tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data)
            .toList(),
      };
      rethrow;
    }
  });
}
