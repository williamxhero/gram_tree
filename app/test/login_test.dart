import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/storage/local_store.dart';

import 'helpers.dart';

/// 邮箱验证码登录、保持登录、续期、Apple 登录、时区同步（SPEC-013.2 票 2、3、4、6）。

TestEnv consentedOnly({
  FakeServer? server,
  FakeAppleSignIn? apple,
  String? tz,
}) => TestEnv(
  server: server,
  apple: apple,
  local: MemoryLocalStore({
    ...consentedStore(),
    // 本机还有一条没上传的同意记录（登录前同意的）
  }),
  timezone: tz ?? 'Asia/Shanghai',
);

Future<void> enterEmail(WidgetTester tester, String email) async {
  await tester.enterText(find.byKey(const ValueKey('login-email')), email);
  await tapVisible(tester, find.text('发送验证码'));
}

Future<void> enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byKey(const ValueKey('code-input')), code);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('输邮箱 → 收码 → 输码 → 进入主界面，登录前的同意记录补传到账号', (tester) async {
    final env = TestEnv();
    await pumpApp(tester, env: env);
    await tapVisible(tester, find.byKey(const ValueKey('consent-agree')));

    await enterEmail(tester, testEmail);
    expect(find.text('输入验证码'), findsOneWidget);
    expect(find.text('已发到 $testEmail，10 分钟内有效。'), findsOneWidget);
    expect(find.text('60 秒后可以重新发送'), findsOneWidget);
    final sent = env.server.calls('POST', '/v1/auth/email/code').single;
    expect(sent.body, {'email': testEmail, 'purpose': 'login'});
    expect(sent.headers['X-Device-ID'], env.local.getString('device_id'));

    await enterCode(tester, goodCode);
    expect(find.text('今天还没有安排'), findsOneWidget);
    expect(env.secure.values[sessionStorageKey], contains('access-1'));

    final upload = env.server.calls('POST', '/v1/me/consents').single;
    expect(upload.headers['Authorization'], 'Bearer access-1');
    expect((upload.body as Map)['records'], hasLength(2));
  });

  testWidgets('验证码错误时显示服务端的提示，可以重输', (tester) async {
    final env = consentedOnly();
    await pumpApp(tester, env: env);
    await enterEmail(tester, testEmail);
    await enterCode(tester, '000000');
    expect(find.text('验证码不对，还可以再试 4 次'), findsOneWidget);
    await enterCode(tester, goodCode);
    expect(find.text('今天还没有安排'), findsOneWidget);
  });

  testWidgets('发送太频繁时提示', (tester) async {
    final server = FakeServer()
      ..on(
        'POST',
        '/v1/auth/email/code',
        (_) => FakeServer.error(
          429,
          'daily_limit_reached',
          '今天发送次数已达上限，请明天再试，或用其他方式登录',
        ),
      );
    await pumpApp(tester, env: consentedOnly(server: server));
    await enterEmail(tester, testEmail);
    expect(find.text('今天发送次数已达上限，请明天再试，或用其他方式登录'), findsOneWidget);
    expect(find.text('输入验证码'), findsNothing);
  });

  testWidgets('重新发送有倒计时，到时可以重发', (tester) async {
    final env = consentedOnly();
    await pumpApp(tester, env: env);
    await enterEmail(tester, testEmail);
    expect(find.text('重新发送'), findsNothing);
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('30 秒后可以重新发送'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    await tapVisible(tester, find.text('重新发送'));
    expect(env.server.calls('POST', '/v1/auth/email/code'), hasLength(2));
    expect(find.text('60 秒后可以重新发送'), findsOneWidget);
  });

  testWidgets('已登录的用户重新打开 App 直接进主界面', (tester) async {
    final env = consentedOnly();
    await pumpApp(tester, env: env);
    await enterEmail(tester, testEmail);
    await enterCode(tester, goodCode);

    await restartApp(tester, env);
    expect(find.text('登录味谱'), findsNothing);
    expect(find.text('今天还没有安排'), findsOneWidget);
  });

  testWidgets('访问令牌过期时自动续期并重试', (tester) async {
    final server = FakeServer();
    var expired = true;
    server.on('GET', '/v1/me/identities', (r) {
      if (expired && r.headers['Authorization'] == 'Bearer access-0') {
        return FakeServer.error(401, 'token_expired', '登录已过期');
      }
      expired = false;
      return (200, [for (final i in server.identities) i.toJson()]);
    });
    final env = await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await tapTab(tester, 4);
    expect(find.text(testEmail), findsOneWidget);
    final refresh = server.calls('POST', '/v1/auth/refresh').single;
    expect(refresh.body, {'refresh_token': 'refresh-0'});
    expect(env.secure.values[sessionStorageKey], contains('refresh-1'));
  });

  test('续期成功但重试仍失败时，请求带着错误返回，不会卡住后面的请求', () async {
    final server = FakeServer();
    var calls = 0;
    server.on('GET', '/v1/me/identities', (r) {
      calls++;
      if (calls == 1) return FakeServer.error(401, 'token_expired', '登录已过期');
      if (calls == 2) return FakeServer.error(500, 'internal_error', '服务器出错了');
      return (200, [for (final i in server.identities) i.toJson()]);
    });
    final container = ProviderContainer(
      overrides: TestEnv.signedIn(server: server).overrides,
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    final api = container.read(apiClientProvider).getAccountApi();

    await expectLater(
      api.listIdentities().timeout(const Duration(seconds: 5)),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          500,
        ),
      ),
    );
    expect(server.calls('POST', '/v1/auth/refresh'), hasLength(1));
    final next = await api.listIdentities().timeout(const Duration(seconds: 5));
    expect(next.data, hasLength(1));
  });

  testWidgets('续期暂时无法连接不退出账号，恢复联网后仍能续期', (tester) async {
    final server = FakeServer();
    server.on('GET', '/v1/me/identities', (r) {
      if (r.headers['Authorization'] == 'Bearer access-0') {
        return FakeServer.error(401, 'token_expired', '登录已过期');
      }
      return (200, [for (final i in server.identities) i.toJson()]);
    });
    final env = TestEnv.signedIn(server: server);
    server.on('POST', '/v1/auth/refresh', (_) {
      env.reachability.reachable = false;
      return FakeServer.error(503, 'temporarily_unavailable', '暂时无法连接');
    });
    await pumpApp(tester, env: env);
    await tapTab(tester, 4);
    expect(find.text('登录味谱'), findsNothing);
    expect(find.text('味友0001'), findsOneWidget);
    expect(env.secure.values[sessionStorageKey], contains('refresh-0'));
    await tester.pump(const Duration(seconds: 30));
    expect(server.calls('POST', '/v1/auth/refresh'), hasLength(1));

    env.reachability.reachable = true;
    server.on('POST', '/v1/auth/refresh', (_) => (200, server.tokens()));
    await restartApp(tester, env);
    await tapTab(tester, 4);
    expect(find.text(testEmail), findsOneWidget);
    expect(env.secure.values[sessionStorageKey], contains('refresh-1'));
    expect(find.text('登录味谱'), findsNothing);
  });

  testWidgets('续期失败就回到登录页', (tester) async {
    final server = FakeServer()
      ..on(
        'GET',
        '/v1/me/identities',
        (_) => FakeServer.error(401, 'token_expired', '登录已过期'),
      )
      ..on(
        'POST',
        '/v1/auth/refresh',
        (_) => FakeServer.error(401, 'refresh_invalid', '登录已失效，请重新登录'),
      );
    final env = await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await tapTab(tester, 4);
    expect(find.text('登录味谱'), findsOneWidget);
    expect(find.text('登录已失效，请重新登录'), findsOneWidget);
    expect(env.secure.values, isEmpty);
  });

  testWidgets('iPhone 上有 Apple 登录，点了进入主界面', (tester) async {
    final env = consentedOnly(apple: FakeAppleSignIn(isAvailable: true));
    env.server.on('POST', '/v1/auth/apple/login', (r) {
      expect((r.body as Map)['identity_token'], 'apple-token');
      return (200, env.server.tokens());
    });
    await pumpApp(tester, env: env);
    await tapVisible(tester, find.byKey(const ValueKey('apple-sign-in')));
    expect(env.apple.calls, 1);
    expect(find.text('今天还没有安排'), findsOneWidget);
  });

  testWidgets('安卓和网页没有 Apple 登录', (tester) async {
    await pumpApp(tester, env: consentedOnly());
    expect(find.text('通过 Apple 登录'), findsNothing);
  });

  testWidgets('登录后手机时区和账号不同时自动更新', (tester) async {
    final env = consentedOnly(tz: 'Europe/Berlin');
    await pumpApp(tester, env: env);
    await enterEmail(tester, testEmail);
    await enterCode(tester, goodCode);
    final patch = env.server.calls('PATCH', '/v1/me').single;
    expect(patch.body, {'timezone': 'Europe/Berlin'});
    expect(env.server.user.timezone, 'Europe/Berlin');
  });

  testWidgets('时区相同时不发请求', (tester) async {
    final env = TestEnv.signedIn();
    await pumpApp(tester, env: env);
    expect(env.server.calls('PATCH', '/v1/me'), isEmpty);
  });

  testWidgets('登录页在最大字号下不溢出', (tester) async {
    await pumpApp(
      tester,
      env: consentedOnly(apple: FakeAppleSignIn(isAvailable: true)),
      textScale: 3.0,
      size: const Size(320, 568),
    );
    expect(tester.takeException(), isNull);
    await enterEmail(tester, testEmail);
    expect(tester.takeException(), isNull);
  });
}
