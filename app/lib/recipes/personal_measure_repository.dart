import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../auth/session.dart';
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
  int _readGeneration = 0;
  Future<void> _cacheWrites = Future.value();
  final Set<String> pendingIds = {};
  final Map<String, PersonalMeasureOut> deletedMeasures = {};

  /// Explicit withdrawal/deletion only. Never called on ordinary logout.
  Future<void> clearAccount() async {
    _erased = true;
    await _cacheWrites;
    await store.remove(_key);
    await store.remove('measure_history:v1:$accountId');
    pendingIds.clear();
    deletedMeasures.clear();
  }

  Future<void> _persistCache(Future<void> Function() operation) {
    final pending = _cacheWrites.then((_) async {
      if (_canUseAccount) await operation();
    });
    _cacheWrites = pending.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return pending;
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
      // Only causally observed writes are covered, including writes whose
      // confirmation response was lost. Receipt delivery is not freshness.
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
    List<PersonalMeasureOut> base,
  ) async {
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
    final covered = _coveredWrites();
    // A confirmation racing a read still applies unless that read proves the
    // write was already included. Replayed receipts cannot undo covered reads.
    {
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
      if (covered.contains(entry.write.id)) continue;
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
    final generation = ++_readGeneration;
    try {
      var covered = <String>{};
      (List<PersonalMeasureOut>, Set<String>)? snapshot;
      for (var attempt = 0; attempt < 3 && snapshot == null; attempt++) {
        final entries = await _entries();
        final relevant = {for (final entry in entries) entry.write.id};
        // Confirmations received before this attempt causally precede its GET.
        // Existing evidence stays valid while owner history is retained.
        covered = _coveredWrites().intersection(relevant)
          ..addAll(
            entries
                .where((e) => e.state == WriteState.confirmed)
                .map((e) => e.write.id),
          );
        snapshot = await _readSnapshot(relevant.difference(covered).toList());
        // A write enqueued during the read may already be included in the
        // returned snapshot. Expand evidence before admitting its old receipt.
        if (snapshot != null &&
            (await _entries()).any((e) => !relevant.contains(e.write.id))) {
          snapshot = null;
        }
      }
      if (snapshot == null) {
        // A continuously changing collection is not safe to reconcile. Keep the
        // last coherent cache, rather than admit partial causal evidence.
        if (!_canUseAccount) throw StateError('账号已切换');
        if (generation == _readGeneration) offline = true;
        return await _project(cached());
      }
      final values = snapshot.$1;
      covered.addAll(snapshot.$2);
      if (!_canUseAccount) throw StateError('账号已切换');
      // Serialize cache writes as well as fencing stale concurrent requests; an
      // older delayed HTTP response must never replace a newer snapshot.
      await _persistCache(() async {
        if (generation == _readGeneration) await _cache(values, covered);
      });
      if (!_canUseAccount) throw StateError('账号已切换');
      if (generation == _readGeneration) offline = false;
      return await _project(cached());
    } catch (error) {
      if (ApiFailure.from(error).code != 'network') rethrow;
      if (!_canUseAccount) throw StateError('账号已切换');
      if (generation == _readGeneration) offline = true;
      return _project(cached());
    }
  }

  Future<(List<PersonalMeasureOut>, Set<String>)?> _readSnapshot(
    List<String> unknown,
  ) async {
    String? version;
    var requests = 0;
    var values = <PersonalMeasureOut>[];
    final covered = <String>{};
    for (
      var offset = 0;
      offset < unknown.length || offset == 0;
      offset += 100
    ) {
      final chunk = unknown.skip(offset).take(100).toSet();
      Set<String>? observed;
      values = [];
      String? cursor;
      do {
        final response = await api.listPersonalMeasures(
          cursor: cursor,
          headers: {'X-Measure-Known-Writes': chunk.join(',')},
        );
        final currentVersion = response.headers.value(
          'X-Measure-Snapshot-Version',
        );
        if (requests++ == 0) {
          version = currentVersion;
        } else if (version == null || version != currentVersion) {
          // The owner lock proves each response; an identical history version
          // proves the collection did not change BETWEEN pages or ID chunks.
          // Old servers without metadata remain compatible for a single page,
          // but cannot prove a coherent multi-request collection.
          return null;
        }
        final evidence =
            (response.headers.value('X-Measure-Observed-Writes') ?? '')
                .split(',')
                .where(chunk.contains)
                .toSet();
        observed = observed == null
            ? evidence
            : observed.intersection(evidence);
        final page = response.data ?? PagePersonalMeasureOut(items: const []);
        values.addAll(page.items);
        cursor = page.nextCursor;
      } while (cursor != null);
      covered.addAll(observed);
    }
    return (values, covered);
  }

  Future<MeasureInputOut> previewInput(MeasureInputRequest input) async =>
      (await api.previewPersonalMeasureInput(measureInputRequest: input)).data!;

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
    final items = await _project(cached());
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
    final items = await _project(cached());
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
      await _persistCache(() async {
        final previous = store.getString(key);
        final histories = previous == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(jsonDecode(previous) as Map);
        histories[id] = rows;
        await store.setString(key, jsonEncode(histories));
      });
      if (!_canUseAccount) throw StateError('账号已切换');
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
  final session = ref.read(sessionStoreProvider);
  final identity = session.identity;
  if (identity == null) throw StateError('个人量具需要登录');
  return PersonalMeasureRepository(
    api: ref.watch(apiClientProvider).getPersonalMeasuresApi(),
    store: ref.watch(localStoreProvider),
    accountId: accountId,
    queue: ref.watch(eventQueueProvider),
    upload: () => ref.read(eventUploaderProvider).triggerUpload(),
    isCurrentAccount: () =>
        ref.mounted &&
        session.matches(identity) &&
        ref.read(authProvider).value?.id == accountId,
  );
});

final personalMeasuresProvider =
    FutureProvider.autoDispose<List<PersonalMeasureOut>>((ref) {
      final queue = ref.watch(eventQueueProvider);
      final subscription = queue.changes.listen((_) => ref.invalidateSelf());
      ref.onDispose(subscription.cancel);
      return ref.watch(personalMeasureRepositoryProvider).list();
    });
