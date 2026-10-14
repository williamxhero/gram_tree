import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/router.dart';

import 'helpers.dart';
import 'sharing_http_fixture_stub.dart'
    if (dart.library.io) 'sharing_http_fixture_io.dart';
import 'sharing_support.dart';
import 'settings_test.dart' show openSettings;

Future<void> _openShare(
  WidgetTester tester,
  SharingTestEnv env,
  String path,
) async {
  await pumpApp(tester, env: env);
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Scaffold).first),
  );
  container.read(routerProvider).go(path);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('logout during share creation never opens the system panel', (
    tester,
  ) async {
    final env = SharingTestEnv();
    final result = Completer<(int, Object?)>();
    env.server.on(
      'POST',
      '/v1/recipes/$sharedRecipeId/share',
      (_) => result.future,
    );
    await _openShare(tester, env, '/recipes/$sharedRecipeId');
    await tester.tap(find.byKey(const ValueKey('recipe-share-button')));
    // The pending share deliberately keeps its progress indicator animating.
    for (
      var i = 0;
      i < 40 &&
          env.server.calls('POST', '/v1/recipes/$sharedRecipeId/share').isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(
      env.server.calls('POST', '/v1/recipes/$sharedRecipeId/share'),
      hasLength(1),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    container.read(routerProvider).go('/me');
    await tester.pumpAndSettle();
    await openSettings(tester);
    await tapVisible(tester, find.text('退出登录'));
    await tester.tap(find.widgetWithText(FilledButton, '退出登录'));
    await tester.pumpAndSettle();
    expect(find.text('登录味谱'), findsOneWidget);
    result.complete((
      200,
      {
        'share_id': publicShareId,
        'url': publicShareUrl,
        'app_path': '/recipes/$sharedRecipeId',
      },
    ));
    await tester.pumpAndSettle();
    expect(env.sharing.texts, isEmpty);
    expect(env.sharing.images, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'public opaque link resolves, detail shares only URL, invalid has fallback',
    (tester) async {
      final env = SharingTestEnv();
      await _openShare(tester, env, '/s/$publicShareId');
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
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
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
      await _openShare(tester, env, '/s/$publicShareId');
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

  testWidgets('uses generated share API and returns validated links', (
    tester,
  ) async {
    final env = SharingTestEnv();
    await _openShare(tester, env, '/recipes/$sharedRecipeId');
    await tester.tap(find.byKey(const ValueKey('recipe-share-button')));
    await tester.pumpAndSettle();
    expect(
      env.server.calls('POST', '/v1/recipes/$sharedRecipeId/share'),
      hasLength(1),
    );
    expect(env.sharing.texts, [publicShareUrl]);
  });

  testWidgets('rejects non-HTTPS share URLs', (tester) async {
    final env = SharingTestEnv();
    env.server.on(
      'POST',
      '/v1/recipes/$sharedRecipeId/share',
      (_) => (
        200,
        {
          'share_id': publicShareId,
          'url': 'http://gramtree.app/s/$publicShareId',
          'app_path': '/recipes/$sharedRecipeId',
        },
      ),
    );
    await _openShare(tester, env, '/recipes/$sharedRecipeId');
    await tester.tap(find.byKey(const ValueKey('recipe-share-button')));
    await tester.pumpAndSettle();
    expect(env.sharing.texts, isEmpty);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets(
    'public recipe share entry fails closed when the feature is disabled',
    (tester) async {
      final env = SharingTestEnv(publicRecipes: false);
      await _openShare(tester, env, '/recipes/$sharedRecipeId');
      expect(find.byKey(const ValueKey('edit-recipe-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('recipe-share-button')), findsNothing);
      expect(
        env.server.calls('POST', '/v1/recipes/$sharedRecipeId/share'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'sharing includes finished image bytes only from the trusted image API',
    (tester) async {
      final env = SharingTestEnv(withImage: true);
      // The snapshot's first image can be older than the public route's image.
      final detail = sharedDetail(
        withImage: true,
        imageContentType: 'image/jpeg',
      ).toJson();
      env.server.on('GET', '/v1/recipes/$sharedRecipeId', (_) => (200, detail));
      await _openShare(tester, env, '/recipes/$sharedRecipeId');
      await tester.tap(find.byKey(const ValueKey('recipe-share-button')));
      await tester.pumpAndSettle();
      expect(env.sharing.texts, [publicShareUrl]);
      if (kIsWeb) {
        expect(env.sharing.images.single, isNull);
        expect(find.text('分享链接已复制'), findsOneWidget);
      } else {
        expect(env.sharing.images.single, testImageBytes);
        expect(env.sharing.contentTypes.single, 'image/png');
        final imageCall = env.server
            .calls('GET', '/s/$publicShareId/image')
            .single;
        expect(imageCall.headers['Authorization'], isNull);
        expect(imageCall.headers['X-Device-ID'], isNull);
        expect(
          env.server.calls('GET', '/s/$publicShareId/image'),
          hasLength(1),
        );
      }
      expect(
        env.server.calls(
          'GET',
          '/v1/recipes/$sharedRecipeId/images/$sharedImageId',
        ),
        isEmpty,
      );
      expect(env.server.calls('GET', '/image.png'), isEmpty);
    },
  );

  for (final redirect in [false, true]) {
    testWidgets(
      'native image HTTP ${redirect ? 'refuses cross-origin redirects' : 'uses anonymous API-origin bytes'}',
      (tester) async {
        final fixture = (await tester.runAsync(
          () => SharingImageHttpFixture.start(redirect: redirect),
        ))!;
        addTearDown(fixture.close);
        final env = SharingTestEnv(
          withImage: true,
          fixtureServer: fixture.server,
          apiBaseUrl: fixture.apiBaseUrl,
        );
        env.server.on(
          'GET',
          '/v1/recipes/$sharedRecipeId',
          (_) => (
            200,
            sharedDetail(
              withImage: true,
              imageUrl: fixture.foreignImageUrl,
              imageContentType: 'image/jpeg',
            ).toJson(),
          ),
        );
        if (redirect) {
          final control = await tester.runAsync(
            fixture.readImageWithDefaultRedirects,
          );
          expect(control, testImageBytes);
          expect(fixture.foreignRequests.single.path, '/redirected-image');
        }
        final beforeImages = fixture.imageRequests.length;
        final beforeForeign = fixture.foreignRequests.length;
        await _openShare(tester, env, '/recipes/$sharedRecipeId');
        await tester.runAsync(
          () => fixture.withRealHttp(() async {
            await tester.tap(find.byKey(const ValueKey('recipe-share-button')));
          }),
        );
        // Real sockets need real event-loop time; pumping a fake clock alone
        // cannot finish this request. Stop only on its visible UI/panel result.
        for (var i = 0; i < 300; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 20));
          if (redirect
              ? find.byType(SnackBar).evaluate().isNotEmpty
              : env.sharing.texts.isNotEmpty) {
            break;
          }
        }
        expect(fixture.imageRequests, hasLength(beforeImages + 1));
        final request = fixture.imageRequests.last;
        expect(request.method, 'GET');
        expect(request.path, '/s/$publicShareId/image');
        expect(
          request.headers['host'],
          Uri.parse(fixture.apiBaseUrl).authority,
        );
        for (final name in [
          'authorization',
          'x-device-id',
          'x-request-signature',
        ]) {
          expect(request.headers[name], isNull, reason: name);
        }
        // This same sink serves both the snapshot's untrusted image URL and
        // the API's cross-origin Location. Neither may receive an App request.
        expect(fixture.foreignRequests, hasLength(beforeForeign));
        if (redirect) {
          expect(find.byType(SnackBar), findsOneWidget);
          expect(env.sharing.texts, isEmpty);
          expect(env.sharing.images, isEmpty);
        } else {
          expect(env.sharing.texts, [publicShareUrl]);
          expect(env.sharing.images.single, testImageBytes);
          expect(env.sharing.contentTypes.single, 'image/png');
        }
        expect(tester.takeException(), isNull);
      },
      skip: kIsWeb,
    );
  }

  testWidgets(
    'a second opaque link replaces the first resolved or unavailable target',
    (tester) async {
      final env = SharingTestEnv(signedIn: false);
      await _openShare(tester, env, '/s/$publicShareId');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      container.read(routerProvider).go('/s/not-found');
      await tester.pumpAndSettle();
      expect(find.text('菜谱不存在或已下架'), findsOneWidget);
      expect(find.text('完整菜谱需要登录后查看'), findsNothing);
      container.read(routerProvider).go('/s/$publicShareId');
      await tester.pumpAndSettle();
      expect(find.text('完整菜谱需要登录后查看'), findsOneWidget);
      expect(find.text('菜谱不存在或已下架'), findsNothing);
    },
  );
}
