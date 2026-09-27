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

  // SPEC-010.1 票 5（#73）：拒收、分批、积压告警。

  test('部分拒收：接收和重复的从队列删除，拒收的进拒收区且不再上传，原因被上报不含内容', () async {
    final server = FakeServer()
      ..on('POST', '/v1/events/upload', (r) {
        final events = ((r.body as Map)['events'] as List).cast<Map>();
        return (
          200,
          {
            'results': [
              for (final e in events)
                if (e['id'] == 'accepted-1')
                  {'id': e['id'], 'status': 'accepted'}
                else if (e['id'] == 'dup-1')
                  {'id': e['id'], 'status': 'duplicate'}
                else
                  {
                    'id': e['id'],
                    'status': 'rejected',
                    'reason': {
                      'code': 'unknown_event_type',
                      'message': '不认识这个事件类型',
                    },
                  },
            ],
          },
        );
      });
    final env = TestEnv.signedIn(server: server);
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    await queue.enqueue(
      sample(id: 'accepted-1', deviceTime: DateTime.utc(2026, 9, 27, 0)),
    );
    await queue.enqueue(
      sample(id: 'dup-1', deviceTime: DateTime.utc(2026, 9, 27, 1)),
    );
    await queue.enqueue(
      sample(id: 'bad-1', deviceTime: DateTime.utc(2026, 9, 27, 2)),
    );

    await container.read(eventUploaderProvider).triggerUpload();

    // 已接收、重复的都从待上传队列删除；拒收的既不在待上传队列，也不再重传。
    expect(await queue.pending(), isEmpty);
    expect(queue.rejectedItems.map((e) => e.id), ['bad-1']);
    expect(await queue.rejectedCount(), 1);

    // 拒收原因被上报，只带 ID/类型/版本/原因代码，不带事件内容。
    final reports = env.eventReports.reports;
    expect(reports, hasLength(1));
    expect(reports.single, contains('bad-1'));
    expect(reports.single, contains('pipeline.self_check'));
    expect(reports.single, contains('unknown_event_type'));
    expect(reports.single, isNot(contains('"content"')));

    // 再触发一次也不会把拒收的那条重新发出去（队列已经空了，不会再发请求）。
    final callsBefore = server.calls('POST', '/v1/events/upload').length;
    await container.read(eventUploaderProvider).triggerUpload();
    expect(server.calls('POST', '/v1/events/upload').length, callsBefore);
  });

  test('积压超过单批上限时分多批上传，全部上传完成', () async {
    final server = FakeServer();
    final container = ProviderContainer(
      overrides: [
        ...TestEnv.signedIn(server: server).overrides,
        eventUploaderProvider.overrideWith((ref) {
          final uploader = EventUploader(
            ref,
            initialBackoff: const Duration(milliseconds: 5),
            maxBackoff: const Duration(milliseconds: 20),
            batchSize: 2,
          );
          ref.onDispose(uploader.dispose);
          return uploader;
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    for (var i = 0; i < 5; i++) {
      await queue.enqueue(
        sample(id: 'e$i', deviceTime: DateTime.utc(2026, 9, 27, i)),
      );
    }

    await container.read(eventUploaderProvider).triggerUpload();

    expect(await queue.pending(), isEmpty);
    // 5 条事件、单批 2 条：2 + 2 + 1，一共 3 次请求。
    expect(server.calls('POST', '/v1/events/upload'), hasLength(3));
  });

  test('服务端答复超过上限时自动缩小批次重传，最终全部上传成功', () async {
    final server = FakeServer()
      ..on('POST', '/v1/events/upload', (r) {
        final events = ((r.body as Map)['events'] as List).cast<Map>();
        if (events.length > 2) {
          return FakeServer.error(422, 'too_many_events', '单次上传的事件条数超过上限');
        }
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
        eventUploaderProvider.overrideWith((ref) {
          final uploader = EventUploader(
            ref,
            initialBackoff: const Duration(milliseconds: 5),
            maxBackoff: const Duration(milliseconds: 20),
            batchSize: 5,
          );
          ref.onDispose(uploader.dispose);
          return uploader;
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    for (var i = 0; i < 5; i++) {
      await queue.enqueue(
        sample(id: 'e$i', deviceTime: DateTime.utc(2026, 9, 27, i)),
      );
    }

    await container.read(eventUploaderProvider).triggerUpload();

    expect(await queue.pending(), isEmpty);
    // 第一次按 5 条一批被拒（超过上限），砍到 2 条重传后就一直成功了。
    final calls = server.calls('POST', '/v1/events/upload').toList();
    expect(calls.first.body, isA<Map>());
    expect(((calls.first.body as Map)['events'] as List), hasLength(5));
    expect(calls.length, greaterThan(1));
    expect(
      ((calls.last.body as Map)['events'] as List).length,
      lessThanOrEqualTo(2),
    );
  });

  test('单条事件本身就超过服务端上限时按退避重试，不会不停原地重试', () async {
    // 服务端对任何批次（哪怕只有 1 条）都答复超过上限：批次已经砍到 1 条砍不动了，
    // 应该转成按退避间隔重试，而不是每次都立刻重试、把队列彻底卡死打爆服务端。
    final server = FakeServer()
      ..on(
        'POST',
        '/v1/events/upload',
        (_) => FakeServer.error(422, 'payload_too_large', '单条事件超过大小上限'),
      );
    final container = ProviderContainer(
      overrides: [
        ...TestEnv.signedIn(server: server).overrides,
        eventUploaderProvider.overrideWith((ref) {
          final uploader = EventUploader(
            ref,
            initialBackoff: const Duration(milliseconds: 20),
            maxBackoff: const Duration(milliseconds: 40),
            batchSize: 1,
          );
          ref.onDispose(uploader.dispose);
          return uploader;
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    await queue.enqueue(sample());

    await container.read(eventUploaderProvider).triggerUpload();
    // 批次已经是 1、砍不动了：这一轮 triggerUpload 只应该请求一次就转成退避重试，
    // 不能在没有任何等待的情况下原地一直重传。
    expect(server.calls('POST', '/v1/events/upload'), hasLength(1));
    expect(await queue.pending(), hasLength(1)); // 事件还在，没有被丢弃

    // 退避到期后触发下一次重试，确认走的是定时重试而不是死循环。
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(
      server.calls('POST', '/v1/events/upload').length,
      inInclusiveRange(2, 3),
    );
  });

  test('未登录、有一条积压超过阈值天数的事件时发一次积压告警，不丢事件', () async {
    final server = FakeServer();
    final env = TestEnv(server: server); // 未登录：不会真的发上传请求
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    await queue.enqueue(
      sample(
        id: 'old-1',
        deviceTime: DateTime.now().toUtc().subtract(const Duration(days: 2)),
      ),
    );

    await container.read(eventUploaderProvider).triggerUpload();

    // 没有被删除
    expect(await queue.pending(), hasLength(1));
    // 只报一次
    expect(env.eventReports.reports, hasLength(1));
    expect(env.eventReports.reports.single, contains('event_backlog_alert'));
  });

  test('队列条数超过阈值时也发一次积压告警，不丢事件', () async {
    final server = FakeServer();
    final env = TestEnv(server: server); // 未登录：不会真的发上传请求
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    final queue = container.read(eventQueueProvider) as FakeEventQueue;
    for (var i = 0; i < EventUploader.backlogCountThreshold + 1; i++) {
      await queue.enqueue(
        sample(id: 'e$i', deviceTime: DateTime.utc(2026, 9, 27, 0, i)),
      );
    }

    await container.read(eventUploaderProvider).triggerUpload();

    expect(
      await queue.pending(),
      hasLength(EventUploader.backlogCountThreshold + 1),
    );
    expect(env.eventReports.reports, hasLength(1));
    expect(env.eventReports.reports.single, contains('event_backlog_alert'));
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
