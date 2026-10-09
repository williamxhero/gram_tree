import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../events/event_queue.dart';
import '../events/event_uploader.dart';
import '../storage/local_store.dart';
import '../util/ids.dart';
import 'personal_measure_write.dart';

/// Server reads are cached; each edit and its projection live in ONE queue
/// transaction. Pending projections are derived from retained business records,
/// never separately written into the read-through cache as an "atomic" edit.
class PersonalMeasureRepository {
  PersonalMeasureRepository({
    required this.api,
    required this.store,
    required this.accountId,
    required this.queue,
    required this.upload,
    required this.isCurrentAccount,
  });

  final PersonalMeasuresApi api;
  final LocalStore store;
  final String accountId;
  final EventQueue queue;
  final Future<void> Function() upload;
  final bool Function() isCurrentAccount;
  bool offline = false;
  bool _erased = false;
  final Set<String> pendingIds = {};
  final Map<String, PersonalMeasureOut> deletedMeasures = {};

  /// Explicit withdrawal/deletion only. Never called on ordinary logout.
  Future<void> clearAccount() async {
    _erased = true;
    await store.remove(_key);
    await store.remove('measure_history:v1:$accountId');
    pendingIds.clear();
    deletedMeasures.clear();
  }

  bool get _canUseAccount => !_erased && isCurrentAccount();

  String get _key => 'personal_measures:v1:$accountId';

  List<PersonalMeasureOut> cached() {
    try {
      final encoded = store.getString(_key);
      if (encoded == null) return [];
      final value = jsonDecode(encoded);
      if (value is! Map || value['account_id'] != accountId) return [];
      final items = value['items'];
      if (items is! List) return [];
      return items
          .map(
            (item) => PersonalMeasureOut.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  Future<void> _cache(
    List<PersonalMeasureOut> values,
    Set<String> coveredWrites,
  ) => store.setString(
    _key,
    jsonEncode({
      'account_id': accountId,
      'items': [for (final value in values) value.toJson()],
      // Reads supersede confirmations known BEFORE the HTTP read began. A
      // write confirmed during this read remains a newer retained projection.
      'covered_write_ids': coveredWrites.toList(),
    }),
  );

  Set<String> _coveredWrites() {
    final encoded = store.getString(_key);
    if (encoded == null) return {};
    try {
      return Set<String>.from(
        (jsonDecode(encoded) as Map)['covered_write_ids'] as List? ?? const [],
      );
    } catch (_) {
      return {};
    }
  }

  Future<List<QueueEntry>> _entries() async =>
      (await queue.entries(ownerId: accountId))
          .where((entry) => entry.write.writeType == personalMeasureWriteType)
          .toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));

  Future<List<PersonalMeasureOut>> _project(
    List<PersonalMeasureOut> base, {
    required bool remote,
  }) async {
    final entries = await _entries();
    final values = {for (final item in base) item.id: item.toJson()};
    pendingIds.clear();
    deletedMeasures.clear();
    for (final entry in entries) {
      final projection = entry.businessRecord?['projection'];
      if (entry.write.payload['action'] == 'delete' &&
          projection is Map &&
          (entry.needsSync || projection['deleted'] == true)) {
        final item = PersonalMeasureOut.fromJson(
          Map<String, dynamic>.from(projection),
        );
        deletedMeasures[item.id] = item;
      }
    }
    // The newest confirmation is the last authoritative snapshot received, not
    // the last device timestamp. Server reads supersede all old confirmations.
    if (!remote) {
      final covered = _coveredWrites();
      final confirmed =
          entries
              .where(
                (entry) =>
                    entry.state == WriteState.confirmed &&
                    !covered.contains(entry.write.id),
              )
              .toList()
            ..sort((a, b) {
              final order = (a.confirmedAt ?? a.write.deviceTime).compareTo(
                b.confirmedAt ?? b.write.deviceTime,
              );
              return order == 0 ? a.sequence.compareTo(b.sequence) : order;
            });
      for (final entry in confirmed) {
        final projection = entry.businessRecord?['projection'];
        if (projection is! Map) continue;
        final id = entry.write.payload['resource_id'] as String;
        if (projection['deleted'] == true) {
          values.remove(id);
        } else {
          values[id] = Map<String, dynamic>.from(projection);
        }
      }
    }
    for (final entry in entries.where((entry) => entry.needsSync)) {
      final id = entry.write.payload['resource_id'] as String;
      pendingIds.add(id);
      if (entry.write.payload['action'] == 'delete') {
        values.remove(id);
        continue;
      }
      final projection = entry.businessRecord?['projection'];
      final current =
          values[id] ??
          (projection is Map ? Map<String, dynamic>.from(projection) : null);
      if (current == null) continue;
      values[id] = {
        ...current,
        for (final field in (entry.write.payload['fields'] as Map).entries)
          field.key as String: (field.value as Map)['value'],
      };
    }
    return values.values.map(PersonalMeasureOut.fromJson).toList();
  }

  Future<List<PersonalMeasureOut>> list() async {
    try {
      final covered = {
        for (final entry in await _entries())
          if (entry.state == WriteState.confirmed) entry.write.id,
      };
      final values = <PersonalMeasureOut>[];
      String? cursor;
      do {
        final response = await api.listPersonalMeasures(cursor: cursor);
        final page = response.data ?? PagePersonalMeasureOut(items: const []);
        values.addAll(page.items);
        cursor = page.nextCursor;
      } while (cursor != null);
      if (!_canUseAccount) throw StateError('账号已切换');
      await _cache(values, covered);
      offline = false;
      return await _project(values, remote: true);
    } catch (error) {
      if (ApiFailure.from(error).code != 'network') rethrow;
      offline = true;
      return _project(cached(), remote: false);
    }
  }

  Future<PersonalMeasureOut> create(PersonalMeasureInput input) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final projection = {
      'id': newUuidV4(),
      ...input.toJson(),
      'created_at': now,
      'updated_at': now,
    };
    await _enqueue(
      projection['id'] as String,
      'create',
      input.toJson(),
      projection,
    );
    return PersonalMeasureOut.fromJson(projection);
  }

