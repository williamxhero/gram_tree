import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:gramtree_api/gramtree_api.dart' show EventCorrelationIds;

import 'event_queue.dart';
import 'write_registry.dart';

part 'event_queue_mobile.g.dart';

/// Extend the original queue in place. Legacy columns remain for lossless v1
/// migration; new writes carry an immutable generic envelope and delivery state.
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
  TextColumn get ownerId => text().nullable()();
  TextColumn get envelopeJson => text().nullable()();
  IntColumn get enqueueSequence => integer().withDefault(const Constant(0))();
  TextColumn get deliveryState =>
      text().withDefault(const Constant('quarantined'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get reasonCode => text().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get resultJson => text().nullable()();
  TextColumn get businessJson => text().nullable()();
  DateTimeColumn get confirmedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Original refusals had already discarded their payload. Preserve all remaining
/// evidence, quarantined, rather than fabricating a reconstructable envelope.
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

class SyncQueueCounters extends Table {
  IntColumn get id => integer()();
  IntColumn get nextSequence => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [QueuedEvents, RejectedEvents, SyncQueueCounters])
class EventQueueDatabase extends _$EventQueueDatabase {
  EventQueueDatabase() : super(driftDatabase(name: 'event_queue'));
  EventQueueDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(syncQueueCounters).insert(
        SyncQueueCountersCompanion.insert(id: const Value(1), nextSequence: 0),
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        for (final column in [
          queuedEvents.ownerId,
          queuedEvents.envelopeJson,
          queuedEvents.enqueueSequence,
          queuedEvents.deliveryState,
          queuedEvents.attempts,
          queuedEvents.reasonCode,
          queuedEvents.nextAttemptAt,
          queuedEvents.resultJson,
          queuedEvents.businessJson,
          queuedEvents.confirmedAt,
        ]) {
          await m.addColumn(queuedEvents, column);
        }
        await m.createTable(syncQueueCounters);
        // Old insertion order survives even equal/backward device timestamps.
        // No reliable original account evidence exists in v1: never adopt it.
        await customStatement(
          "UPDATE queued_events SET enqueue_sequence = rowid, reason_code = 'legacy_owner_unknown'",
        );
        await customStatement(
          'INSERT INTO sync_queue_counters (id,next_sequence) SELECT 1,coalesce(max(enqueue_sequence),0) FROM queued_events',
        );
      }
    },
  );
}

EventQueue createEventQueue({WriteRegistry? registry}) =>
    DriftEventQueue(EventQueueDatabase(), registry: registry);

