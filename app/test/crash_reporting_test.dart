import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/app.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/observability/crash_reporting.dart';
import 'package:gram_tree/privacy/consent.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'helpers.dart';

class FakeBackend implements CrashReporterBackend {
  int initCalls = 0;
  int closeCalls = 0;
  String? environment;
  BeforeSendCallback? beforeSend;

  @override
  Future<void> close() async => closeCalls++;

  @override
  Future<void> init({
    required String dsn,
    required String environment,
    required BeforeSendCallback beforeSend,
  }) async {
    initCalls++;
    this.environment = environment;
    this.beforeSend = beforeSend;
  }
}

Future<ProviderContainer> pumpWith(
  WidgetTester tester,
  FakeBackend backend, {
  String dsn = 'https://key@glitchtip.example/1',
  bool devOverride = false,
  AppEnv env = AppEnv.prod,
  bool consented = false,
}) async {
  final testEnv = consented ? TestEnv.signedIn() : TestEnv();
  final container = ProviderContainer(
    overrides: [
      ...testEnv.overrides,
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
    expect(find.text('开始之前，先说清楚我们会用到什么'), findsOneWidget);
    expect(backend.initCalls, 0);
  });

  testWidgets('同意隐私政策后初始化，撤回同意后关闭', (tester) async {
    final backend = FakeBackend();
    final container = await pumpWith(tester, backend);
    await container.read(consentProvider.notifier).agree();
    await tester.pumpAndSettle();
    expect(backend.initCalls, 1);
    expect(backend.environment, 'prod');

    // 界面重建不会重复初始化
    await tester.pumpAndSettle();
    expect(backend.initCalls, 1);

    await container.read(consentProvider.notifier).withdraw();
    await tester.pumpAndSettle();
    expect(backend.closeCalls, 1);

    await container.read(consentProvider.notifier).agree();
    await tester.pumpAndSettle();
    expect(backend.initCalls, 2);
  });

  testWidgets('已同意过的用户重新打开 App 时直接初始化', (tester) async {
    final backend = FakeBackend();
    await pumpWith(tester, backend, consented: true);
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
    await container.read(consentProvider.notifier).agree();
    await tester.pumpAndSettle();
    expect(backend.initCalls, 0);
  });

  testWidgets(
    'SDK beforeSend never sends private exception or unknown nested payload',
    (tester) async {
      final backend = FakeBackend();
      await pumpWith(tester, backend, consented: true);
      final marker = 'private-${DateTime.now().microsecondsSinceEpoch}';
      final event = SentryEvent(
        message: SentryMessage(marker),
        throwable: StateError(marker),
        exceptions: [SentryException(type: 'StateError', value: marker)],
        // ignore: deprecated_member_use
        extra: {
          'unexpected': {'nested': marker},
          'screen': marker,
        },
        tags: {'unexpected': marker, 'build': marker},
        transaction: marker,
        culprit: marker,
        breadcrumbs: [
          Breadcrumb(
            category: marker,
            message: marker,
            data: {'unknown': marker},
          ),
        ],
      )..contexts['unknown_context'] = {'nested': marker};
      final sent = await backend.beforeSend!(event, Hint());
      expect(sent, isNotNull);
      expect(jsonEncode(sent!.toJson()), isNot(contains(marker)));
      expect(sent.exceptions!.single.type, 'StateError');
      expect(sent.exceptions!.single.value, isNull);
    },
  );

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
