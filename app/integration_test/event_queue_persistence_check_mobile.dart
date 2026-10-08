import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/event_queue_mobile.dart';
import 'package:gramtree_api/gramtree_api.dart';

/// 手机端真的落盘一次，验证 drift 队列连接关闭/重建后数据还在（不是 OS 杀进程）。
///
/// 用独立的库名（不是生产用的 `event_queue`），也不需要 path_provider——直接复用
/// 生产代码同一套 `driftDatabase(name: ...)` 打开方式（见 event_queue_mobile.dart 的
/// [EventQueueDatabase]）。这只验证数据库连接重建；真实 OS 杀进程、事务中断及
/// 后台恢复行为仍需独立安卓验收，不能由这个测试代替。
const _dbName = 'event_queue_persistence_check';

EventQueueDatabase _open() =>
    EventQueueDatabase.withExecutor(driftDatabase(name: _dbName));

QueuedEvent _event(String id, DateTime deviceTime) => QueuedEvent(
  id: id,
  ownerId: 'ccccccc1-cccc-4ccc-8ccc-cccccccccccc',
  eventType: 'pipeline.self_check',
  typeVersion: 1,
  deviceId: 'integration-test-device',
  deviceTime: deviceTime,
  appVersion: '0.0.0-integration-test',
  correlation: EventCorrelationIds(
    recipeVersionId: 'ddddddd1-dddd-4ddd-8ddd-dddddddddddd',
  ),
  content: {'ping': 'durable'},
);

Future<void> checkEventQueueSurvivesRestart() async {
  // 先清干净，避免真机上跑过好几次互相干扰（CI 的模拟器是每次全新起的，
  // 这一步主要是给真机手测兜底）。
  final cleanupDb = _open();
  await cleanupDb.delete(cleanupDb.queuedEvents).go();
  await cleanupDb.close();

  final earlyId = 'aaaaaaa1-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  final lateId = 'bbbbbbb1-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

  final queue1 = DriftEventQueue(_open());
  // 设备时间倒退不改变持久入队顺序。
  await queue1.enqueue(_event(lateId, DateTime.utc(2026, 9, 27, 1)));
  await queue1.enqueue(_event(earlyId, DateTime.utc(2026, 9, 27, 0)));

  final beforeRestart = await queue1.pending();
  expect(beforeRestart.map((e) => e.id).toList(), [lateId, earlyId]);
  expect(beforeRestart.first.ownerId, 'ccccccc1-cccc-4ccc-8ccc-cccccccccccc');
  expect(
    beforeRestart.first.correlation?.recipeVersionId,
    'ddddddd1-dddd-4ddd-8ddd-dddddddddddd',
  );
  expect(beforeRestart.first.content, {'ping': 'durable'});
  // drift 默认把 DateTime 存成不带时区的 unix 时间戳，读回来时 isUtc 标记会丢，
  // 序列化成请求体时就漏掉时区后缀，被服务端拒收（"Input should have timezone
  // info"）。这条断言曾经在这里漏掉，导致真机/模拟器上传一直 422，网页版和
  // 单元测试（内存队列，没有序列化往返）却测不出来——代码评审后补上。
  expect(beforeRestart.first.deviceTime.isUtc, isTrue);
  expect(beforeRestart.first.deviceTime.toIso8601String(), endsWith('Z'));

  // 删掉一条，模拟服务端已经确认收到。
  await queue1.remove(lateId);
  await queue1.close();

  // 关闭并重建数据库连接，仍在同一进程内指向同一个数据库文件。
  final queue2 = DriftEventQueue(_open());
  final afterRestart = await queue2.pending();
  expect(afterRestart.map((e) => e.id).toList(), [earlyId]);

  // 票 5（#73）：拒收之后从待上传队列消失、进拒收区，重建数据库连接后拒收区还在。
  await queue2.reject(earlyId, reasonCode: 'unknown_event_type');
  expect(await queue2.pending(), isEmpty);
  expect(await queue2.rejectedCount(), 1);
  await queue2.close();

  final queue3 = DriftEventQueue(_open());
  expect(await queue3.pending(), isEmpty);
  expect(await queue3.rejectedCount(), 1);
  await queue3.close();

  // The generic queue's delivery metadata and retained business content must
  // round-trip too. This still tests connection reopening, NOT OS process death.
  final queue4 = DriftEventQueue(_open());
  final retryAt = DateTime.utc(2026, 10, 8, 12);
  final confirmedAt = DateTime.utc(2026, 10, 8, 11);
  final ids = <String>[];
  for (final (index, state) in WriteState.values.indexed) {
    final id =
        '${(index + 1).toRadixString(16).padLeft(8, '0')}-eeee-4eee-8eee-eeeeeeeeeeee';
    ids.add(id);
    await queue4.enqueue(
      _event(id, DateTime.utc(2026, 10, 8)),
      businessRecord: {'draft': 'retained-${state.name}'},
    );
    final entry = (await queue4.entries()).singleWhere((e) => e.write.id == id);
    await queue4.update(
      entry.change(
        state: state,
        attempts: 3,
        reasonCode: 'retained-${state.name}',
        nextAttemptAt: retryAt,
        result: {'resource_id': 'receipt-${state.name}'},
        confirmedAt: state == WriteState.confirmed ? confirmedAt : null,
      ),
    );
  }
  final durable = (await queue4.entries())
      .where((e) => ids.contains(e.write.id))
      .toList();
  await queue4.close();
  final queue5 = DriftEventQueue(_open());
  final reopened = (await queue5.entries())
      .where((e) => ids.contains(e.write.id))
      .toList();
  expect(reopened.map((e) => e.state).toList(), WriteState.values);
  expect(reopened.map((e) => e.write.id).toList(), ids);
  for (final (index, entry) in reopened.indexed) {
    expect(entry.write.toJson(), durable[index].write.toJson());
    expect(entry.sequence, durable[index].sequence);
    expect(entry.attempts, 3);
    expect(entry.reasonCode, 'retained-${entry.state.name}');
    expect(entry.nextAttemptAt, retryAt);
    expect(entry.result, {'resource_id': 'receipt-${entry.state.name}'});
    expect(entry.businessRecord, {'draft': 'retained-${entry.state.name}'});
    expect(
      entry.confirmedAt,
      entry.state == WriteState.confirmed ? confirmedAt : null,
    );
  }
  await queue5.close();
  await _checkLegacyV1Migration();
}

