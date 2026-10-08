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
import 'package:gram_tree/ingredients/ingredient_api_client.dart';
import 'package:gram_tree/ingredients/ingredient_provider.dart';
import 'package:gram_tree/ingredients/ingredient_repository.dart';
import 'package:gram_tree/observability/crash_reporting.dart';
import 'package:gram_tree/network/reachability.dart';
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
import 'package:gram_tree/ui_protocol/composition_cache.dart';
import 'package:gram_tree/ui_protocol/page_types.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
    on(
      'GET',
      '/v1/me/taste-profile/allergies',
      (_) => (
        200,
        AllergiesOut(
          consentId: null,
          consentVersion: 'allergies-v1',
          authorizationVersion: 0,
          profileVersion: 1,
          availableCategories: const [
            '含麸质的谷物',
            '甲壳纲类动物',
            '鱼类',
            '蛋类',
            '花生',
            '大豆',
            '乳及乳制品',
            '坚果及其果仁',
          ],
          categories: const [],
          ingredients: const [],
        ).toJson(),
      ),
    );
    on(
      'GET',
      '/v1/me/taste-profile/allergies/changes',
      (_) => (200, PageTasteProfileChangeOut(items: const []).toJson()),
    );
    final personalMeasures = <Map<String, dynamic>>[];
    on(
      'GET',
      '/v1/me/measures',
      (_) => (200, {'items': personalMeasures, 'next_cursor': null}),
    );
    on('POST', '/v1/me/measures', (r) {
      final body = Map<String, dynamic>.from(r.body as Map);
      final value = {
        ...body,
        'id': '66666666-6666-4666-8666-666666666666',
        'created_at': '2026-10-02T00:00:00Z',
        'updated_at': '2026-10-02T00:00:00Z',
      };
      personalMeasures.add(value);
      return (201, value);
    });
    on('PATCH', '/v1/me/measures/66666666-6666-4666-8666-666666666666', (r) {
      final body = Map<String, dynamic>.from(r.body as Map);
      final current = personalMeasures.firstWhere(
        (item) => item['id'] == '66666666-6666-4666-8666-666666666666',
        orElse: () => {
          'id': '66666666-6666-4666-8666-666666666666',
          'name': '白瓷勺',
          'kind': 'spoon',
          'capacity_ml': 15,
          'created_at': '2026-10-02T00:00:00Z',
          'updated_at': '2026-10-02T00:00:00Z',
        },
      );
      current.addAll(body);
      if (!personalMeasures.contains(current)) personalMeasures.add(current);
      return (200, current);
    });
    on('DELETE', '/v1/me/measures/66666666-6666-4666-8666-666666666666', (_) {
      personalMeasures.removeWhere(
        (item) => item['id'] == '66666666-6666-4666-8666-666666666666',
      );
      return (204, null);
    });
    on('GET', '/v1/me/measures/66666666-6666-4666-8666-666666666666', (_) {
      final item = personalMeasures.firstOrNull;
      return item == null
          ? FakeServer.error(404, 'not_found', '没有找到')
          : (200, item);
    });
    on('POST', '/v1/analytics/events', (_) => (204, null));
    on('POST', '/v1/sync/writes', (r) {
      final batch = WriteBatch.fromJson(
        Map<String, dynamic>.from(r.body as Map),
      );
      return (
        200,
        WriteBatchResponse(
          results: [
            for (final write in batch.writes)
              WriteResult(
                writeId: write.writeId,
                status: WriteResultStatusEnum.confirmed,
                result: WriteResourceResult(
                  resourceType: 'experience.event',
                  resourceId: write.writeId,
                ),
              ),
          ],
        ).toJson(),
      );
    });
    on('POST', '/v1/ui/compositions', (r) {
      final body = r.body as Map;
      if (body['page_type'] != 'today') {
        return error(404, 'unknown_page_type', '没有这个页面类型');
      }
      final supported = ((body['supported_components'] as List?) ?? const [])
          .cast<String>()
          .toSet();
      final all = [
        {
          'type': 'hint_bar',
          'id': 'c1',
          'detail': 'brief',
          'data': {'conclusion': '先添加一道你常做的菜'},
          'actions': [
            {
              'intent': 'open_page',
              'params': {'page': 'create'},
            },
          ],
          'reason': {'code': 'default', 'text': '默认组合'},
          'required': false,
        },
        {
          'type': 'empty_state',
          'id': 'c2',
          'detail': 'standard',
          'data': {
            'conclusion': '今天还没有安排',
            'basis': {'text': '这里会显示今天要做的菜'},
            'action_label': '添加第一道菜谱',
          },
          'actions': [
            {
              'intent': 'open_page',
              'params': {'page': 'create'},
            },
          ],
          'reason': {'code': 'default', 'text': '默认组合'},
          'required': false,
        },
      ];
      return (
        200,
        {
          'protocol': '1.0',
          'page_type': 'today',
          'composition_id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
          'generated_at': '2026-09-28T10:30:00Z',
          'cache': {
            'depends_on': {'plan': 'v0'},
            'ttl_s': 600,
          },
          'experiment': null,
          'components': [
            for (final c in all)
              if (supported.contains(c['type'])) c,
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

/// 拒收原因、积压告警走的轻量上报通道（SPEC-010.1 票 5），测试里换成这个，
/// 记录报了什么消息，不真的碰 Sentry。
class FakeEventReportBackend implements EventReportBackend {
  final reports = <String>[];

  @override
  void report(String message, {required SentryLevel level}) {
    reports.add(message);
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

class TestReachabilityProbe implements ApiReachabilityProbe {
  TestReachabilityProbe(this.reachable);
  bool reachable;
  @override
  Future<bool> check() async => reachable;
  @override
  void dispose() {}
}

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
    FakeEventReportBackend? eventReports,
    this.timezone = 'Asia/Shanghai',
    this.features = const {},
    this.params = const {},
    this.requiredComponentTypes,
    this.localDependencyVersions,
    this.offline = false,
    this.probe,
  }) : server = server ?? FakeServer(),
       local = local ?? MemoryLocalStore(),
       secure = secure ?? MemorySecureStore(),
       exit = exit ?? FakeAppExit(),
       apple = apple ?? FakeAppleSignIn(),
       permissions = permissions ?? FakePermissions(),
       eventQueue = eventQueue ?? FakeEventQueue(),
       eventReports = eventReports ?? FakeEventReportBackend();

  /// 已同意、已登录。
  factory TestEnv.signedIn({
    FakeServer? server,
    Map<String, bool> features = const {},
    Map<String, Object?> params = const {},
    Map<String, Set<String>>? requiredComponentTypes,
    Map<String, String>? localDependencyVersions,
    MemoryLocalStore? local,
    bool offline = false,
    ApiReachabilityProbe? probe,
  }) {
    final s = server ?? FakeServer();
    return TestEnv(
      server: s,
      local: local ?? MemoryLocalStore(consentedStore()),
      secure: MemorySecureStore(signedInSecure(s.user)),
      features: features,
      params: params,
      requiredComponentTypes: requiredComponentTypes,
      localDependencyVersions: localDependencyVersions,
      offline: offline,
      probe: probe,
    );
  }

  final ApiReachabilityProbe? probe;
  late final reachability = TestReachabilityProbe(!offline);
  final FakeServer server;
  final MemoryLocalStore local;
  final MemorySecureStore secure;
  final FakeAppExit exit;
  final FakeAppleSignIn apple;
  final FakePermissions permissions;
  final FakeEventQueue eventQueue;
  final FakeEventReportBackend eventReports;
  final links = FakeLinkOpener();
  final String? timezone;
  final Map<String, bool> features;

  /// 覆盖 `/v1/client-config` 的 `params`（例如
  /// `ui.composition_timeout_ms`），测试组合服务等待时限之类"App 按下发的值执行"
  /// 的行为时用（SPEC-009.1 #79）。
  final Map<String, Object?> params;

  /// 覆盖 `requiredComponentTypesProvider`，测试"缺必显组件时整页退回标准布局"这个
  /// 机制本身时用（SPEC-009.1 #79）；`null` 表示不覆盖，用 App 里登记的默认值
  /// （现在都是空集合）。
  final Map<String, Set<String>>? requiredComponentTypes;

  /// 覆盖 `localDependencyVersionsProvider`，测试"本机缓存的 depends_on 和这个值
  /// 一致才用缓存"这条机制时用（SPEC-009.1 票 7，#83）；`null` 表示不覆盖，用 App
  /// 里的默认值（空 Map，见该 provider 的文档）。
  final Map<String, String>? localDependencyVersions;

  /// 让每个请求从一开始就被 [offlineSimulationProvider] 拒绝成
  /// `DioException.connectionError`——测试"离线时使用本机缓存"（SPEC-009.1 票 7，
  /// #83）时用；默认 false（正常联网）。
  final bool offline;

  List<Override> get overrides => [
    localStoreProvider.overrideWithValue(local),
    secureStoreProvider.overrideWithValue(secure),
    fakeServerProvider.overrideWithValue(server),
    apiReachabilityProbeProvider.overrideWithValue(probe ?? reachability),
    // Page tests use the same cache interface with a fake-clock-safe store;
    // native drift persistence is exercised by installed integration tests.
    ingredientRepositoryProvider.overrideWith(
      (ref) => IngredientRepository(
        api: GeneratedIngredientSyncApi(
          ref.watch(apiClientProvider).getIngredientsApi(),
        ),
        cache: LocalStoreIngredientCache(local),
      ),
    ),
    deviceCapabilitiesProvider.overrideWithValue(FakeDeviceCapabilities()),
    appExitProvider.overrideWithValue(exit),
    appleSignInProvider.overrideWithValue(apple),
    linkOpenerProvider.overrideWithValue(links),
    timezoneSourceProvider.overrideWithValue(FakeTimezone(timezone)),
    permissionServiceProvider.overrideWithValue(permissions),
    eventQueueProvider.overrideWithValue(eventQueue),
    eventReportBackendProvider.overrideWithValue(eventReports),
    appVersionProvider.overrideWith((ref) async => '0.1.0-test'),
    if (offline) offlineSimulationProvider.overrideWith(_AlwaysOffline.new),
    if (features.isNotEmpty || params.isNotEmpty)
      clientConfigProvider.overrideWith(
        (ref) async => ClientConfig(features: features, params: params),
      ),
    if (requiredComponentTypes != null)
      requiredComponentTypesProvider.overrideWithValue(requiredComponentTypes!),
    if (localDependencyVersions != null)
      localDependencyVersionsProvider.overrideWithValue(
        localDependencyVersions!,
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
  bool settle = true,
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
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Keep the non-settling path bounded for browser page tests. The fake
    // interceptor completes synchronously; a few short frames flush the route
    // and provider updates without waiting on app-wide timers.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
  return e;
}

/// [TestEnv.offline] 用：请求从 `pumpApp` 第一次渲染开始就被拒绝，不用先联网成功
/// 一次再手动调用 `.set(true)`——这样"离线且本机有缓存"的测试可以直接控制
/// [TestEnv.local] 里预先存好什么，不用先走一遍真实成功的组合请求（那样会覆盖掉
/// 预先存的缓存，见 `composition_cache_test.dart`）。
class _AlwaysOffline extends OfflineSimulation {
  @override
  bool build() => true;
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
