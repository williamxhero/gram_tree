import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/event_recorder.dart';
import 'package:gram_tree/events/fake_event_queue.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

// Preserve the existing recorder regressions using valid registered payloads;
// new anonymous work is suppressed rather than adopted by the next login.
void main() {
  test('未登录不创建新的无归属内容，不发请求', () async {
    final env = TestEnv();
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await container
        .read(eventRecorderProvider)
        .record(
          eventType: 'pipeline.self_check',
          typeVersion: 1,
          content: {'ping': 'anonymous'},
        );
    expect(env.eventQueue.items, isEmpty);
    expect(env.server.calls('POST', '/v1/sync/writes'), isEmpty);
  });

  test('已归属离线记录立即落本机，保留关联、内容及UTC时间', () async {
    final env = TestEnv.signedIn(offline: true);
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    const version = '11111111-1111-4111-8111-111111111111';
    await container
        .read(eventRecorderProvider)
        .record(
          eventType: 'pipeline.self_check',
          typeVersion: 1,
          correlation: EventCorrelationIds(recipeVersionId: version),
          content: {'ping': 'offline'},
        );
    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    expect(queue.items, hasLength(1));
    final saved = queue.items.single;
    expect(saved.ownerId, env.server.user.id);
    expect(saved.eventType, 'pipeline.self_check');
    expect(saved.typeVersion, 1);
    expect(saved.correlation?.recipeVersionId, version);
    expect(saved.content, {'ping': 'offline'});
    expect(saved.appVersion, isNotEmpty);
    expect(saved.deviceId, isNotEmpty);
    expect(saved.deviceTime.isUtc, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(env.server.calls('POST', '/v1/sync/writes'), isEmpty);
  });

  test('每次记事件生成不同的UUIDv4', () async {
    final env = TestEnv.signedIn(offline: true);
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    final recorder = container.read(eventRecorderProvider);
    await recorder.record(
      eventType: 'pipeline.self_check',
      typeVersion: 1,
      content: {'ping': 'first'},
    );
    await recorder.record(
      eventType: 'pipeline.self_check',
      typeVersion: 1,
      content: {'ping': 'second'},
    );
    expect(env.eventQueue.items.map((e) => e.id).toSet(), hasLength(2));
    expect(
      env.eventQueue.items.every(
        (e) => RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(e.id),
      ),
      isTrue,
    );
  });

  test('已登录联网记录后自动发送，确认后不再待同步', () async {
    final env = TestEnv.signedIn();
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    await container
        .read(eventRecorderProvider)
        .record(
          eventType: 'pipeline.self_check',
          typeVersion: 1,
          content: {'ping': 'online'},
        );
    await _waitUntil(
      () => env.server.calls('POST', '/v1/sync/writes').isNotEmpty,
    );
    await _waitUntil(() => env.eventQueue.items.isEmpty);
  });
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('等待超时：条件一直没有成立');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
