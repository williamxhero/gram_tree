import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart' show EventCorrelationIds;

import 'event_queue_stub.dart'
    if (dart.library.io) 'event_queue_mobile.dart'
    if (dart.library.js_interop) 'event_queue_web.dart';
import 'write_registry.dart';

/// Immutable delivery envelope. Legacy events without reliable ownership are
/// retained in quarantine; they are NEVER assigned to the next signed-in user.
class QueuedEvent {
  QueuedEvent({
    required String id,
    required String eventType,
    required int typeVersion,
    required String deviceId,
    required DateTime deviceTime,
    required String appVersion,
    String? ownerId,
    EventCorrelationIds? correlation,
    Map<String, dynamic>? content,
  }) : this.write(
         id: id,
         ownerId: ownerId,
         deviceTime: deviceTime,
         writeType: 'experience.event',
         payload: {
           'event_type': eventType,
           'type_version': typeVersion,
           'device_id': deviceId,
           'app_version': appVersion,
           'correlation': _correlationJson(correlation),
           'content': content ?? {},
         },
       );

  QueuedEvent.write({
    required this.id,
    required this.ownerId,
    required DateTime deviceTime,
    required this.writeType,
    required Map<String, dynamic> payload,
    List<String> dependencies = const [],
    this.formatVersion = 1,
  }) : deviceTime = deviceTime.toUtc(),
       payload = _freezeMap(payload),
       dependencies = List.unmodifiable(dependencies);

  factory QueuedEvent.fromJson(Map<String, dynamic> json) => QueuedEvent.write(
    id: json['write_id'] as String,
    ownerId: json['owner_id'] as String?,
    deviceTime: DateTime.parse(json['device_time'] as String),
    writeType: json['write_type'] as String,
    payload: Map<String, dynamic>.from(json['payload'] as Map),
    dependencies: List<String>.from(json['dependencies'] as List? ?? []),
    formatVersion: json['format_version'] as int,
  );

  final int formatVersion;
  final String id;
  final String? ownerId;
  final String writeType;
  final DateTime deviceTime;
  final Map<String, dynamic> payload;
  final List<String> dependencies;

  // Compatibility getters for existing experience event producers.
  String get eventType => payload['event_type'] as String? ?? writeType;
  int get typeVersion => payload['type_version'] as int? ?? 1;
  String get deviceId => payload['device_id'] as String? ?? '';
  String get appVersion => payload['app_version'] as String? ?? '';
  Map<String, dynamic>? get content =>
      payload['content'] as Map<String, dynamic>?;
  EventCorrelationIds? get correlation => payload['correlation'] == null
      ? null
      : EventCorrelationIds.fromJson(
          Map<String, dynamic>.from(payload['correlation'] as Map),
        );

  Map<String, dynamic> toJson() => {
    'format_version': formatVersion,
    'write_type': writeType,
    'write_id': id,
    'owner_id': ownerId,
    'device_time': deviceTime.toIso8601String(),
    'payload': payload,
    'dependencies': dependencies,
  };

  bool sameEnvelope(QueuedEvent other) =>
      _canonical(toJson()) == _canonical(other.toJson());

  void validateForEnqueue() {
    if (formatVersion != 1 ||
        !_uuidV4.hasMatch(id) ||
        (ownerId != null && !_uuidV4.hasMatch(ownerId!)) ||
        dependencies.length > 100 ||
        dependencies.toSet().length != dependencies.length ||
        dependencies.any((id) => !_uuidV4.hasMatch(id))) {
      throw ArgumentError('Invalid immutable write envelope');
    }
  }
}

final _uuidV4 = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

Map<String, dynamic> _correlationJson(EventCorrelationIds? correlation) {
  final value = correlation?.toJson() ?? <String, dynamic>{};
  value.removeWhere((key, value) => value == null);
  return value;
}

Map<String, dynamic> _freezeMap(Map<String, dynamic> value) {
  dynamic freeze(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.unmodifiable(
        value.map((key, item) => MapEntry(key as String, freeze(item))),
      );
    }
    if (value is List) return List<dynamic>.unmodifiable(value.map(freeze));
    return value;
  }

  return freeze(jsonDecode(jsonEncode(value))) as Map<String, dynamic>;
}

String _canonical(dynamic value) {
  dynamic sorted(dynamic value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: sorted(value[key])};
    }
    if (value is List) return value.map(sorted).toList();
    return value;
  }

  return jsonEncode(sorted(value));
}

enum WriteState {
  pending,
  uploading,
  deferred,
  loginPaused,
  conflict,
  failed,
  confirmed,
  quarantined,
}

