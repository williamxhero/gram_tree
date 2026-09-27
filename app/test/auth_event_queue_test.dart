import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/auth/auth_controller.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/fake_event_queue.dart';

import 'helpers.dart';

/// 退出登录 / 注销账号时要清掉本机事件队列（含拒收区），不然同一台设备换个
/// 账号登录后，上一个账号没传完的事件会被当成新账号的事件传上去（代码评审
/// 发现，SPEC-010.1 合并时补的修复）。

void main() {
  test('退出登录后本机事件队列（含拒收区）被清空', () async {
    final server = FakeServer();
    final container = ProviderContainer(
      overrides: TestEnv.signedIn(server: server).overrides,
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();

    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    await queue.enqueue(
      QueuedEvent(
        id: 'e1',
        eventType: 'pipeline.self_check',
        typeVersion: 1,
        deviceId: 'device-1',
        deviceTime: DateTime.utc(2026, 9, 27),
        appVersion: '0.1.0-test',
      ),
    );
    // 模拟一条已经被服务端拒收、留在拒收区的事件。
    await queue.reject('e1', reasonCode: 'unknown_event_type');
    await queue.enqueue(
      QueuedEvent(
        id: 'e2',
        eventType: 'pipeline.self_check',
        typeVersion: 1,
        deviceId: 'device-1',
        deviceTime: DateTime.utc(2026, 9, 27, 1),
        appVersion: '0.1.0-test',
      ),
    );
    expect(await queue.rejectedCount(), 1);
    expect(await queue.pending(), hasLength(1));

    await container.read(authProvider.notifier).signOut();

    expect(await queue.pending(), isEmpty);
    expect(await queue.rejectedCount(), 0);
    expect(server.calls('POST', '/v1/auth/logout'), hasLength(1));
  });

  test('注销账号清本机会话时同样清空本机事件队列', () async {
    final container = ProviderContainer(
      overrides: TestEnv.signedIn().overrides,
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();

    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    await queue.enqueue(
      QueuedEvent(
        id: 'e1',
        eventType: 'pipeline.self_check',
        typeVersion: 1,
        deviceId: 'device-1',
        deviceTime: DateTime.utc(2026, 9, 27),
        appVersion: '0.1.0-test',
      ),
    );
    expect(await queue.pending(), hasLength(1));

    await container.read(authProvider.notifier).clearLocalSession();

    expect(await queue.pending(), isEmpty);
  });
}
