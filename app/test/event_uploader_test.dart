import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/event_uploader.dart';
import 'package:gram_tree/events/fake_event_queue.dart';

import 'helpers.dart';

/// 后台上传逻辑（SPEC-010.1 票 4），用内存队列（[FakeEventQueue]）+ 假服务端
/// （[FakeServer]），不涉及 drift。drift 落盘的存取和“杀进程重开”行为不能在这个
/// 目录测（真机实现依赖 dart:ffi，编译不到网页，`flutter test --platform chrome`
/// 会失败），改在 integration_test/event_queue_persistence_test.dart 里验证，
/// 只在安卓模拟器（CI）上真正跑到。

QueuedEvent sample({
  String id = '11111111-1111-4111-8111-111111111111',
  DateTime? deviceTime,
}) => QueuedEvent(
  id: id,
  eventType: 'pipeline.self_check',
  typeVersion: 1,
  deviceId: 'device-1',
  deviceTime: deviceTime ?? DateTime.utc(2026, 9, 27),
  appVersion: '0.1.0-test',
);

/// 短退避间隔覆盖，测试用：不用真的等 5 秒、10 分钟。跟生产的 provider 一样，
/// 容器销毁时要把还没触发的重试定时器取消掉，不然测试结束后定时器再触发会用到
/// 已经销毁的 ref，报错。
final _fastUploaderOverride = eventUploaderProvider.overrideWith((ref) {
  final uploader = EventUploader(
    ref,
    initialBackoff: const Duration(milliseconds: 5),
    maxBackoff: const Duration(milliseconds: 20),
  );
  ref.onDispose(uploader.dispose);
  return uploader;
});

void main() {
  test('未登录时不发请求，事件留在队列里', () async {
    final server = FakeServer();
    final container = ProviderContainer(
      overrides: TestEnv(server: server).overrides,
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();

    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    await queue.enqueue(sample());

    await container.read(eventUploaderProvider).triggerUpload();

    expect(server.calls('POST', '/v1/events/upload'), isEmpty);
    expect(await queue.pending(), hasLength(1));
  });

  test('已登录联网：批量上传成功后队列清空，按设备时间从早到晚发送', () async {
    final server = FakeServer();
    final container = ProviderContainer(
      overrides: TestEnv.signedIn(server: server).overrides,
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();

    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    await queue.enqueue(
      sample(id: 'b', deviceTime: DateTime.utc(2026, 9, 27, 1)),
    );
    await queue.enqueue(
      sample(id: 'a', deviceTime: DateTime.utc(2026, 9, 27, 0)),
    );

    await container.read(eventUploaderProvider).triggerUpload();

    final call = server.calls('POST', '/v1/events/upload').single;
    final ids = ((call.body as Map)['events'] as List)
        .map((e) => (e as Map)['id'])
        .toList();
    expect(ids, ['a', 'b']);
    expect(await queue.pending(), isEmpty);
  });

  test('服务端答复 duplicate 的事件同样从队列删除', () async {
    final server = FakeServer()
      ..on('POST', '/v1/events/upload', (r) {
        final events = ((r.body as Map)['events'] as List).cast<Map>();
        return (
          200,
          {
            'results': [
              for (final e in events) {'id': e['id'], 'status': 'duplicate'},
            ],
          },
        );
      });
    final container = ProviderContainer(
      overrides: TestEnv.signedIn(server: server).overrides,
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    await queue.enqueue(sample());

    await container.read(eventUploaderProvider).triggerUpload();
    expect(await queue.pending(), isEmpty);
  });

  test('部分事件遇到这份客户端还不认识的状态取值时，保守不删，留着重试', () async {
    final server = FakeServer()
      ..on('POST', '/v1/events/upload', (r) {
        final events = ((r.body as Map)['events'] as List).cast<Map>();
        // 服务端以后加了新状态（比如 rejected），这份客户端的枚举还不认识时，
        // 反序列化本身会失败——用一个真实不认识的取值模拟这种情况。
        return (
          200,
          {
            'results': [
              for (final e in events)
                {'id': e['id'], 'status': 'somebody_added_a_new_status'},
            ],
          },
        );
      });
    final container = ProviderContainer(
      overrides: [
        ...TestEnv.signedIn(server: server).overrides,
        _fastUploaderOverride,
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    await queue.enqueue(sample());

    // 不能因为解析失败就崩溃
    await expectLater(
      container.read(eventUploaderProvider).triggerUpload(),
      completes,
    );
    expect(await queue.pending(), hasLength(1));
  });

  test('5xx 失败时事件留在队列，按退避间隔重试，最终成功后清空', () async {
    var attempts = 0;
    final server = FakeServer()
      ..on('POST', '/v1/events/upload', (r) {
        attempts++;
        if (attempts < 3) {
          return FakeServer.error(500, 'internal_error', '服务器出错了');
        }
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
    final container = ProviderContainer(
      overrides: [
        ...TestEnv.signedIn(server: server).overrides,
        _fastUploaderOverride,
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    await queue.enqueue(sample());

    await container.read(eventUploaderProvider).triggerUpload();
    // 前两次都失败：请求发出去了，事件还在队列里，没有崩溃
    expect(attempts, 1);
    expect(await queue.pending(), hasLength(1));

    // 等退避重试跑完（5ms + 10ms 的退避，留足余量）
    await _waitUntil(() => attempts >= 3);
    await _waitUntil(() async => (await queue.pending()).isEmpty);
    expect(attempts, 3);
  });

  test('队列是空的时候不发请求', () async {
    final server = FakeServer();
    final container = ProviderContainer(
      overrides: TestEnv.signedIn(server: server).overrides,
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();

    await container.read(eventUploaderProvider).triggerUpload();
    expect(server.calls('POST', '/v1/events/upload'), isEmpty);
  });
}

/// 轮询等一个条件成立，避免死等固定时长导致测试变慢或偶发失败。
Future<void> _waitUntil(
  FutureOr<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!(await condition())) {
    if (DateTime.now().isAfter(deadline)) {
      fail('等待超时：条件一直没有成立');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
