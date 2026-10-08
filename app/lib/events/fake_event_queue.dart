import 'dart:async';

import 'event_queue.dart';
import 'write_registry.dart';

/// In-memory web/test adapter with the same ownership and immutability rules.
class FakeEventQueue implements EventQueue {
  FakeEventQueue({WriteRegistry? registry})
    : registry = registry ?? WriteRegistry();

  @override
  final WriteRegistry registry;
  final Map<String, QueueEntry> _entries = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _sequence = 0;

  @override
  Stream<void> get changes => _changes.stream;

  List<QueuedEvent> get items => _entries.values
      .where(
        (e) => e.state != WriteState.confirmed && e.state != WriteState.failed,
      )
      .map((e) => e.write)
      .toList();
  List<QueuedEvent> get rejectedItems => _entries.values
      .where((e) => e.state == WriteState.failed)
      .map((e) => e.write)
      .toList();

  @override
  Future<void> enqueue(
    QueuedEvent event, {
    Map<String, dynamic>? businessRecord,
  }) async {
    event.validateForEnqueue();
    registry.require(event.writeType).validate(event.payload);
    final existing = _entries[event.id];
    if (existing != null) {
      if (!existing.write.sameEnvelope(event)) {
        throw StateError('Immutable write ID reused');
      }
      return;
    }
    _entries[event.id] = QueueEntry(
      write: event,
      sequence: ++_sequence,
      state: event.ownerId == null
          ? WriteState.quarantined
          : WriteState.pending,
      reasonCode: event.ownerId == null ? 'legacy_owner_unknown' : null,
      businessRecord: businessRecord,
    );
    _changes.add(null);
  }

  @override
  Future<List<QueueEntry>> entries({String? ownerId}) async =>
      _entries.values
          .where((e) => ownerId == null || e.write.ownerId == ownerId)
          .toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));

  @override
  Future<void> update(QueueEntry entry) async {
    final existing = _entries[entry.write.id];
    // A late response/state update cannot recreate privacy-deleted content or
    // demote a durable confirmation after a concurrent logout/reconnect wake.
    if (existing == null) return;
    if (existing.state == WriteState.confirmed) return;
    if (!existing.write.sameEnvelope(entry.write) ||
        existing.sequence != entry.sequence) {
      throw StateError('Immutable write changed');
    }
    _entries[entry.write.id] = entry;
    _changes.add(null);
  }

  @override
  Future<void> confirm(
    String id,
    String ownerId,
    Map<String, dynamic> result,
  ) async {
    final entry = _entries[id];
    if (entry == null || entry.write.ownerId != ownerId) return;
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
  }

  @override
  Future<void> retryAccount(String ownerId) async {
    for (final entry in await entries(ownerId: ownerId)) {
      if (entry.state != WriteState.confirmed &&
          entry.state != WriteState.conflict) {
        await update(entry.change(state: WriteState.pending, attempts: 0));
      }
    }
  }

  @override
  Future<void> clearAccount(
    String ownerId, {
    bool experienceOnly = false,
  }) async {
    _entries.removeWhere(
      (id, entry) =>
          entry.write.ownerId == ownerId &&
          (!experienceOnly || entry.write.writeType == 'experience.event'),
    );
    _changes.add(null);
  }

  @override
  Future<List<QueuedEvent>> pending({int? limit, String? ownerId}) async {
    final pending = (await entries(ownerId: ownerId))
        .where(
          (e) =>
              e.state != WriteState.confirmed &&
              e.state != WriteState.failed &&
              e.state != WriteState.conflict,
        )
        .map((e) => e.write);
    return (limit == null ? pending : pending.take(limit)).toList();
  }

  @override
  Future<void> remove(String id) => removeAll([id]);
  @override
  Future<void> removeAll(Iterable<String> ids) async {
    for (final id in ids) {
      _entries.remove(id);
    }
    _changes.add(null);
  }

  @override
  Future<void> reject(String id, {required String reasonCode}) async {
    final entry = _entries[id];
    if (entry != null) {
      await update(
        entry.change(state: WriteState.failed, reasonCode: reasonCode),
      );
    }
  }

  @override
  Future<int> rejectedCount() async => rejectedItems.length;
  @override
  Future<void> clear() async {
    _entries.clear();
    _changes.add(null);
  }

  @override
  Future<void> close() => _changes.close();
}