const _legacyDbName = 'event_queue_v1_migration_check';
const _legacyIds = [
  '11111111-1111-4111-8111-111111111111',
  '22222222-2222-4222-8222-222222222222',
];

EventQueueDatabase _openLegacy({
  bool seedV1 = false,
}) => EventQueueDatabase.withExecutor(
  driftDatabase(
    name: _legacyDbName,
    native: seedV1
        ? DriftNativeOptions(
            setup: (db) {
              // Raw schema from commit 2fc6f5a, BEFORE Drift opens/migrates.
              // Only this isolated test database is reset on repeated runs.
              db.execute('DROP TABLE IF EXISTS queued_events');
              db.execute('DROP TABLE IF EXISTS rejected_events');
              db.execute('DROP TABLE IF EXISTS sync_queue_counters');
              db.execute('''
                    CREATE TABLE queued_events (
                      id TEXT NOT NULL PRIMARY KEY,
                      event_type TEXT NOT NULL,
                      type_version INTEGER NOT NULL,
                      device_id TEXT NOT NULL,
                      device_time INTEGER NOT NULL,
                      app_version TEXT NOT NULL,
                      correlation_json TEXT,
                      content_json TEXT
                    )
                  ''');
              db.execute('''
                    CREATE TABLE rejected_events (
                      id TEXT NOT NULL PRIMARY KEY,
                      event_type TEXT NOT NULL,
                      type_version INTEGER NOT NULL,
                      reason_code TEXT NOT NULL,
                      rejected_at INTEGER NOT NULL
                    )
                  ''');
              for (final (index, id) in _legacyIds.indexed) {
                // Insertion order is the opposite of device-clock order.
                final time = DateTime.utc(2026, 9, 27, 1 - index);
                db.execute(
                  'INSERT INTO queued_events VALUES (?,?,?,?,?,?,?,?)',
                  [
                    id,
                    'pipeline.self_check',
                    1,
                    'legacy-device',
                    time.millisecondsSinceEpoch ~/ 1000,
                    '0.0.0-v1',
                    '{"recipe_version_id":"ddddddd1-dddd-4ddd-8ddd-dddddddddddd"}',
                    '{"ping":"legacy-$index"}',
                  ],
                );
              }
              db.execute('INSERT INTO rejected_events VALUES (?,?,?,?,?)', [
                '33333333-3333-4333-8333-333333333333',
                'old.unknown_event',
                1,
                'unknown_event_type',
                DateTime.utc(2026, 9, 27).millisecondsSinceEpoch ~/ 1000,
              ]);
              db.execute('PRAGMA user_version = 1');
            },
          )
        : null,
  ),
);

