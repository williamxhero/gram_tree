import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/event_uploader.dart';
import 'package:gram_tree/events/write_registry.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

// Existing uploader regression coverage migrated to the account-scoped
// transport. New account isolation regressions exercise real pages separately.
String eventId(int index) =>
    '11111111-1111-4111-8111-${index.toString().padLeft(12, '0')}';
QueuedEvent sample({int index = 1, DateTime? deviceTime}) => QueuedEvent(
  id: eventId(index),
  ownerId: testUser().id,
  eventType: 'pipeline.self_check',
  typeVersion: 1,
  deviceId: 'device-1',
  deviceTime: deviceTime ?? DateTime.now().toUtc(),
  appVersion: '0.1.0-test',
  content: {'ping': 'retained'},
);

List<Map> writes(Recorded request) =>
    ((request.body as Map)['writes'] as List).cast<Map>();
(int, Object?) confirmed(Recorded request, {bool replay = false}) => (
  200,
  WriteBatchResponse(
    results: [
      for (final write in writes(request))
        WriteResult(
          writeId: write['write_id'] as String,
          status: replay
              ? WriteResultStatusEnum.alreadyProcessed
              : WriteResultStatusEnum.confirmed,
          confirmedAt: '2026-10-08T10:11:12Z',
          result: WriteResourceResult(
            resourceType: 'experience.event',
            resourceId: write['write_id'] as String,
          ),
        ),
    ],
  ).toJson(),
);

final _fastUploaderOverride = eventUploaderProvider.overrideWith((ref) {
  final uploader = EventUploader(
    ref,
    initialBackoff: const Duration(milliseconds: 5),
    maxBackoff: const Duration(milliseconds: 20),
  );
  ref.onDispose(uploader.dispose);
  return uploader;
});

Future<ProviderContainer> setup(TestEnv env, {bool fast = false}) async {
  final container = ProviderContainer(
    overrides: [...env.overrides, if (fast) _fastUploaderOverride],
  );
  addTearDown(container.dispose);
  await container.read(sessionStoreProvider).load();
  return container;
}

class _ThrowingEntriesQueue implements EventQueue {
  _ThrowingEntriesQueue(this._delegate);

  final EventQueue _delegate;

  @override
  WriteRegistry get registry => _delegate.registry;

  @override
  Stream<void> get changes => _delegate.changes;

  @override
  Future<void> enqueue(
    QueuedEvent event, {
    Map<String, dynamic>? businessRecord,
  }) => _delegate.enqueue(event, businessRecord: businessRecord);

  @override
  Future<List<QueueEntry>> entries({String? ownerId}) =>
      Future.error(StateError('queue read failed'));

  @override
  Future<void> update(QueueEntry entry) => _delegate.update(entry);

  @override
  Future<void> confirm(
    String id,
    String ownerId,
    Map<String, dynamic> result, {
    DateTime? confirmedAt,
  }) => _delegate.confirm(id, ownerId, result, confirmedAt: confirmedAt);

  @override
  Future<void> retryAccount(String ownerId) => _delegate.retryAccount(ownerId);

  @override
  Future<void> clearAccount(String ownerId, {bool experienceOnly = false}) =>
      _delegate.clearAccount(ownerId, experienceOnly: experienceOnly);

  @override
  Future<List<QueuedEvent>> pending({int? limit, String? ownerId}) =>
      _delegate.pending(limit: limit, ownerId: ownerId);

  @override
  Future<void> remove(String id) => _delegate.remove(id);

  @override
  Future<void> removeAll(Iterable<String> ids) => _delegate.removeAll(ids);

  @override
  Future<void> reject(String id, {required String reasonCode}) =>
      _delegate.reject(id, reasonCode: reasonCode);

  @override
  Future<int> rejectedCount() => _delegate.rejectedCount();

  @override
  Future<LegacyQueueDiagnostics> legacyDiagnostics() =>
      _delegate.legacyDiagnostics();

