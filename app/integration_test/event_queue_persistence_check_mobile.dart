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
}