Future<void> _checkLegacyV1Migration() async {
  final migrated = DriftEventQueue(_openLegacy(seedV1: true));
  final beforeReopen = await migrated.entries();
  expect(beforeReopen.map((e) => e.write.id).toList(), _legacyIds);
  expect(beforeReopen.map((e) => e.sequence).toList(), [1, 2]);
  for (final (index, entry) in beforeReopen.indexed) {
    expect(entry.write.ownerId, isNull);
    expect(entry.write.writeType, 'experience.event');
    expect(entry.write.formatVersion, 1);
    expect(entry.write.eventType, 'pipeline.self_check');
    expect(entry.write.typeVersion, 1);
    expect(entry.write.deviceId, 'legacy-device');
    expect(entry.write.appVersion, '0.0.0-v1');
    expect(entry.write.deviceTime, DateTime.utc(2026, 9, 27, 1 - index));
    expect(entry.write.deviceTime.isUtc, isTrue);
    expect(entry.write.content, {'ping': 'legacy-$index'});
    expect(
      entry.write.correlation?.recipeVersionId,
      'ddddddd1-dddd-4ddd-8ddd-dddddddddddd',
    );
    expect(entry.state, WriteState.quarantined);
    expect(entry.reasonCode, 'legacy_owner_unknown');
    // v1 had no delivery attempt/backoff/receipt metadata to invent.
    expect(entry.attempts, 0);
    expect(entry.nextAttemptAt, isNull);
    expect(entry.result, isNull);
    expect(entry.businessRecord, isNull);
    expect(entry.confirmedAt, isNull);
  }
  var diagnostics = await migrated.legacyDiagnostics();
  expect(diagnostics.ownerUnknownCount, 2);
  expect(diagnostics.rejectedCount, 1);
  expect(await migrated.rejectedCount(), 1);
  await migrated.close();

  final reopened = DriftEventQueue(_openLegacy());
  final afterReopen = await reopened.entries();
  expect(afterReopen.length, 2);
  for (final (index, entry) in afterReopen.indexed) {
    expect(entry.write.toJson(), beforeReopen[index].write.toJson());
    expect(entry.sequence, beforeReopen[index].sequence);
    expect(entry.state, WriteState.quarantined);
    expect(entry.reasonCode, 'legacy_owner_unknown');
    expect(entry.attempts, 0);
    expect(entry.nextAttemptAt, isNull);
  }
  const nextOwner = 'ccccccc1-cccc-4ccc-8ccc-cccccccccccc';
  await reopened.retryAccount(nextOwner);
  await reopened.confirm(_legacyIds.first, nextOwner, {
    'resource_type': 'experience_event',
    'resource_id': _legacyIds.first,
  });
  expect(await reopened.entries(ownerId: nextOwner), isEmpty);
  expect(await reopened.pending(ownerId: nextOwner), isEmpty);
  final fresh = _event(
    '44444444-4444-4444-8444-444444444444',
    DateTime.utc(2026, 10, 8),
  );
  await reopened.enqueue(fresh);
  expect((await reopened.entries(ownerId: nextOwner)).single.sequence, 3);
  expect(
    (await reopened.pending(ownerId: nextOwner)).map((e) => e.id).toList(),
    [fresh.id],
  );
  await reopened.clearAccount(nextOwner);
  expect(
    (await reopened.entries()).map((e) => e.write.id).toList(),
    _legacyIds,
  );
  diagnostics = await reopened.legacyDiagnostics();
  // Historical rejections stay count-only, never become a fabricated replay.
  expect(diagnostics.ownerUnknownCount, 2);
  expect(diagnostics.rejectedCount, 1);
  expect(await reopened.rejectedCount(), 1);
  await reopened.close();
}
