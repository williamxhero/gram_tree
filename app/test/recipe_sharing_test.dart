import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_tree/app/router.dart';

import 'helpers.dart';
import 'sharing_support.dart';

import 'package:gram_tree/recipes/recipe_sharing.dart';

void main() {
  testWidgets(
    'public opaque link resolves, detail shares only URL, invalid has fallback',
    (tester) async {
      final env = SharingTestEnv();
      await pumpApp(tester, env: env);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      container.read(routerProvider).go('/s/$publicShareId');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recipe-share-button')), findsOneWidget);
      final resolver = env.server
          .calls('GET', '/v1/shares/$publicShareId')
          .single;
      expect(resolver.headers['Authorization'], isNull);
      expect(resolver.headers['X-Device-ID'], isNull);
      await tester.tap(find.byKey(const ValueKey('recipe-share-button')));
      await tester.pumpAndSettle();
      expect(env.sharing.texts, [publicShareUrl]);
      expect(env.sharing.texts.single, isNot(contains('烧开')));
      container.read(routerProvider).go('/s/not-found');
      await tester.pumpAndSettle();
      expect(find.text('菜谱不存在或已下架'), findsOneWidget);
      expect(find.textContaining('未安装 App'), findsOneWidget);
    },
  );

  testWidgets(
    'public link survives login without exposing the full recipe before login',
    (tester) async {
      final env = SharingTestEnv(signedIn: false);
      await pumpApp(tester, env: env);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      container.read(routerProvider).go('/s/$publicShareId');
      await tester.pumpAndSettle();
      expect(find.text('完整菜谱需要登录后查看'), findsOneWidget);
      expect(env.server.calls('GET', '/v1/recipes/$sharedRecipeId'), isEmpty);
      expect(find.textContaining('未安装 App'), findsOneWidget);
      await tester.tap(find.text('登录后查看完整菜谱'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('login-email')),
        testEmail,
      );
      await tester.tap(find.text('发送验证码'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('code-input')),
        goodCode,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recipe-share-button')), findsOneWidget);
    },
  );
  test('uses generated share API and returns validated links', () async {
    RequestOptions? captured;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: {
                  'share_id': 'share-1',
                  'url': 'https://gramtree.example.test/s/share-1',
                  'app_path': '/recipes/recipe-1',
                },
              ),
            );
          },
        ),
      );
    final api = GramtreeApi(dio: dio, interceptors: const []);
    final sharing = ApiRecipeSharing(api);

    final link = await sharing.create('recipe-1');

    expect(captured?.method, 'POST');
    expect(captured?.path, '/v1/recipes/recipe-1/share');
    expect(link.url, 'https://gramtree.example.test/s/share-1');
    expect(link.appPath, '/recipes/recipe-1');
  });

  test('rejects non-HTTPS share URLs', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              data: {
                'share_id': 'share-1',
                'url': 'http://gramtree.example.test/s/share-1',
                'app_path': '/recipes/recipe-1',
              },
            ),
          ),
        ),
      );
    final sharing = ApiRecipeSharing(
      GramtreeApi(dio: dio, interceptors: const []),
    );

    await expectLater(sharing.create('recipe-1'), throwsFormatException);
  });
}
