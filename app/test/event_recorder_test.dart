import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/event_recorder.dart';
import 'package:gram_tree/events/fake_event_queue.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

/// 给各功能用的“记一条事件”简单调用（SPEC-010.1 票 4）。

void main() {
  test('离线（未登录）时记事件立即返回、写进本机队列，不发请求', () async {
    final server = FakeServer();
    final container = ProviderContainer(
      overrides: TestEnv(server: server).overrides,
    );
    addTearDown(container.dispose);

    await container
        .read(eventRecorderProvider)
        .record(
          eventType: 'pipeline.self_check',
          typeVersion: 1,
          correlation: EventCorrelationIds(recipeVersionId: 'recipe-1'),
          content: {'ok': true},
        );

    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    expect(queue.items, hasLength(1));
    final saved = queue.items.single;
    expect(saved.eventType, 'pipeline.self_check');
    expect(saved.typeVersion, 1);
    expect(saved.correlation?.recipeVersionId, 'recipe-1');
    expect(saved.content, {'ok': true});
    expect(saved.appVersion, isNotEmpty);
    expect(saved.deviceId, isNotEmpty);
    expect(saved.deviceTime.isUtc, isTrue);

    // 未登录：不应该真的发出上传请求
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(server.calls('POST', '/v1/events/upload'), isEmpty);
  });

  test('每次记事件都生成不同的事件 ID', () async {
    final container = ProviderContainer(overrides: TestEnv().overrides);
    addTearDown(container.dispose);
    final recorder = container.read(eventRecorderProvider);

    await recorder.record(eventType: 'pipeline.self_check', typeVersion: 1);
    await recorder.record(eventType: 'pipeline.self_check', typeVersion: 1);

    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    expect(queue.items.map((e) => e.id).toSet(), hasLength(2));
  });

  test('已登录联网时记事件后，后台会自动把它传上去', () async {
    final server = FakeServer();
    final container = ProviderContainer(
      overrides: TestEnv.signedIn(server: server).overrides,
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();

    await container
        .read(eventRecorderProvider)
        .record(eventType: 'pipeline.self_check', typeVersion: 1);

    await _waitUntil(
      () => server.calls('POST', '/v1/events/upload').isNotEmpty,
    );
    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    await _waitUntil(() => queue.items.isEmpty);
  });
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('等待超时：条件一直没有成立');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
