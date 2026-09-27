import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/app/app.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/event_recorder.dart';
import 'package:gram_tree/events/fake_event_queue.dart';
import 'package:gram_tree/features_flags/features.dart';
import 'package:gram_tree/platform/app_exit.dart';
import 'package:gram_tree/platform/apple_sign_in.dart';
import 'package:gram_tree/platform/device_capabilities.dart';
import 'package:gram_tree/platform/fake_device_capabilities.dart';
import 'package:gram_tree/platform/link_opener.dart';
import 'package:gram_tree/platform/permissions.dart';
import 'package:gram_tree/platform/timezone_source.dart';
import 'package:gram_tree/privacy/policy.dart';
import 'package:gram_tree/storage/local_store.dart';
import 'package:gram_tree/storage/secure_store.dart';

/// 页面测试共用的启动和操作方法。
///
/// 页面测试不启动服务端：[FakeServer] 代替网络层，按生成的接口模型返回假数据，
/// 并记录 App 发出的每个请求。

const tabLabels = ['今天', '发现', '新建', '记录', '我的'];

/// Title shown by each tab's empty state, in bottom-bar order.
/// 我的 页显示的是昵称。
const emptyTitles = ['今天还没有安排', '还没有可发现的内容', '想做点什么？', '还没有做菜记录', '味友0001'];

const testEmail = 'cook@example.com';
const goodCode = '123456';

UserOut testUser({String nickname = '味友0001', String tz = 'Asia/Shanghai'}) =>
    UserOut(
      id: '0b9c6d4e-8f2a-4c3b-9d1e-2f3a4b5c6d7e',
      nickname: nickname,
      timezone: tz,
      status: UserOutStatusEnum.active,
      phone: null,
      realNameStatus: UserOutRealNameStatusEnum.none,
      createdAt: '2026-09-27T00:00:00+00:00',
    );

/// 记录的一次请求。
class Recorded {
  Recorded(this.method, this.path, this.body, this.headers);

  final String method;
  final String path;
  final Object? body;
  final Map<String, dynamic> headers;

  @override
  String toString() => '$method $path';
}

/// 一个很小的假服务端：常用接口有默认行为，测试可以用 [on] 覆盖。
///
/// 它是 Dio 拦截链的最后一环，直接给出响应，不经过网络层：网页上 Dio 的网络层要等真实的浏览器事件，
/// 页面测试的假时钟里等不到。
class FakeServer extends Interceptor {
  FakeServer() {
    _defaults();
  }

  final requests = <Recorded>[];
  final _routes = <String, FutureOr<(int, Object?)> Function(Recorded)>{};

  UserOut user = testUser();
  List<IdentityOut> identities = [
    IdentityOut(
      kind: IdentityOutKindEnum.email,
      email: testEmail,
      createdAt: '2026-09-27T00:00:00+00:00',
    ),
  ];
  int tokenSerial = 0;
  bool reauthed = false;

  void on(
    String method,
    String path,
    FutureOr<(int, Object?)> Function(Recorded) handler,
  ) => _routes['$method $path'] = handler;

  Iterable<Recorded> calls(String method, String path) =>
      requests.where((r) => r.method == method && r.path == path);

  static (int, Object?) error(int status, String code, String message) => (
    status,
    {
      'error': {
        'code': code,
        'message': message,
        'detail': null,
        'request_id': 'r',
      },
    },
  );

  Map<String, dynamic> tokens() {
    tokenSerial++;
    return TokenPair(
      accessToken: 'access-$tokenSerial',
      accessExpiresIn: 1800,
      refreshToken: 'refresh-$tokenSerial',
      user: user,
    ).toJson();
  }