class QueueEntry {
  QueueEntry({
    required this.write,
    required this.sequence,
    required this.state,
    this.attempts = 0,
    this.reasonCode,
    this.nextAttemptAt,
    Map<String, dynamic>? result,
    Map<String, dynamic>? businessRecord,
    this.confirmedAt,
  }) : result = result == null ? null : _freezeMap(result),
       businessRecord = businessRecord == null
           ? null
           : _freezeMap(businessRecord);

  final QueuedEvent write;
  final int sequence;
  final WriteState state;
  final int attempts;
  final String? reasonCode;
  final DateTime? nextAttemptAt;
  final Map<String, dynamic>? result;
  final Map<String, dynamic>? businessRecord;
  final DateTime? confirmedAt;

  bool get needsSync =>
      state != WriteState.confirmed && state != WriteState.quarantined;

  /// Only transient delivery failures may spend a fresh manual retry budget.
  /// Unknown/validation/permission failures are retained, never blind-replayed.
  bool get canRetryDelivery {
    if (state == WriteState.pending) return true;
    if (state == WriteState.deferred) {
      return reasonCode != 'dependency_conflict';
    }
    if (state != WriteState.failed) return false;
    final reason = reasonCode?.split(':').first;
    return const {
      'network_or_server_failure',
      'invalid_or_lost_response',
      'retry_limit_exceeded',
      'dependency_failed',
    }.contains(reason);
  }

  QueueEntry change({
    required WriteState state,
    int? attempts,
    String? reasonCode,
    DateTime? nextAttemptAt,
    Map<String, dynamic>? result,
    Map<String, dynamic>? businessRecord,
    DateTime? confirmedAt,
  }) => QueueEntry(
    write: write,
    sequence: sequence,
    state: state,
    attempts: attempts ?? this.attempts,
    reasonCode: reasonCode,
    nextAttemptAt: nextAttemptAt,
    result: result ?? this.result,
    businessRecord: businessRecord ?? this.businessRecord,
    confirmedAt: confirmedAt ?? this.confirmedAt,
  );
}

/// Resolve retry eligibility against the same owner snapshot. A blocked child
/// cannot bypass a rejected prerequisite or a conflict awaiting user choice.
Iterable<QueueEntry> manualRetryEntries(List<QueueEntry> entries) {
  final byId = {for (final entry in entries) entry.write.id: entry};
  bool eligible(QueueEntry entry, Set<String> visiting) {
    if (!entry.canRetryDelivery || !visiting.add(entry.write.id)) return false;
    for (final id in entry.write.dependencies) {
      final parent = byId[id];
      if (parent == null || parent.state == WriteState.confirmed) continue;
      if (!eligible(parent, {...visiting})) return false;
    }
    return true;
  }

  return entries.where((entry) => eligible(entry, {}));
}

/// Device-level migration evidence, intentionally counts only. There is no
/// reliable owner for these records, so never expose their IDs or content to a
/// signed-in account or include another owner's delivery failures here.
class LegacyQueueDiagnostics {
  const LegacyQueueDiagnostics({
    this.ownerUnknownCount = 0,
    this.rejectedCount = 0,
  });
  final int ownerUnknownCount;
  final int rejectedCount;
}

/// Same queue as SPEC-010.1, now account scoped and registered. Sequence is
/// independent of device time. Confirmation keeps businessRecord and receipt.
abstract class EventQueue {
  WriteRegistry get registry;
  Stream<void> get changes;
  Future<void> enqueue(
    QueuedEvent event, {
    Map<String, dynamic>? businessRecord,
  });
  Future<List<QueueEntry>> entries({String? ownerId});
  Future<void> update(QueueEntry entry);
  Future<void> confirm(
    String id,
    String ownerId,
    Map<String, dynamic> result, {
    DateTime? confirmedAt,
  });
  Future<void> retryAccount(String ownerId);
  Future<void> clearAccount(String ownerId, {bool experienceOnly = false});
  Future<List<QueuedEvent>> pending({int? limit, String? ownerId});
  Future<void> remove(String id);
  Future<void> removeAll(Iterable<String> ids);
  Future<void> reject(String id, {required String reasonCode});
  Future<int> rejectedCount();
  Future<LegacyQueueDiagnostics> legacyDiagnostics();

  /// Explicit privacy withdrawal/deletion only, NEVER ordinary logout.
  Future<void> clear();
  Future<void> close();
}

final writeRegistryProvider = Provider<WriteRegistry>((ref) => WriteRegistry());

final eventQueueProvider = Provider<EventQueue>((ref) {
  final queue = createEventQueue(registry: ref.watch(writeRegistryProvider));
  ref.onDispose(queue.close);
  return queue;
});
