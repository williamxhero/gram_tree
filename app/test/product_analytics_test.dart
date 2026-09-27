import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/app.dart';
import 'package:gram_tree/auth/auth_controller.dart';
import 'package:gram_tree/observability/product_analytics.dart';
import 'package:gram_tree/privacy/consent.dart';
import 'package:gram_tree/privacy/policy.dart';

import 'helpers.dart';

const _path = '/v1/analytics/events';

Future<ProviderContainer> pumpWith(WidgetTester tester, TestEnv testEnv) async {
  final container = ProviderContainer(overrides: testEnv.overrides);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GramTreeApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

/// 直接（不通过界面手势）触发一次网络调用时，widget 测试的假时钟不会自己走，
/// 要显式 pump 才能让 [FakeServer] 那一环的响应流转回来，否则 await 会一直卡住；
/// 多 pump 几次，覆盖请求经过多层拦截器（同意校验、设备头、鉴权续期排队）时
/// 需要多轮微任务才能走完的情况。
Future<void> fire(WidgetTester tester, Future<void> Function() call) async {
  final done = Completer<void>();
  unawaited(call().then(done.complete, onError: done.completeError));
  for (var i = 0; i < 50 && !done.isCompleted; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  if (!done.isCompleted) {
    throw StateError('fire() 等待网络调用完成超时，检查是不是漏了 pump');
  }
  return done.future;
}

void main() {
  testWidgets('同意隐私政策前不发埋点请求', (tester) async {
    final env = TestEnv(); // 未同意，未登录
    final container = await pumpWith(tester, env);
    expect(find.text('开始之前，先说清楚我们会用到什么'), findsOneWidget);

    final analytics = container.read(productAnalyticsProvider);
    expect(analytics.allowed, isFalse);
    await analytics.reportPageView('today');
    await analytics.reportTap('today.cook_button');
    await analytics.reportLoadDuration('today', 120);

    expect(env.server.calls('POST', _path), isEmpty);
  });

  testWidgets('同意后默认发送页面访问、入口点击、加载耗时', (tester) async {
    final env = TestEnv.signedIn();
    final container = await pumpWith(tester, env);

    final analytics = container.read(productAnalyticsProvider);
    expect(analytics.allowed, isTrue);
    await fire(tester, () => analytics.reportPageView('today'));
    await fire(tester, () => analytics.reportTap('today.cook_button'));
    await fire(tester, () => analytics.reportLoadDuration('today', 120));

    final calls = env.server.calls('POST', _path).toList();
    expect(calls, hasLength(3));
    final bodies = calls.map((c) => (c.body as Map)['events']).toList();
    expect((bodies[0] as List).single['event_type'], 'page_view');
    expect((bodies[0] as List).single['target'], 'today');
    expect((bodies[1] as List).single['event_type'], 'tap');
    expect((bodies[1] as List).single['target'], 'today.cook_button');
    expect((bodies[2] as List).single['event_type'], 'load_duration');
    expect((bodies[2] as List).single['duration_ms'], 120);
    // 只允许登记好的字段：不含用户 ID、菜谱内容等
    final firstEvent = (bodies[0] as List).single as Map;
    expect(
      firstEvent.keys,
      containsAll(['id', 'event_type', 'target', 'occurred_at']),
    );
    expect(firstEvent.containsKey('user_id'), isFalse);
  });

  testWidgets('关闭“产品改进统计”后不再发送，同意记录里有这次关闭', (tester) async {
    final env = TestEnv.signedIn();
    final container = await pumpWith(tester, env);

    // 默认开启
    expect(container.read(consentProvider).productAnalyticsEnabled, isTrue);

    final entry = await container
        .read(consentProvider.notifier)
        .setProductAnalytics(false);
    expect(entry.kind, ConsentKind.productAnalytics);
    expect(entry.agree, isFalse);
    expect(container.read(consentProvider).productAnalyticsEnabled, isFalse);
    // 设置页开关变化后会立刻尝试上传这条同意记录（AuthController.uploadConsentRecords）
    await fire(
      tester,
      () => container.read(authProvider.notifier).uploadConsentRecords([entry]),
    );

    final analytics = container.read(productAnalyticsProvider);
    expect(analytics.allowed, isFalse);
    await analytics.reportPageView('today');
    expect(env.server.calls('POST', _path), isEmpty);

    // 关闭这个动作本身作为同意记录留了下来
    final consentCalls = env.server.calls('POST', '/v1/me/consents').toList();
    expect(consentCalls, isNotEmpty);
    final records = consentCalls.last.body as Map;
    final kinds = (records['records'] as List).cast<Map>();
    expect(
      kinds.any(
        (r) => r['kind'] == 'product_analytics' && r['action'] == 'withdraw',
      ),
      isTrue,
    );
  });

  testWidgets('重新打开“产品改进统计”后恢复发送', (tester) async {
    final env = TestEnv.signedIn();
    final container = await pumpWith(tester, env);
    await container.read(consentProvider.notifier).setProductAnalytics(false);
    await container.read(consentProvider.notifier).setProductAnalytics(true);

    expect(container.read(consentProvider).productAnalyticsEnabled, isTrue);
    await fire(
      tester,
      () => container.read(productAnalyticsProvider).reportPageView('today'),
    );
    expect(env.server.calls('POST', _path), isNotEmpty);
  });
}