  void _defaults() {
    on(
      'GET',
      '/v1/client-config',
      (_) => (200, {'features': {}, 'params': {}}),
    );
    on(
      'POST',
      '/v1/auth/email/code',
      (_) => (200, {'resend_after_seconds': 60, 'expires_in_seconds': 600}),
    );
    on('POST', '/v1/auth/email/login', (r) {
      final body = r.body as Map;
      if (body['code'] != goodCode) {
        return error(400, 'code_invalid', '验证码不对，还可以再试 4 次');
      }
      return (200, tokens());
    });
    on('POST', '/v1/auth/refresh', (_) => (200, tokens()));
    on('POST', '/v1/auth/logout', (_) => (204, null));
    on('POST', '/v1/auth/reauth/email', (r) {
      if ((r.body as Map)['code'] != goodCode) {
        return error(400, 'code_invalid', '验证码不对');
      }
      reauthed = true;
      return (204, null);
    });
    on('GET', '/v1/me', (_) => (200, user.toJson()));
    on('PATCH', '/v1/me', (r) {
      final body = r.body as Map;
      final name = body['nickname'] as String?;
      if (name != null && name.length > 20) {
        return error(422, 'invalid_nickname', '昵称最多 20 个字');
      }
      user = user.copyWith(
        nickname: name ?? user.nickname,
        timezone: body['timezone'] as String? ?? user.timezone,
      );
      return (200, user.toJson());
    });
    on(
      'GET',
      '/v1/me/identities',
      (_) => (200, [for (final i in identities) i.toJson()]),
    );
    on('POST', '/v1/me/identities/email', (r) {
      final body = r.body as Map;
      if (body['email'] == 'taken@example.com') {
        return error(409, 'identity_taken', '这个登录方式已经属于另一个味谱账号，不能绑定');
      }
      identities = [
        ...identities,
        IdentityOut(
          kind: IdentityOutKindEnum.email,
          email: body['email'] as String,
          createdAt: '2026-09-27T00:00:00+00:00',
        ),
      ];
      return (200, [for (final i in identities) i.toJson()]);
    });
    on('POST', '/v1/me/identities/apple', (_) {
      identities = [
        ...identities,
        IdentityOut(
          kind: IdentityOutKindEnum.apple,
          email: null,
          createdAt: '2026-09-27T00:00:00+00:00',
        ),
      ];
      return (200, [for (final i in identities) i.toJson()]);
    });
    on('POST', '/v1/me/consents', (_) => (204, null));
    on('POST', '/v1/events/upload', (r) {
      final events = ((r.body as Map)['events'] as List).cast<Map>();
      return (
        200,
        {
          'results': [
            for (final e in events) {'id': e['id'], 'status': 'accepted'},
          ],
        },
      );
    });
    on('POST', '/v1/me/deletion', (_) {
      if (!reauthed) return error(403, 'reauth_required', '为了安全，请先重新验证身份');
      return (
        202,
        {'status': 'deleting', 'deletion_due_at': '2026-10-20T00:00:00+00:00'},
      );
    });
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final sent = options.data;
    final Object? body = sent == null
        ? null
        : jsonDecode(sent is String ? sent : jsonEncode(sent));
    final rec = Recorded(
      options.method,
      options.uri.path,
      body,
      Map.of(options.headers),
    );
    requests.add(rec);
    final handle = _routes['${options.method} ${options.uri.path}'];
    final (status, data) = handle == null
        ? error(404, 'not_found', '没有找到')
        : await handle(rec);
    // 和真的网络响应一样，数据是解析好的 JSON
    final response = Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: data == null ? null : jsonDecode(jsonEncode(data)),
    );
    if (status >= 200 && status < 300) {
      handler.resolve(response, true);
    } else {
      handler.reject(
        DioException.badResponse(
          statusCode: status,
          requestOptions: options,
          response: response,
        ),
        true,
      );
    }
  }
}

class FakeAppExit implements AppExit {
  FakeAppExit({this.canExit = true});

  final bool canExit;
  int calls = 0;

  @override
  Future<bool> exit() async {
    calls++;
    return canExit;
  }
}

class FakeLinkOpener implements LinkOpener {
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }
}

class FakeAppleSignIn implements AppleSignIn {
  FakeAppleSignIn({this.isAvailable = false});

  @override
  final bool isAvailable;
  int calls = 0;

  @override
  Future<AppleCredential> signIn() async {
    calls++;
    return const AppleCredential(
      identityToken: 'apple-token',
      authorizationCode: 'code',
    );
  }
}

class FakeTimezone implements TimezoneSource {
  FakeTimezone(this.tz);

  final String? tz;

  @override
  Future<String?> current() async => tz;
}

class FakePermissions implements PermissionService {
  FakePermissions({
    this.initial = PermissionState.denied,
    this.answer = PermissionState.granted,
  });

  PermissionState initial;
  PermissionState answer;
  final requested = <AppPermission>[];
  int settingsOpened = 0;

  @override
  Future<PermissionState> status(AppPermission permission) async => initial;

  @override
  Future<PermissionState> request(AppPermission permission) async {
    requested.add(permission);
    initial = answer;
    return answer;
  }

  @override
  Future<void> openSystemSettings() async => settingsOpened++;
}