  @override
  Future<void> clear() => _delegate.clear();

  @override
  Future<void> close() => _delegate.close();
}

void main() {
  test('unexpected queue errors do not escape background upload', () async {
    final env = TestEnv.signedIn();
    final container = ProviderContainer(
      overrides: [
        ...env.overrides,
        eventQueueProvider.overrideWithValue(
          _ThrowingEntriesQueue(env.eventQueue),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();

    final uploader = container.read(eventUploaderProvider);
    await expectLater(uploader.networkRestored(), completes);
    await expectLater(uploader.triggerUpload(), completes);
  });

  test('未登录时不发请求，已归属事件留在队列里不认领', () async {
    final env = TestEnv();
    final container = await setup(env);
    await env.eventQueue.enqueue(sample());
    await container.read(eventUploaderProvider).triggerUpload();
    expect(env.server.calls('POST', '/v1/sync/writes'), isEmpty);
    expect(await env.eventQueue.pending(), hasLength(1));
  });

  test('已登录联网按入队顺序发送，不按设备时间；确认记录保留但不再待同步', () async {
    final env = TestEnv.signedIn();
    final container = await setup(env);
    await env.eventQueue.enqueue(
      sample(index: 2, deviceTime: DateTime.utc(2026, 9, 27, 1)),
    );
    await env.eventQueue.enqueue(
      sample(index: 1, deviceTime: DateTime.utc(2026, 9, 27, 0)),
    );
    await container.read(eventUploaderProvider).triggerUpload();
    expect(
      env.server
          .calls('POST', '/v1/sync/writes')
          .expand(writes)
          .map((w) => w['write_id']),
      [eventId(2), eventId(1)],
    );
    expect(await env.eventQueue.pending(), isEmpty);
  });

  test('服务端 already_processed 同样停止重传且保留稳定关联', () async {
    final server = FakeServer()
      ..on('POST', '/v1/sync/writes', (r) => confirmed(r, replay: true));
    final env = TestEnv.signedIn(server: server);
    final container = await setup(env);
    await env.eventQueue.enqueue(sample());
    await container.read(eventUploaderProvider).triggerUpload();
    expect(await env.eventQueue.pending(), isEmpty);
    expect(
      (await env.eventQueue.entries()).single.result?['resource_id'],
      eventId(1),
    );
  });

  test('未知响应状态保守保留内容，解析失败不崩溃', () async {
    final server = FakeServer()
      ..on(
        'POST',
        '/v1/sync/writes',
        (r) => (
          200,
          {
            'results': [
              for (final w in writes(r))
                {
                  'write_id': w['write_id'],
                  'status': 'somebody_added_a_new_status',
                },
            ],
          },
        ),
      );
    final env = TestEnv.signedIn(server: server);
    final container = await setup(env, fast: true);
    await env.eventQueue.enqueue(sample());
    await expectLater(
      container.read(eventUploaderProvider).triggerUpload(),
      completes,
    );
    expect(await env.eventQueue.pending(), hasLength(1));
  });

  for (final serverTime in [null, '2026-10-08T10:11:12']) {
    test('确认响应缺少明确服务端时区时保留原写入：$serverTime', () async {
      final server = FakeServer()
        ..on(
          'POST',
          '/v1/sync/writes',
          (request) => (
            200,
            {
              'results': [
                {
                  'write_id': writes(request).single['write_id'],
                  'status': 'confirmed',
                  ...?serverTime == null ? null : {'confirmed_at': serverTime},
                  'result': {
                    'resource_type': 'experience.event',
                    'resource_id': writes(request).single['write_id'],
                  },
                },
              ],
            },
          ),
        );
      final env = TestEnv.signedIn(server: server);
      final container = await setup(env);
      final original = sample();
      await env.eventQueue.enqueue(original);
      await container.read(eventUploaderProvider).triggerUpload();
      final entry = (await env.eventQueue.entries()).single;
      expect(entry.write.sameEnvelope(original), isTrue);
      expect(entry.state, WriteState.pending);
      expect(entry.reasonCode, 'invalid_or_lost_response');
      expect(entry.confirmedAt, isNull);
    });
  }

  test('5xx 保留内容按退避重试，第三次确认后停止', () async {
    var attempts = 0;
    final server = FakeServer()
      ..on('POST', '/v1/sync/writes', (r) {
        attempts++;
        return attempts < 3
            ? FakeServer.error(500, 'internal_error', '服务器出错了')
            : confirmed(r);
      });
    final env = TestEnv.signedIn(server: server);
    final container = await setup(env, fast: true);
    await env.eventQueue.enqueue(sample());
    await container.read(eventUploaderProvider).triggerUpload();
    expect(attempts, 1);
    expect(await env.eventQueue.pending(), hasLength(1));
    await _waitUntil(() async => (await env.eventQueue.pending()).isEmpty);
    expect(attempts, 3);
  });

  test('过期已尝试写入按入队顺序唤醒，不消耗新写入、阻塞子写入或其他账号', () async {
    final server = FakeServer()
      ..on(
        'POST',
        '/v1/sync/writes',
        (_) => FakeServer.error(503, 'unavailable', '暂不可用'),
      );
    final env = TestEnv.signedIn(server: server);
    final container = ProviderContainer(
      overrides: [
        ...env.overrides,
        eventUploaderProvider.overrideWith((ref) {
          final uploader = EventUploader(
            ref,
            initialBackoff: const Duration(seconds: 2),
            maxBackoff: const Duration(seconds: 8),
          );
          ref.onDispose(uploader.dispose);
          return uploader;
        }),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionStoreProvider).load();
    final parent = sample(index: 1);
    final secondRetry = sample(index: 3);
    final thirdRetry = sample(index: 4);
    // New unrelated work deliberately precedes the existing due retries.
    for (final event in [parent, sample(index: 2), secondRetry, thirdRetry]) {
      await env.eventQueue.enqueue(event);
    }
    await env.eventQueue.enqueue(
      QueuedEvent.write(
        id: eventId(5),
        ownerId: parent.ownerId,
        deviceTime: parent.deviceTime,
        writeType: parent.writeType,
        payload: parent.payload,
        dependencies: [parent.id],
      ),
    );
    await env.eventQueue.enqueue(sample(index: 6));
    await env.eventQueue.enqueue(sample(index: 7));
    await env.eventQueue.enqueue(
      QueuedEvent.write(
        id: eventId(8),
        ownerId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        deviceTime: parent.deviceTime,
        writeType: parent.writeType,
        payload: parent.payload,
      ),
    );
    final overdue = DateTime.now().toUtc().subtract(const Duration(seconds: 1));
    for (final entry in await env.eventQueue.entries()) {
      if (entry.write.id == eventId(2)) continue;
      await env.eventQueue.update(
        entry.change(
          state: entry.write.id == eventId(5)
              ? WriteState.deferred
              : entry.write.id == eventId(6)
              ? WriteState.failed
              : entry.write.id == eventId(7)
              ? WriteState.loginPaused
              : WriteState.pending,
          attempts: 1,
          reasonCode: entry.write.id == eventId(5)
              ? 'dependency_not_confirmed'
              : 'network_or_server_failure',
          // The later write is older by deadline, but both are already due.
          // FIFO must still win, as with deadlines truncated by native storage.
          nextAttemptAt: entry.write.id == eventId(4)
              ? overdue.subtract(const Duration(seconds: 1))
              : overdue,
        ),
      );
    }
    await container.read(eventUploaderProvider).triggerUpload();
    expect(server.calls('POST', '/v1/sync/writes'), hasLength(1));
    await _waitUntil(() async {
      final entries = await env.eventQueue.entries();
      return entries[2].attempts == 2 && entries[3].attempts == 2;
    }, timeout: const Duration(seconds: 1));
    // Allow any accidental zero-delay wake to run before checking the boundary.
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(server.calls('POST', '/v1/sync/writes').expand(writes).toList(), [
      parent.toJson(),
      secondRetry.toJson(),
      thirdRetry.toJson(),
    ]);
    final retained = await env.eventQueue.entries();
    expect(retained[1].attempts, 0);
    expect(retained[1].nextAttemptAt, isNull);
    expect(retained[4].attempts, 1);
    expect(retained[4].state, WriteState.deferred);
    expect(retained[4].nextAttemptAt, overdue);
    expect(retained[5].state, WriteState.failed);
    expect(retained[5].attempts, 1);
    expect(retained[6].state, WriteState.loginPaused);
    expect(retained[6].attempts, 1);
    expect(retained[7].attempts, 1);
    expect(
      retained.every((entry) => entry.write.content?['ping'] == 'retained'),
      isTrue,
    );
  });

  test('定时重试确认传输恢复后，新写入仍自动同步，不永久暂停', () async {
    var requests = 0;
    final server = FakeServer()
      ..on('POST', '/v1/sync/writes', (request) {
        requests++;
        return requests == 1
            ? FakeServer.error(503, 'unavailable', '暂不可用')
            : confirmed(request);
      });
    final env = TestEnv.signedIn(server: server);
    final container = await setup(env, fast: true);
    final retained = sample(index: 1);
    final fresh = sample(index: 2);
    await env.eventQueue.enqueue(retained);
    await env.eventQueue.enqueue(fresh);
    await container.read(eventUploaderProvider).triggerUpload();
    expect(server.calls('POST', '/v1/sync/writes'), hasLength(1));
    expect(await env.eventQueue.pending(), hasLength(2));
    // Recovery is discovered by the existing retry, without a manual network
    // reset or a new action. Its confirmation must release outage suspension.
    await _waitUntil(() async => (await env.eventQueue.pending()).isEmpty);
    expect(server.calls('POST', '/v1/sync/writes').expand(writes).toList(), [
      retained.toJson(),
      retained.toJson(),
      fresh.toJson(),
    ]);
  });

  for (final outcome in ['failed', 'conflict']) {
    for (final parentFirst in [true, false]) {
      test('前置 $outcome（父先入队 $parentFirst）同轮阻止子上传且不消耗额度', () async {
        final server = FakeServer()
          ..on(
            'POST',
            '/v1/sync/writes',
            (request) => (
              200,
              {
                'results': [
                  {
                    'write_id': writes(request).single['write_id'],
                    'status': outcome,
                    'reason_code': 'parent_$outcome',
                  },
                ],
              },
            ),
          );
        final env = TestEnv.signedIn(server: server);
        final container = await setup(env);
        final parent = sample(index: 1);
        final child = QueuedEvent.write(
          id: eventId(2),
          ownerId: parent.ownerId,
          deviceTime: parent.deviceTime,
          writeType: parent.writeType,
          payload: parent.payload,
          dependencies: [parent.id],
        );
        for (final event in parentFirst ? [parent, child] : [child, parent]) {
          await env.eventQueue.enqueue(event);
        }
        // A previous deferred attempt must not delay learning that its parent
        // has now failed/conflicted, nor count as a new child HTTP attempt.
        final childEntry = (await env.eventQueue.entries()).singleWhere(
          (entry) => entry.write.id == child.id,
        );
        await env.eventQueue.update(
          childEntry.change(
            state: WriteState.deferred,
            attempts: 3,
            reasonCode: 'dependency_not_arrived',
            nextAttemptAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          ),
        );
        await container.read(eventUploaderProvider).triggerUpload();
        expect(
          server
              .calls('POST', '/v1/sync/writes')
              .expand(writes)
              .map((write) => write['write_id']),
          [parent.id],
        );
        final settled = (await env.eventQueue.entries()).singleWhere(
          (entry) => entry.write.id == child.id,
        );
        expect(
          settled.state,
          outcome == 'failed' ? WriteState.failed : WriteState.deferred,
        );
        expect(settled.reasonCode, 'dependency_$outcome');
        expect(settled.attempts, 3);
        expect(settled.write.content, {'ping': 'retained'});
        await container.read(eventUploaderProvider).triggerUpload();
        expect(server.calls('POST', '/v1/sync/writes'), hasLength(1));
      });
    }
  }

  test('断网超限同轮结算前置失败，但不消耗子写入或无关写入的尝试', () async {
    final server = FakeServer()
      ..on(
        'POST',
        '/v1/sync/writes',
        (_) => FakeServer.error(503, 'unavailable', '暂不可用'),
      );
    final env = TestEnv.signedIn(server: server);
    final container = await setup(env);
    final parent = sample(index: 1);
    await env.eventQueue.enqueue(
      QueuedEvent.write(
        id: eventId(2),
        ownerId: parent.ownerId,
        deviceTime: parent.deviceTime,
        writeType: parent.writeType,
        payload: parent.payload,
        dependencies: [parent.id],
      ),
    );
    await env.eventQueue.enqueue(parent);
    await env.eventQueue.enqueue(sample(index: 3));
    final parentEntry = (await env.eventQueue.entries()).singleWhere(
      (entry) => entry.write.id == parent.id,
    );
    await env.eventQueue.update(
      parentEntry.change(state: WriteState.pending, attempts: 19),
    );
    await container.read(eventUploaderProvider).triggerUpload();
    final entries = await env.eventQueue.entries();
    expect(entries[0].reasonCode, 'dependency_failed');
    expect(entries[0].attempts, 0);
    expect(
      entries[1].reasonCode,
      'retry_limit_exceeded:network_or_server_failure',
    );
    expect(entries[1].attempts, 20);
    expect(entries[2].state, WriteState.pending);
    expect(entries[2].attempts, 0);
    expect(
      server
          .calls('POST', '/v1/sync/writes')
          .expand(writes)
          .map((write) => write['write_id']),
      [parent.id],
    );
  });

  test('队列为空时不发请求', () async {
    final env = TestEnv.signedIn();
    final container = await setup(env);
    await container.read(eventUploaderProvider).triggerUpload();
    expect(env.server.calls('POST', '/v1/sync/writes'), isEmpty);
  });

  test('部分拒收保留内容且不再上传，确认和重放停止；原因上报不含内容', () async {
    final server = FakeServer()
      ..on('POST', '/v1/sync/writes', (r) {
        final write = writes(r).single;
        if (write['write_id'] == eventId(1)) return confirmed(r);
        if (write['write_id'] == eventId(2)) return confirmed(r, replay: true);
        return (
          200,
          WriteBatchResponse(
            results: [
              WriteResult(
                writeId: write['write_id'] as String,
                status: WriteResultStatusEnum.failed,
                reasonCode: 'unknown_event_type',
              ),
            ],
          ).toJson(),
        );
      });
    final env = TestEnv.signedIn(server: server);
    final container = await setup(env);
    for (var i = 1; i <= 3; i++) {
      await env.eventQueue.enqueue(sample(index: i));
    }
    await container.read(eventUploaderProvider).triggerUpload();
    expect(await env.eventQueue.pending(), isEmpty);
    expect(env.eventQueue.rejectedItems.map((e) => e.id), [eventId(3)]);
    expect(await env.eventQueue.rejectedCount(), 1);
    final reports = env.eventReports.reports;
    expect(reports, hasLength(1));
    expect(reports.single, contains(eventId(3)));
    expect(reports.single, contains('pipeline.self_check'));
    expect(reports.single, contains('unknown_event_type'));
    expect(reports.single, isNot(contains('"content"')));
    final before = server.calls('POST', '/v1/sync/writes').length;
    await container.read(eventUploaderProvider).triggerUpload();
    expect(server.calls('POST', '/v1/sync/writes').length, before);
  });

  test('积压超过旧单批上限时单封包依次上传，全部确认', () async {
    final env = TestEnv.signedIn();
    final container = await setup(env);
    for (var i = 1; i <= 5; i++) {
      await env.eventQueue.enqueue(sample(index: i));
    }
    await container.read(eventUploaderProvider).triggerUpload();
    expect(await env.eventQueue.pending(), isEmpty);
    expect(env.server.calls('POST', '/v1/sync/writes'), hasLength(5));
    expect(
      env.server
          .calls('POST', '/v1/sync/writes')
          .every((r) => writes(r).length == 1),
      isTrue,
    );
  });

  test('服务端单批上限为2时，新单封包传输不超限、无重传且全部成功', () async {
    final server = FakeServer()
      ..on(
        'POST',
        '/v1/sync/writes',
        (r) => writes(r).length > 2
            ? FakeServer.error(422, 'too_many_events', '超过上限')
            : confirmed(r),
      );
    final env = TestEnv.signedIn(server: server);
    final container = await setup(env);
    for (var i = 1; i <= 5; i++) {
      await env.eventQueue.enqueue(sample(index: i));
    }
    await container.read(eventUploaderProvider).triggerUpload();
    expect(await env.eventQueue.pending(), isEmpty);
    final calls = server.calls('POST', '/v1/sync/writes').toList();
    expect(calls, hasLength(5));
    expect(calls.every((r) => writes(r).length <= 2), isTrue);
  });

  test('单条超限是永久失败：保留内容供处理，不原地自旋或定时无限重传', () async {
    final server = FakeServer()
      ..on(
        'POST',
        '/v1/sync/writes',
        (_) => FakeServer.error(422, 'payload_too_large', '单条超过上限'),
      );
    final env = TestEnv.signedIn(server: server);
    final container = await setup(env, fast: true);
    await env.eventQueue.enqueue(sample());
    await container.read(eventUploaderProvider).triggerUpload();
    expect(server.calls('POST', '/v1/sync/writes'), hasLength(1));
    expect(env.eventQueue.rejectedItems.single.content, {'ping': 'retained'});
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(server.calls('POST', '/v1/sync/writes'), hasLength(1));
    await container.read(eventUploaderProvider).triggerUpload();
    expect(server.calls('POST', '/v1/sync/writes'), hasLength(1));
  });

  test('本账号离线积压超过阈值天数时告警一次，不丢内容', () async {
    final env = TestEnv.signedIn(offline: true);
    final container = await setup(env);
    await env.eventQueue.enqueue(
      sample(
        deviceTime: DateTime.now().toUtc().subtract(const Duration(days: 2)),
      ),
    );
    await container.read(eventUploaderProvider).triggerUpload();
    expect(await env.eventQueue.pending(), hasLength(1));
    expect(env.eventReports.reports, hasLength(1));
    expect(env.eventReports.reports.single, contains('event_backlog_alert'));
  });

  test('本账号队列条数超过阈值时告警一次，不丢内容', () async {
    final env = TestEnv.signedIn(offline: true);
    final container = await setup(env);
    for (var i = 1; i <= EventUploader.backlogCountThreshold + 1; i++) {
      await env.eventQueue.enqueue(sample(index: i));
    }
    await container.read(eventUploaderProvider).triggerUpload();
    expect(
      await env.eventQueue.pending(),
      hasLength(EventUploader.backlogCountThreshold + 1),
    );
    expect(env.eventReports.reports, hasLength(1));
    expect(env.eventReports.reports.single, contains('event_backlog_alert'));
  });
}

Future<void> _waitUntil(
  FutureOr<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!(await condition())) {
    if (DateTime.now().isAfter(deadline)) fail('等待超时：条件一直没有成立');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