class DriftEventQueue implements EventQueue {
  DriftEventQueue(this._db, {WriteRegistry? registry})
    : registry = registry ?? WriteRegistry();
  final EventQueueDatabase _db;
  @override
  final WriteRegistry registry;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> enqueue(
    QueuedEvent event, {
    Map<String, dynamic>? businessRecord,
  }) async {
    event.validateForEnqueue();
    registry.require(event.writeType).validate(event.payload);
    await _db.transaction(() async {
      final previous = await (_db.select(
        _db.queuedEvents,
      )..where((t) => t.id.equals(event.id))).getSingleOrNull();
      if (previous != null) {
        if (!_fromRow(previous).write.sameEnvelope(event)) {
          throw StateError('Immutable write ID reused');
        }
        return;
      }
      final counter = await _db.select(_db.syncQueueCounters).getSingle();
      final sequence = counter.nextSequence + 1;
      await (_db.update(_db.syncQueueCounters)..where((t) => t.id.equals(1)))
          .write(SyncQueueCountersCompanion(nextSequence: Value(sequence)));
      await _db
          .into(_db.queuedEvents)
          .insert(
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
              ownerId: Value(event.ownerId),
              envelopeJson: Value(jsonEncode(event.toJson())),
              enqueueSequence: Value(sequence),
              deliveryState: Value(
                event.ownerId == null ? 'quarantined' : 'pending',
              ),
              reasonCode: Value(
                event.ownerId == null ? 'legacy_owner_unknown' : null,
              ),
              businessJson: Value(
                businessRecord == null ? null : jsonEncode(businessRecord),
              ),
            ),
          );
    });
    _changes.add(null);
  }

  @override
  Future<List<QueueEntry>> entries({String? ownerId}) async {
    final query = _db.select(_db.queuedEvents)
      ..orderBy([(t) => OrderingTerm(expression: t.enqueueSequence)]);
    if (ownerId != null) query.where((t) => t.ownerId.equals(ownerId));
    return (await query.get()).map(_fromRow).toList();
  }

  @override
  Future<void> update(QueueEntry entry) async {
    await _db.transaction(() async {
      final row = await (_db.select(
        _db.queuedEvents,
      )..where((t) => t.id.equals(entry.write.id))).getSingleOrNull();
      // Privacy deletion wins over late network/lifecycle callbacks; confirmed
      // delivery is terminal and must never be demoted by a stale wake/pause.
      if (row == null || row.deliveryState == 'confirmed') return;
      if (row.enqueueSequence != entry.sequence ||
          !_fromRow(row).write.sameEnvelope(entry.write)) {
        throw StateError('Immutable write changed');
      }
      await (_db.update(
        _db.queuedEvents,
      )..where((t) => t.id.equals(entry.write.id))).write(
        QueuedEventsCompanion(
          deliveryState: Value(entry.state.name),
          attempts: Value(entry.attempts),
          reasonCode: Value(entry.reasonCode),
          nextAttemptAt: Value(entry.nextAttemptAt),
          resultJson: Value(
            entry.result == null ? null : jsonEncode(entry.result),
          ),
          businessJson: Value(
            entry.businessRecord == null
                ? null
                : jsonEncode(entry.businessRecord),
          ),
          confirmedAt: Value(entry.confirmedAt),
        ),
      );
    });
    _changes.add(null);
  }

  @override
  Future<void> confirm(
    String id,
    String ownerId,
    Map<String, dynamic> result,
  ) async {
    await _db.transaction(() async {
      final row =
          await (_db.select(_db.queuedEvents)
                ..where((t) => t.id.equals(id) & t.ownerId.equals(ownerId)))
              .getSingleOrNull();
      if (row == null) return;
      final entry = _fromRow(row);
      final business = registry
          .require(entry.write.writeType)
          .applyResult(entry.businessRecord, result);
      await update(
        entry.change(
          state: WriteState.confirmed,
          result: result,
          businessRecord: business,
          confirmedAt: DateTime.now().toUtc(),
        ),
      );
    });
  }

  @override
  Future<void> retryAccount(String ownerId) async {
    await _db.transaction(() async {
      for (final entry in await entries(ownerId: ownerId)) {
        if (entry.state != WriteState.confirmed &&
            entry.state != WriteState.conflict) {
          await update(entry.change(state: WriteState.pending, attempts: 0));
        }
      }
    });
  }

  @override
  Future<void> clearAccount(
    String ownerId, {
    bool experienceOnly = false,
  }) async {
    await _db.transaction(() async {
      final ids = (await entries(ownerId: ownerId))
          .where(
            (e) => !experienceOnly || e.write.writeType == 'experience.event',
          )
          .map((e) => e.write.id);
      await removeAll(ids);
    });
  }

  @override
  Future<List<QueuedEvent>> pending({int? limit, String? ownerId}) async {
    final values = (await entries(ownerId: ownerId))
        .where(
          (e) =>
              e.state != WriteState.confirmed &&
              e.state != WriteState.failed &&
              e.state != WriteState.conflict,
        )
        .map((e) => e.write);
    return (limit == null ? values : values.take(limit)).toList();
  }

  @override
  Future<void> remove(String id) => removeAll([id]);
  @override
  Future<void> removeAll(Iterable<String> ids) async {
    await (_db.delete(
      _db.queuedEvents,
    )..where((t) => t.id.isIn(ids.toList()))).go();
    _changes.add(null);
  }

  @override
  Future<void> reject(String id, {required String reasonCode}) async {
    final row = await (_db.select(
      _db.queuedEvents,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row != null) {
      await update(
        _fromRow(row).change(state: WriteState.failed, reasonCode: reasonCode),
      );
    }
  }

  @override
  Future<int> rejectedCount() async =>
      (await _db.select(_db.rejectedEvents).get()).length +
      (await entries()).where((e) => e.state == WriteState.failed).length;
  @override
  Future<LegacyQueueDiagnostics> legacyDiagnostics() async {
    final unknownCount = _db.queuedEvents.id.count();
    final unknown =
        await (_db.selectOnly(_db.queuedEvents)
              ..addColumns([unknownCount])
              ..where(
                _db.queuedEvents.ownerId.isNull() &
                    _db.queuedEvents.deliveryState.equals('quarantined'),
              ))
            .getSingle();
    final rejectedCount = _db.rejectedEvents.id.count();
    final rejected = await (_db.selectOnly(
      _db.rejectedEvents,
    )..addColumns([rejectedCount])).getSingle();
    return LegacyQueueDiagnostics(
      ownerUnknownCount: unknown.read(unknownCount) ?? 0,
      rejectedCount: rejected.read(rejectedCount) ?? 0,
    );
  }

  @override
  Future<void> clear() async {
    await _db.transaction(() async {
      await _db.delete(_db.queuedEvents).go();
      await _db.delete(_db.rejectedEvents).go();
    });
    _changes.add(null);
  }

  @override
  Future<void> close() async {
    await _db.close();
    await _changes.close();
  }

  QueueEntry _fromRow(QueuedEventRow row) => QueueEntry(
    write: row.envelopeJson == null
        ? QueuedEvent(
            id: row.id,
            eventType: row.eventType,
            typeVersion: row.typeVersion,
            deviceId: row.deviceId,
            deviceTime: row.deviceTime.toUtc(),
            appVersion: row.appVersion,
            ownerId: row.ownerId,
            correlation: row.correlationJson == null
                ? null
                : EventCorrelationIds.fromJson(
                    jsonDecode(row.correlationJson!) as Map<String, dynamic>,
                  ),
            content: row.contentJson == null
                ? null
                : jsonDecode(row.contentJson!) as Map<String, dynamic>,
          )
        : QueuedEvent.fromJson(
            jsonDecode(row.envelopeJson!) as Map<String, dynamic>,
          ),
    sequence: row.enqueueSequence,
    state: WriteState.values.byName(row.deliveryState),
    attempts: row.attempts,
    reasonCode: row.reasonCode,
    nextAttemptAt: row.nextAttemptAt?.toUtc(),
    confirmedAt: row.confirmedAt?.toUtc(),
    result: row.resultJson == null
        ? null
        : jsonDecode(row.resultJson!) as Map<String, dynamic>,
    businessRecord: row.businessJson == null
        ? null
        : jsonDecode(row.businessJson!) as Map<String, dynamic>,
  );
}
