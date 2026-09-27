import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:gramtree_api/gramtree_api.dart' show EventCorrelationIds;

import 'event_queue.dart';

part 'event_queue_mobile.g.dart';

/// 待上传事件表：字段和 [QueuedEvent] 一一对应；关联 ID 和内容存成 JSON 文本
/// （项目第一次用 drift；SPEC-013.3 通用写入队列会照这个模式再加别的表，不是重新设计）。
@DataClassName('QueuedEventRow')
class QueuedEvents extends Table {
  TextColumn get id => text()();
  TextColumn get eventType => text().named('event_type')();
  IntColumn get typeVersion => integer().named('type_version')();
  TextColumn get deviceId => text().named('device_id')();
  DateTimeColumn get deviceTime => dateTime().named('device_time')();
  TextColumn get appVersion => text().named('app_version')();
  TextColumn get correlationJson =>
      text().named('correlation_json').nullable()();
  TextColumn get contentJson => text().named('content_json').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 拒收区（票 5 / #73）：服务端答复"拒收"的事件从 [QueuedEvents] 挪到这里，
/// 不再参与 [DriftEventQueue.pending]/上传。不存内容，只留诊断需要的字段。
@DataClassName('RejectedEventRow')
class RejectedEvents extends Table {
  TextColumn get id => text()();
  TextColumn get eventType => text().named('event_type')();
  IntColumn get typeVersion => integer().named('type_version')();
  TextColumn get reasonCode => text().named('reason_code')();
  DateTimeColumn get rejectedAt => dateTime().named('rejected_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [QueuedEvents, RejectedEvents])
class EventQueueDatabase extends _$EventQueueDatabase {
  /// 手机端真正落盘的位置：`getApplicationDocumentsDirectory()` 下的
  /// `event_queue.sqlite`（drift_flutter 的默认行为）。
  EventQueueDatabase() : super(driftDatabase(name: 'event_queue'));

  /// 测试专用：传入指定的连接（比如指向临时文件的 [NativeDatabase]），
  /// 用来验证“杀进程重开后数据还在”。
  EventQueueDatabase.withExecutor(super.executor);

  // 加了 RejectedEvents 表（票 5 / #73），但整个事件管道还没有发布给真实用户
  // 数据，不需要 onUpgrade：schemaVersion 维持 1，新装的 App 直接按最新表结构建库。
  @override
  int get schemaVersion => 1;
}

/// 手机端实现：真的落盘，不是替身。
EventQueue createEventQueue() => DriftEventQueue(EventQueueDatabase());

class DriftEventQueue implements EventQueue {
  DriftEventQueue(this._db);

  final EventQueueDatabase _db;

  @override
  Future<void> enqueue(QueuedEvent event) {
    return _db.into(_db.queuedEvents).insertOnConflictUpdate(_toRow(event));
  }

  @override
  Future<List<QueuedEvent>> pending({int? limit}) async {
    final query = _db.select(_db.queuedEvents)
      ..orderBy([(t) => OrderingTerm(expression: t.deviceTime)]);
    if (limit != null) query.limit(limit);
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> remove(String id) =>
      (_db.delete(_db.queuedEvents)..where((t) => t.id.equals(id))).go();

  @override
  Future<void> removeAll(Iterable<String> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) return;
    await (_db.delete(_db.queuedEvents)..where((t) => t.id.isIn(idList))).go();
  }

  @override
  Future<void> reject(String id, {required String reasonCode}) async {
    await _db.transaction(() async {
      final row = await (_db.select(
        _db.queuedEvents,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null) return; // 已经不在队列里，什么都不做（安静忽略）
      await _db
          .into(_db.rejectedEvents)
          .insertOnConflictUpdate(
            RejectedEventsCompanion.insert(
              id: row.id,
              eventType: row.eventType,
              typeVersion: row.typeVersion,
              reasonCode: reasonCode,
              rejectedAt: DateTime.now().toUtc(),
            ),
          );
      await (_db.delete(_db.queuedEvents)..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Future<int> rejectedCount() async {
    final rows = await _db.select(_db.rejectedEvents).get();
    return rows.length;
  }

  @override
  Future<void> clear() async {
    await _db.transaction(() async {
      await _db.delete(_db.queuedEvents).go();
      await _db.delete(_db.rejectedEvents).go();
    });
  }

  @override
  Future<void> close() => _db.close();

  QueuedEventsCompanion _toRow(QueuedEvent event) =>
      QueuedEventsCompanion.insert(
        id: event.id,
        eventType: event.eventType,
        typeVersion: event.typeVersion,
        deviceId: event.deviceId,
        deviceTime: event.deviceTime,
        appVersion: event.appVersion,
        correlationJson: Value(
          event.correlation == null
              ? null
              : jsonEncode(event.correlation!.toJson()),
        ),
        contentJson: Value(
          event.content == null ? null : jsonEncode(event.content),
        ),
      );

  QueuedEvent _fromRow(QueuedEventRow row) => QueuedEvent(
    id: row.id,
    eventType: row.eventType,
    typeVersion: row.typeVersion,
    deviceId: row.deviceId,
    // drift 默认把 DateTime 存成不带时区的 unix 时间戳，读回来的 DateTime 瞬间
    // 是对的，但 isUtc 标记会丢（变回 false/"本地时间"）；序列化成请求体的
    // ISO 8601 字符串因此会漏掉时区后缀，被服务端的 Timestamp 校验拒收
    // （`device_time: Input should have timezone info`）。写入前已经是 UTC
    // （event_recorder.dart 生成时就 `.toUtc()` 了），这里 `.toUtc()` 只是
    // 把标记转回来，不改变实际时刻。
    deviceTime: row.deviceTime.toUtc(),
    appVersion: row.appVersion,
    correlation: row.correlationJson == null
        ? null
        : EventCorrelationIds.fromJson(
            jsonDecode(row.correlationJson!) as Map<String, dynamic>,
          ),
    content: row.contentJson == null
        ? null
        : jsonDecode(row.contentJson!) as Map<String, dynamic>,
  );
}