  Future<PersonalMeasureOut> update(
    String id,
    PersonalMeasureUpdate input,
  ) async {
    final items = await _project(cached(), remote: false);
    final old = items.firstWhere((item) => item.id == id);
    // Generated nullable update models serialize omitted members as null. Our
    // UI has non-null fields, so send only supplied fields that actually changed.
    final fields = input.toJson()
      ..removeWhere(
        (key, value) => value == null || old.toJson()[key] == value,
      );
    if (fields.isEmpty) return old;
    final projection = {
      ...old.toJson(),
      ...fields,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _enqueue(id, 'update', fields, projection, oldValues: old.toJson());
    return PersonalMeasureOut.fromJson(projection);
  }

  Future<void> delete(String id) async {
    final items = await _project(cached(), remote: false);
    final old = items.firstWhere((item) => item.id == id);
    await _enqueue(
      id,
      'delete',
      {'deleted': true},
      {...old.toJson(), 'deleted': true},
      oldValues: {'deleted': false},
    );
  }

  Future<void> _enqueue(
    String id,
    String action,
    Map<String, dynamic> fields,
    Map<String, dynamic> projection, {
    Map<String, dynamic> oldValues = const {},
  }) async {
    if (!_canUseAccount) throw StateError('账号已切换');
    final entries = await _entries();
    if (!_canUseAccount) throw StateError('账号已切换');
    final creation = entries
        .where(
          (entry) =>
              entry.write.payload['resource_id'] == id &&
              entry.write.payload['action'] == 'create',
        )
        .firstOrNull;
    final now = DateTime.now().toUtc();
    await queue.enqueue(
      QueuedEvent.write(
        id: newUuidV4(),
        ownerId: accountId,
        deviceTime: now,
        writeType: personalMeasureWriteType,
        dependencies: action != 'create' && creation != null
            ? [creation.write.id]
            : [],
        payload: {
          'resource_id': id,
          'action': action,
          'fields': {
            for (final field in fields.entries)
              field.key: {
                'value': field.value,
                'device_time': now.toIso8601String(),
              },
          },
        },
      ),
      businessRecord: {'projection': projection, 'old_values': oldValues},
    );
    pendingIds.add(id);
    // Shared uploader owns networking/retry; offline saves return immediately.
    if (_canUseAccount) unawaited(upload());
  }

  Future<List<Map<String, dynamic>>> history(String id) async {
    try {
      final rows = <Map<String, dynamic>>[];
      String? cursor;
      do {
        final response = await api.personalMeasureHistory(
          measureId: id,
          cursor: cursor,
        );
        final page = response.data!;
        rows.addAll(page.items.map((item) => item.toJson()));
        cursor = page.nextCursor;
      } while (cursor != null);
      if (!_canUseAccount) throw StateError('账号已切换');
      final key = 'measure_history:v1:$accountId';
      final previous = store.getString(key);
      final histories = previous == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(previous) as Map);
      histories[id] = rows;
      await store.setString(key, jsonEncode(histories));
      return await _withPendingHistory(id, rows);
    } catch (error) {
      if (ApiFailure.from(error).code != 'network') rethrow;
      if (!_canUseAccount) throw StateError('账号已切换');
      final encoded = store.getString('measure_history:v1:$accountId');
      final histories = encoded == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(encoded) as Map);
      return _withPendingHistory(id, [
        ...((histories[id] as List?) ?? const []).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      ]);
    }
  }

  Future<List<Map<String, dynamic>>> _withPendingHistory(
    String id,
    List<Map<String, dynamic>> rows,
  ) async {
    final known = {
      for (final row in rows) '${row['write_id']}:${row['field']}',
    };
    return [
      ...rows,
      for (final row in await _pendingHistory(id))
        if (!known.contains('${row['write_id']}:${row['field']}')) row,
    ];
  }

  Future<List<Map<String, dynamic>>> _pendingHistory(String id) async => [
    for (final entry in await _entries())
      if (entry.write.payload['resource_id'] == id && entry.needsSync)
        for (final field in (entry.write.payload['fields'] as Map).entries)
          {
            'write_id': entry.write.id,
            'field': field.key,
            'old_value':
                (entry.businessRecord?['old_values'] as Map?)?[field.key],
            'new_value': (field.value as Map)['value'],
            'device_time': (field.value as Map)['device_time'],
            'outcome': 'pending',
          },
  ];
}

final personalMeasureRepositoryProvider = Provider<PersonalMeasureRepository>((
  ref,
) {
  final accountId = ref.watch(authProvider).value?.id;
  if (accountId == null) throw StateError('个人量具需要登录');
  return PersonalMeasureRepository(
    api: ref.watch(apiClientProvider).getPersonalMeasuresApi(),
    store: ref.watch(localStoreProvider),
    accountId: accountId,
    queue: ref.watch(eventQueueProvider),
    upload: () => ref.read(eventUploaderProvider).triggerUpload(),
    isCurrentAccount: () =>
        ref.mounted && ref.read(authProvider).value?.id == accountId,
  );
});

final personalMeasuresProvider =
    FutureProvider.autoDispose<List<PersonalMeasureOut>>((ref) {
      final queue = ref.watch(eventQueueProvider);
      final subscription = queue.changes.listen((_) => ref.invalidateSelf());
      ref.onDispose(subscription.cancel);
      return ref.watch(personalMeasureRepositoryProvider).list();
    });
