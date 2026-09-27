import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/app.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/features_flags/features.dart';
import 'package:gram_tree/observability/crash_reporting.dart';
import 'package:gram_tree/platform/device_capabilities.dart';
import 'package:gram_tree/platform/fake_device_capabilities.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class FakeBackend implements CrashReporterBackend {
  int initCalls = 0;
  String? environment;

  @override
  Future<void> init({
    required String dsn,
    required String environment,
    required BeforeSendCallback beforeSend,
  }) async {
    initCalls++;
    this.environment = environment;
  }
}

Future<ProviderContainer> pumpWith(
  WidgetTester tester,
  FakeBackend backend, {
  String dsn = 'https://key@glitchtip.example/1',
  bool devOverride = false,
  AppEnv env = AppEnv.prod,
}) async {
  final container = ProviderContainer(
    overrides: [
      deviceCapabilitiesProvider.overrideWithValue(FakeDeviceCapabilities()),
      clientConfigProvider.overrideWith(
        (ref) async => ClientConfig(features: const {}, params: const {}),
      ),
      appConfigProvider.overrideWithValue(AppConfig.forEnv(env)),
      crashReporterBackendProvider.overrideWithValue(backend),
      crashReportingConfigProvider.overrideWithValue(
        CrashReportingConfig(dsn: dsn, devOverride: devOverride),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GramTreeApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('未同意隐私政策时，崩溃上报不初始化', (tester) async {
    final backend = FakeBackend();
    await pumpWith(tester, backend);
    expect(find.text('今天还没有安排'), findsOneWidget);
    expect(backend.initCalls, 0);
  });

  testWidgets('同意隐私政策后初始化一次，之后不重复', (tester) async {
    final backend = FakeBackend();
    final container = await pumpWith(tester, backend);
    container.read(privacyConsentProvider.notifier).set(true);
    await tester.pumpAndSettle();
    expect(backend.initCalls, 1);
    expect(backend.environment, 'prod');

    container.read(privacyConsentProvider.notifier).set(false);
    await tester.pumpAndSettle();
    container.read(privacyConsentProvider.notifier).set(true);
    await tester.pumpAndSettle();
    expect(backend.initCalls, 1);
  });

  testWidgets('开发构建可以手动打开', (tester) async {
    final backend = FakeBackend();
    await pumpWith(tester, backend, devOverride: true, env: AppEnv.dev);
    expect(backend.initCalls, 1);
  });

  testWidgets('正式构建里手动打开无效', (tester) async {
    final backend = FakeBackend();
    await pumpWith(tester, backend, devOverride: true, env: AppEnv.prod);
    expect(backend.initCalls, 0);
  });

  testWidgets('没配上报地址时，同意了也不初始化', (tester) async {
    final backend = FakeBackend();
    final container = await pumpWith(tester, backend, dsn: '');
    container.read(privacyConsentProvider.notifier).set(true);
    await tester.pumpAndSettle();
    expect(backend.initCalls, 0);
  });

  test('上报内容去掉菜谱、口味、健康信息和请求内容', () {
    final event = SentryEvent(
      // ignore: deprecated_member_use
      extra: {'recipe_title': '番茄炒蛋', 'screen': 'today'},
      tags: {'allergy': '花生', 'build': '42'},
      user: SentryUser(id: 'u1', email: 'a@b.c', username: 'yosef'),
      request: SentryRequest(
        url: 'https://api/v1/recipes',
        data: {'title': '秘方'},
      ),
      breadcrumbs: [
        Breadcrumb(
          message: '打开菜谱：番茄炒蛋',
          category: 'navigation',
          data: {'recipe': 'x'},
        ),
      ],
    )..contexts['taste_profile'] = {'spicy': 3};

    final scrubbed = scrubEvent(event);

    // ignore: deprecated_member_use
    expect(scrubbed.extra, {'screen': 'today'});
    expect(scrubbed.tags, {'build': '42'});
    expect(scrubbed.user?.id, 'u1');
    expect(scrubbed.user?.email, isNull);
    expect(scrubbed.user?.username, isNull);
    expect(scrubbed.request, isNull);
    expect(scrubbed.contexts.containsKey('taste_profile'), isFalse);
    expect(scrubbed.breadcrumbs!.single.category, 'navigation');
    expect(scrubbed.breadcrumbs!.single.message, isNull);
    expect(scrubbed.breadcrumbs!.single.data, anyOf(isNull, isEmpty));
  });
}
