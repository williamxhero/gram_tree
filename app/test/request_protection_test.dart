import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/router.dart';

import 'helpers.dart';
import 'sharing_support.dart';

Future<void> openProtectedRecipe(
  WidgetTester tester,
  SharingTestEnv env,
) async {
  await pumpApp(tester, env: env);
  final container = ProviderScope.containerOf(
    tester.element(find.byType(Scaffold).first),
  );
  container.read(routerProvider).go('/recipes/$sharedRecipeId');
}

Future<void> pumpUntilVisible(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 80 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
}

void main() {
  testWidgets(
    'clock replay can refresh expired tokens without a second clock or auth retry',
    (tester) async {
      final env = SharingTestEnv();
      var calls = 0;
      env.server.on('GET', '/v1/recipes/$sharedRecipeId', (_) {
        calls++;
        if (calls == 1) {
          return (
            401,
            {
              'error': {
                'code': 'signature_clock_skew',
                'server_time': '2028-01-02T03:04:05Z',
              },
            },
          );
        }
        if (calls == 2) {
          return FakeServer.error(401, 'token_expired', 'expired');
        }
        return (200, sharedDetail().toJson());
      });
      await openProtectedRecipe(tester, env);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recipe-share-button')), findsOneWidget);
      expect(calls, 3);
      expect(env.server.calls('POST', '/v1/auth/refresh'), hasLength(1));
    },
  );

  testWidgets(
    'captcha challenge read can rotate tokens before verification and replay',
    (tester) async {
      final env = SharingTestEnv();
      var recipeCalls = 0;
      var challengeCalls = 0;
      env.server.responseHeaders['GET /v1/recipes/$sharedRecipeId'] = {
        'x-risk-challenge': ['challenge-123'],
      };
      env.server.on(
        'GET',
        '/v1/recipes/$sharedRecipeId',
        (_) => ++recipeCalls == 1
            ? FakeServer.error(403, 'risk_captcha_required', '需要安全验证')
            : (200, sharedDetail().toJson()),
      );
      env.server.on(
        'GET',
        '/v1/risk/captcha/challenge-123',
        (_) => ++challengeCalls == 1
            ? FakeServer.error(401, 'token_expired', 'expired')
            : (
                200,
                {
                  'challenge_id': 'challenge-123',
                  'prompt': '输入图中的字符',
                  'image_data_uri': 'data:image/png;base64,$testPngBase64',
                },
              ),
      );
      env.server.on(
        'POST',
        '/v1/risk/captcha',
        (_) => (200, {'accepted': true, 'access_restored': true}),
      );
      await openProtectedRecipe(tester, env);
      await pumpUntilVisible(tester, find.text('安全验证'));
      await tester.enterText(
        find.byKey(const ValueKey('captcha-response')),
        'verified',
      );
      await tester.tap(find.text('验证并继续'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recipe-share-button')), findsOneWidget);
      expect(recipeCalls, 2);
      expect(challengeCalls, 2);
      expect(env.server.calls('POST', '/v1/auth/refresh'), hasLength(1));
      expect(env.server.calls('POST', '/v1/risk/captcha'), hasLength(1));
    },
  );

  testWidgets(
    'cancelled captcha shows original failure and sends no verification or replay',
    (tester) async {
      final env = SharingTestEnv();
      env.server.responseHeaders['GET /v1/recipes/$sharedRecipeId'] = {
        'x-risk-challenge': ['challenge-123'],
      };
      env.server.on(
        'GET',
        '/v1/recipes/$sharedRecipeId',
        (_) => FakeServer.error(403, 'risk_captcha_required', '需要安全验证'),
      );
      await openProtectedRecipe(tester, env);
      await pumpUntilVisible(tester, find.text('安全验证'));
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(find.text('安全验证'), findsNothing);
      expect(env.server.calls('POST', '/v1/risk/captcha'), isEmpty);
      expect(
        env.server.calls('GET', '/v1/recipes/$sharedRecipeId'),
        hasLength(1),
      );
      expect(find.byKey(const ValueKey('recipe-share-button')), findsNothing);
    },
  );

  for (final receipt in [
    (accepted: false, restored: true),
    (accepted: true, restored: false),
    (accepted: false, restored: false),
  ]) {
    testWidgets('unsuccessful captcha receipt never replays: $receipt', (
      tester,
    ) async {
      final env = SharingTestEnv();
      env.server.responseHeaders['GET /v1/recipes/$sharedRecipeId'] = {
        'x-risk-challenge': ['challenge-123'],
      };
      env.server.on(
        'GET',
        '/v1/recipes/$sharedRecipeId',
        (_) => FakeServer.error(403, 'risk_captcha_required', '需要安全验证'),
      );
      env.server.on(
        'POST',
        '/v1/risk/captcha',
        (_) => (
          200,
          {'accepted': receipt.accepted, 'access_restored': receipt.restored},
        ),
      );
      await openProtectedRecipe(tester, env);
      await pumpUntilVisible(tester, find.text('安全验证'));
      await tester.enterText(
        find.byKey(const ValueKey('captcha-response')),
        'verified',
      );
      await tester.tap(find.text('验证并继续'));
      await tester.pumpAndSettle();
      expect(find.text('安全验证'), findsNothing);
      expect(env.server.calls('POST', '/v1/risk/captcha'), hasLength(1));
      expect(
        env.server.calls('GET', '/v1/recipes/$sharedRecipeId'),
        hasLength(1),
      );
      expect(find.byKey(const ValueKey('recipe-share-button')), findsNothing);
    });
  }

  for (final repeated in [false, true]) {
    testWidgets('clock correction retries once, repeated=$repeated', (
      tester,
    ) async {
      final env = SharingTestEnv();
      var count = 0;
      env.server.on('GET', '/v1/recipes/$sharedRecipeId', (_) {
        count++;
        if (count == 1 || repeated) {
          return (
            401,
            {
              'error': {
                'code': 'signature_clock_skew',
                'message': '设备时间不准确',
                'server_time': '2028-01-02T03:04:05Z',
              },
            },
          );
        }
        return (200, sharedDetail().toJson());
      });
      await openProtectedRecipe(tester, env);
      await tester.pumpAndSettle();
      expect(count, 2);
      final requests = env.server
          .calls('GET', '/v1/recipes/$sharedRecipeId')
          .toList();
      expect(
        requests[0].headers['X-Request-Nonce'],
        isNot(requests[1].headers['X-Request-Nonce']),
      );
      expect(
        int.parse(requests[1].headers['X-Request-Timestamp'] as String),
        closeTo(
          DateTime.utc(2028, 1, 2, 3, 4, 5).millisecondsSinceEpoch ~/ 1000,
          2,
        ),
      );
      expect(
        find.byKey(const ValueKey('recipe-share-button')),
        repeated ? findsNothing : findsOneWidget,
      );
    });
  }

  testWidgets('token refresh re-signs original request with rotated key', (
    tester,
  ) async {
    final env = SharingTestEnv();
    var count = 0;
    env.server.on(
      'GET',
      '/v1/recipes/$sharedRecipeId',
      (_) => ++count == 1
          ? FakeServer.error(401, 'token_expired', '登录已过期')
          : (200, sharedDetail().toJson()),
    );
    await openProtectedRecipe(tester, env);
    await tester.pumpAndSettle();
    final requests = env.server
        .calls('GET', '/v1/recipes/$sharedRecipeId')
        .toList();
    expect(requests, hasLength(2));
    expect(requests.first.headers['Authorization'], 'Bearer access-0');
    expect(requests.last.headers['Authorization'], 'Bearer access-1');
    expect(
      requests.last.headers['X-Request-Signature'],
      matches(RegExp(r'^[a-f0-9]{64}$')),
    );
    expect(
      requests.first.headers['X-Request-Nonce'],
      isNot(requests.last.headers['X-Request-Nonce']),
    );
    expect(find.byKey(const ValueKey('recipe-share-button')), findsOneWidget);
  });

  for (final repeated in [false, true]) {
    testWidgets(
      'captcha dialog completes and original retry is bounded, repeated=$repeated',
      (tester) async {
        final env = SharingTestEnv();
        var count = 0;
        env.server.responseHeaders['GET /v1/recipes/$sharedRecipeId'] = {
          'x-risk-challenge': ['challenge-123'],
        };
        env.server.on(
          'GET',
          '/v1/recipes/$sharedRecipeId',
          (_) => ++count == 1 || repeated
              ? FakeServer.error(403, 'risk_captcha_required', '需要安全验证')
              : (200, sharedDetail().toJson()),
        );
        env.server.on('POST', '/v1/risk/captcha', (r) {
          expect(r.body, {
            'challenge_id': 'challenge-123',
            'response': 'verified',
          });
          return (200, {'accepted': true, 'access_restored': true});
        });
        await openProtectedRecipe(tester, env);
        await pumpUntilVisible(tester, find.text('安全验证'));
        expect(find.text('输入图中的字符'), findsOneWidget);
        expect(find.byKey(const ValueKey('captcha-image')), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('captcha-response')),
          'verified',
        );
        await tester.tap(find.text('验证并继续'));
        await tester.pumpAndSettle();
        expect(count, 2);
        expect(env.server.calls('POST', '/v1/risk/captcha'), hasLength(1));
        expect(find.text('安全验证'), findsNothing);
        expect(
          find.byKey(const ValueKey('recipe-share-button')),
          repeated ? findsNothing : findsOneWidget,
        );
      },
    );
  }

  testWidgets(
    'rate limit countdown is visible, expires, and never auto-replays',
    (tester) async {
      final env = SharingTestEnv();
      env.server.responseHeaders['GET /v1/recipes/$sharedRecipeId'] = {
        'retry-after': ['3'],
      };
      env.server.on(
        'GET',
        '/v1/recipes/$sharedRecipeId',
        (_) => FakeServer.error(429, 'rate_limited', '操作太频繁，请稍后再试'),
      );
      await openProtectedRecipe(tester, env);
      await pumpUntilVisible(
        tester,
        find.byKey(const ValueKey('access-retry-countdown')),
      );
      expect(find.textContaining('秒后可重试'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(
        find.byKey(const ValueKey('access-retry-countdown')),
        findsNothing,
      );
      expect(
        env.server.calls('GET', '/v1/recipes/$sharedRecipeId'),
        hasLength(1),
      );
    },
  );
}