/// 已同意当前版本的本机记录。
Map<String, String> consentedStore({String privacy = privacyVersion}) => {
  'consent_records': jsonEncode([
    for (final (kind, version) in [
      ('terms', termsVersion),
      ('privacy', privacy),
    ])
      {
        'id': '00000000-0000-4000-8000-00000000000${kind == 'terms' ? 1 : 2}',
        'kind': kind,
        'version': version,
        'agree': true,
        'occurred_at': '2026-09-27T00:00:00.000Z',
        'device_id': 'device-test',
        'uploaded': true,
      },
  ]),
  'device_id': 'device-test',
};

Map<String, String> signedInSecure(UserOut user) => {
  sessionStorageKey: jsonEncode(
    AuthSession(
      accessToken: 'access-0',
      refreshToken: 'refresh-0',
      user: user,
    ).toJson(),
  ),
};

/// 一次测试用到的替身，测试里可以检查它们记录了什么。
class TestEnv {
  TestEnv({
    FakeServer? server,
    MemoryLocalStore? local,
    MemorySecureStore? secure,
    FakeAppExit? exit,
    FakeAppleSignIn? apple,
    FakePermissions? permissions,
    FakeEventQueue? eventQueue,
    this.timezone = 'Asia/Shanghai',
    this.features = const {},
  }) : server = server ?? FakeServer(),
       local = local ?? MemoryLocalStore(),
       secure = secure ?? MemorySecureStore(),
       exit = exit ?? FakeAppExit(),
       apple = apple ?? FakeAppleSignIn(),
       permissions = permissions ?? FakePermissions(),
       eventQueue = eventQueue ?? FakeEventQueue();

  /// 已同意、已登录。
  factory TestEnv.signedIn({
    FakeServer? server,
    Map<String, bool> features = const {},
  }) {
    final s = server ?? FakeServer();
    return TestEnv(
      server: s,
      local: MemoryLocalStore(consentedStore()),
      secure: MemorySecureStore(signedInSecure(s.user)),
      features: features,
    );
  }

  final FakeServer server;
  final MemoryLocalStore local;
  final MemorySecureStore secure;
  final FakeAppExit exit;
  final FakeAppleSignIn apple;
  final FakePermissions permissions;
  final FakeEventQueue eventQueue;
  final links = FakeLinkOpener();
  final String? timezone;
  final Map<String, bool> features;

  List<Override> get overrides => [
    localStoreProvider.overrideWithValue(local),
    secureStoreProvider.overrideWithValue(secure),
    fakeServerProvider.overrideWithValue(server),
    deviceCapabilitiesProvider.overrideWithValue(FakeDeviceCapabilities()),
    appExitProvider.overrideWithValue(exit),
    appleSignInProvider.overrideWithValue(apple),
    linkOpenerProvider.overrideWithValue(links),
    timezoneSourceProvider.overrideWithValue(FakeTimezone(timezone)),
    permissionServiceProvider.overrideWithValue(permissions),
    eventQueueProvider.overrideWithValue(eventQueue),
    appVersionProvider.overrideWith((ref) async => '0.1.0-test'),
    if (features.isNotEmpty)
      clientConfigProvider.overrideWith(
        (ref) async => ClientConfig(features: features, params: const {}),
      ),
  ];
}

Future<void> _setView(
  WidgetTester tester, {
  required Brightness brightness,
  required double textScale,
  required Size size,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

/// 启动 App。默认已同意隐私政策、已登录，直接看到主界面。
Future<TestEnv> pumpApp(
  WidgetTester tester, {
  TestEnv? env,
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  Size size = const Size(360, 780),
  Map<String, bool> features = const {},
}) async {
  final e = env ?? TestEnv.signedIn(features: features);
  await _setView(
    tester,
    brightness: brightness,
    textScale: textScale,
    size: size,
  );
  await tester.pumpWidget(
    ProviderScope(overrides: e.overrides, child: const GramTreeApp()),
  );
  await tester.pumpAndSettle();
  return e;
}

/// 模拟杀掉进程重新打开：本机存储保留，内存里的状态全部重建。
Future<void> restartApp(WidgetTester tester, TestEnv env) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    ProviderScope(overrides: env.overrides, child: const GramTreeApp()),
  );
  await tester.pumpAndSettle();
}

/// Taps the bottom-bar entry at [index]. The center one is the ＋ button.
Future<void> tapTab(WidgetTester tester, int index) async {
  final finder = index == 2
      ? find.byKey(const ValueKey('primary-create-button'))
      : find.text(tabLabels[index]);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// 在 [finder] 可见后点它（长页面里先滚动到它）。
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// 点顶栏的返回（下面一层页面的返回按钮也在树里，取最上面的）。
Future<void> goBack(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).last);
  await tester.pumpAndSettle();
}
