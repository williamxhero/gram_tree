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

@DriftDatabase(tables: [QueuedEvents])
class EventQueueDatabase extends _$EventQueueDatabase {
  /// 手机端真正落盘的位置：`getApplicationDocumentsDirectory()` 下的
  /// `event_queue.sqlite`（drift_flutter 的默认行为）。
  EventQueueDatabase() : super(driftDatabase(name: 'event_queue'));

  /// 测试专用：传入指定的连接（比如指向临时文件的 [NativeDatabase]），
  /// 用来验证“杀进程重开后数据还在”。
  EventQueueDatabase.withExecutor(super.executor);

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
    deviceTime: row.deviceTime,
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
