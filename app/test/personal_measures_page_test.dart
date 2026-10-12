import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/events/event_uploader.dart';
import 'package:gram_tree/events/event_queue.dart';
import 'package:gram_tree/events/fake_event_queue.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';
import 'settings_test.dart' show openSettings;

import 'package:gram_tree/storage/local_store.dart';
import 'package:gram_tree/storage/secure_store.dart';

// Model direct read consumers (e.g. recipe display) that do not subscribe to
// queue changes: causal correctness must not depend on reactive invalidation.
class _SnapshotOnlyQueue extends FakeEventQueue {
  @override
  Stream<void> get changes => const Stream.empty();
}

class _DelayedMeasureCache extends MemoryLocalStore {
  _DelayedMeasureCache() : super(consentedStore());
  String? delayedPrefix;
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> setString(String key, String value) async {
    if (delayedPrefix != null && key.startsWith(delayedPrefix!)) {
      delayedPrefix = null;
      started.complete();
      await release.future;
    }
    await super.setString(key, value);
  }
}

class _ObservedMeasureServer extends FakeServer {
  final observedWrites = <String>{};
  int snapshotVersion = 0;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.method == 'GET' && options.path == '/v1/me/measures') {
      final requested =
          (options.headers['X-Measure-Known-Writes'] as String? ?? '').split(
            ',',
          );
      options.extra['measure_snapshot_version'] = snapshotVersion.toString();
      options.extra['observed_measure_snapshot'] = requested
          .where(observedWrites.contains)
          .join(',');
    }
    await super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final snapshot = response.requestOptions.extra['observed_measure_snapshot'];
    if (snapshot is String) {
      response.headers.set('X-Measure-Observed-Writes', snapshot);
      response.headers.set(
        'X-Measure-Snapshot-Version',
        response.requestOptions.extra['measure_snapshot_version'] as String,
      );
    }
    handler.next(response);
  }
}

class _MeasureServer {
  _MeasureServer(FakeServer server) {
    server.on(
      'GET',
      '/v1/me/measures',
      (_) => (
        200,
        {
          'items': values.values
              .where((value) => value['deleted'] != true)
              .toList(),
          'next_cursor': null,
        },
      ),
    );
    server.on('POST', '/v1/sync/writes', (request) async {
      final results = <Map<String, dynamic>>[];
      for (final raw in (request.body as Map)['writes'] as List) {
        final write = Map<String, dynamic>.from(raw as Map);
        if (write['write_type'] != 'personal_measure.change') {
          results.add({
            'write_id': write['write_id'],
            'status': 'confirmed',
            'confirmed_at': '2026-10-08T10:11:12Z',
            'result': {
              'resource_type': 'experience.event',
              'resource_id': write['write_id'],
            },
          });
          continue;
        }
        final previous = receipts[write['write_id']];
        if (previous != null) {
          replayStarted?.complete();
          replayStarted = null;
          if (replayBarrier != null) await replayBarrier!.future;
          results.add({...previous, 'status': 'already_processed'});
          continue;
        }
        final payload = write['payload'] as Map;
        final id = payload['resource_id'] as String;
        final old = values[id];
        final fields = payload['fields'] as Map;
        final now = '2026-10-09T00:00:00Z';
        final projection = <String, dynamic>{
          'id': id,
          'created_at': now,
          'updated_at': now,
          ...?old,
          for (final field in fields.entries)
            field.key as String: (field.value as Map)['value'],
        };
        // A deliberately precomputed winner fixture checks that a rejected
        // optimistic name is replaced, rather than recomputing adjudication.
        if (authoritativeName != null && payload['action'] == 'update') {
          projection['name'] = authoritativeName;
        }
        values[id] = projection;
        server.on(
          'GET',
          '/v1/me/measures/$id/history',
          (_) => (
            200,
            {
              'items': [
                {
                  'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
                  'write_id': write['write_id'],
                  'field': 'name',
                  'device_time': write['device_time'],
                  'old_value': old?['name'],
                  'new_value':
                      (fields['name'] as Map?)?['value'] ?? projection['name'],
                  'outcome': authoritativeName == null ? 'won' : 'lost',
                },
              ],
              'next_cursor': null,
            },
          ),
        );
        results.add({
          'write_id': write['write_id'],
          'status': 'confirmed',
          'confirmed_at': now,
          'result': {
            'resource_type': 'personal_measure',
            'resource_id': id,
            'values': {
              ...projection,
              'applied': authoritativeName == null,
              'field_outcomes': {
                for (final field in fields.keys)
                  field: authoritativeName == null ? 'won' : 'lost',
              },
            },
          },
        });
        receipts[write['write_id'] as String] = results.last;
        if (server is _ObservedMeasureServer) {
          server.observedWrites.add(write['write_id'] as String);
          server.snapshotVersion++;
        }
      }
      if (loseNextResponse &&
          results.any(
            (result) => result['result']['resource_type'] == 'personal_measure',
          )) {
        loseNextResponse = false;
        return FakeServer.error(
          503,
          'response_lost',
          'Response lost after commit',
        );
      }
      return (200, {'results': results});
    });
  }
  final values = <String, Map<String, dynamic>>{};
  final receipts = <String, Map<String, dynamic>>{};
  bool loseNextResponse = false;
  Completer<void>? replayBarrier;
  Completer<void>? replayStarted;
  String? authoritativeName;
}

void main() {
  testWidgets('user can create, edit, and delete a personal measure', (
    tester,
  ) async {
    final server = FakeServer();
    final measures = _MeasureServer(server);
    final env = TestEnv.signedIn(server: server);
    await pumpApp(tester, env: env);
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('measure-add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('measure-name')), '白瓷勺');
    await tester.enterText(
      find.byKey(const ValueKey('measure-capacity')),
      '15',
    );
    await tester.tap(find.byKey(const ValueKey('measure-save')));
    await tester.pumpAndSettle();
    expect(find.text('白瓷勺'), findsOneWidget);
    expect(find.textContaining('15'), findsOneWidget);
    final id = measures.values.keys.single;

    await tester.tap(find.byKey(ValueKey('measure-$id')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('measure-name')), '大白瓷勺');
    await tester.enterText(
      find.byKey(const ValueKey('measure-capacity')),
      '18',
    );
    await tester.tap(find.byKey(const ValueKey('measure-save')));
    await tester.pumpAndSettle();
    expect(find.text('大白瓷勺'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('measure-delete-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(find.text('还没有登记量具'), findsOneWidget);
  });

  testWidgets('refreshes measures changed on another device after restart', (
    tester,
  ) async {
    final server = FakeServer();
    var name = '白瓷勺';
    server.on(
      'GET',
      '/v1/me/measures',
      (_) => (
        200,
        {
          'items': [
            {
              'id': '88888888-8888-4888-8888-888888888888',
              'name': name,
              'kind': 'spoon',
              'capacity_ml': 15,
              'created_at': '2026-10-02T00:00:00Z',
              'updated_at': '2026-10-02T00:00:00Z',
            },
          ],
          'next_cursor': null,
        },
      ),
    );
    final env = TestEnv.signedIn(server: server);
    await pumpApp(tester, env: env);
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
    await tester.pumpAndSettle();
    expect(find.text('白瓷勺'), findsOneWidget);

    name = '另一设备量具';
    await restartApp(tester, env);
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
    await tester.pumpAndSettle();
    expect(find.text('另一设备量具'), findsOneWidget);
    expect(find.text('白瓷勺'), findsNothing);
  });

  testWidgets('pull to refresh shows measures changed on another device', (
    tester,
  ) async {
    final server = FakeServer();
    var name = '白瓷勺';
    server.on(
      'GET',
      '/v1/me/measures',
      (_) => (
        200,
        {
          'items': [
            {
              'id': '88888888-8888-4888-8888-888888888888',
              'name': name,
              'kind': 'spoon',
              'capacity_ml': 15,
              'created_at': '2026-10-02T00:00:00Z',
              'updated_at': '2026-10-02T00:00:00Z',
            },
          ],
          'next_cursor': null,
        },
      ),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
    await tester.pumpAndSettle();
    expect(find.text('白瓷勺'), findsOneWidget);

    name = '改名后的勺';
    await tester.fling(find.text('白瓷勺'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(find.text('改名后的勺'), findsOneWidget);
    expect(find.text('白瓷勺'), findsNothing);
  });

  testWidgets('offline page reads account-scoped cached measures', (
    tester,
  ) async {
    final local = MemoryLocalStore(consentedStore());
    await local.setString(
      'personal_measures:v1:${testUser().id}',
      jsonEncode({
        'account_id': testUser().id,
        'items': [
          {
            'id': '77777777-7777-4777-8777-777777777777',
            'name': '离线小碗',
            'kind': 'bowl',
            'capacity_ml': 300,
            'created_at': '2026-10-02T00:00:00Z',
            'updated_at': '2026-10-02T00:00:00Z',
          },
        ],
      }),
    );
    await pumpApp(tester, env: TestEnv.signedIn(local: local, offline: true));
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
    await tester.pumpAndSettle();
    expect(find.text('离线小碗'), findsOneWidget);
    expect(find.textContaining('离线：正在使用已缓存'), findsOneWidget);
    expect(find.byKey(const ValueKey('measure-add')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('measure-add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('measure-name')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('measure-name')), '离线新勺');
    await tester.enterText(
      find.byKey(const ValueKey('measure-capacity')),
      '20',
    );
    await tester.tap(find.byKey(const ValueKey('measure-save')));
    await tester.pumpAndSettle();
    expect(find.text('离线新勺'), findsOneWidget);
    expect(find.text('待同步'), findsOneWidget);
  });

  testWidgets(
    'offline edit survives restart and losing optimistic value becomes authoritative with readable history',
    (tester) async {
      final server = FakeServer();
      final measures = _MeasureServer(server);
      const id = '88888888-8888-4888-8888-888888888888';
      measures.values[id] = {
        'id': id,
        'name': '原始勺',
        'kind': 'spoon',
        'capacity_ml': 15,
        'created_at': '2026-10-08T00:00:00Z',
        'updated_at': '2026-10-08T00:00:00Z',
      };
      final env = TestEnv.signedIn(server: server);
      await pumpApp(tester, env: env);
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
      await tester.pumpAndSettle();
      var container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).last),
      );
      container.read(offlineSimulationProvider.notifier).set(true);
      await tester.tap(find.byKey(const ValueKey('measure-$id')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('measure-name')),
        '离线乐观勺',
      );
      await tester.tap(find.byKey(const ValueKey('measure-save')));
      await tester.pumpAndSettle();
      expect(find.text('离线乐观勺'), findsOneWidget);
      expect(find.text('待同步'), findsOneWidget);
      // The restarted app uses the same retained queue, but has no live UI state.
      final offlineEnv = TestEnv(
        server: server,
        local: env.local,
        secure: env.secure,
        eventQueue: env.eventQueue,
        offline: true,
      );
      await restartApp(tester, offlineEnv);
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
      await tester.pumpAndSettle();
      expect(find.text('离线乐观勺'), findsOneWidget);
      expect(find.text('待同步'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('measure-history-$id')));
      await tester.pumpAndSettle();
      expect(find.textContaining('名称：原始勺 → 离线乐观勺'), findsOneWidget);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      measures.authoritativeName = '另一设备获胜勺';
      container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).last),
      );
      container.read(offlineSimulationProvider.notifier).set(false);
      await tester.runAsync(
        () => container.read(eventUploaderProvider).networkRestored(),
      );
      await tester.pumpAndSettle();
      expect(find.text('另一设备获胜勺'), findsOneWidget);
      expect(find.text('离线乐观勺'), findsNothing);
      expect(find.text('待同步'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('measure-history-$id')));
      await tester.pumpAndSettle();
      expect(find.textContaining('未生效：另一设备的较新修改优先'), findsOneWidget);
      expect(find.textContaining('离线乐观勺'), findsOneWidget);
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();
      // Remote refresh supersedes retained confirmations, including offline reads.
      measures.values[id] = {...measures.values[id]!, 'name': '后来远端修改'};
      await tester.fling(find.text('另一设备获胜勺'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(find.text('后来远端修改'), findsOneWidget);
      container.read(offlineSimulationProvider.notifier).set(true);
      await tester.fling(find.text('后来远端修改'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(find.text('后来远端修改'), findsOneWidget);
      expect(find.text('另一设备获胜勺'), findsNothing);
    },
  );

  for (final deleted in [false, true]) {
    testWidgets(
      'lost receipt replay does not undo authoritative ${deleted ? 'deletion' : 'newer value'} offline',
      (tester) async {
        final server = _ObservedMeasureServer();
        final measures = _MeasureServer(server);
        const id = '88888888-8888-4888-8888-888888888888';
        measures.values[id] = {
          'id': id,
          'name': '原始勺',
          'kind': 'spoon',
          'capacity_ml': 15,
          'created_at': '2026-10-08T00:00:00Z',
          'updated_at': '2026-10-08T00:00:00Z',
        };
        final env = TestEnv.signedIn(server: server);
        await pumpApp(tester, env: env);
        await tester.tap(find.text('我的'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(Scaffold).last),
        );
        measures.loseNextResponse = true;
        await tester.tap(find.byKey(const ValueKey('measure-$id')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('measure-name')),
          '旧确认勺',
        );
        await tester.tap(find.byKey(const ValueKey('measure-save')));
        await tester.pumpAndSettle();
        if (deleted) {
          measures.values.remove(id);
        } else {
          measures.values[id] = {...measures.values[id]!, 'name': '另一设备新勺'};
        }
        // An authoritative read happens while the committed write's delivery
        // still awaits its lost confirmation.
        await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
        await tester.pumpAndSettle();
        final started = Completer<void>();
        final barrier = Completer<void>();
        measures.replayStarted = started;
        measures.replayBarrier = barrier;
        unawaited(container.read(eventUploaderProvider).networkRestored());
        await tester.pumpAndSettle();
        expect(started.isCompleted, isTrue);
        container.read(offlineSimulationProvider.notifier).set(true);
        barrier.complete();
        await tester.pumpAndSettle();
        expect(find.text('旧确认勺'), findsNothing);
        if (deleted) {
          expect(find.text('还没有登记量具'), findsOneWidget);
          expect(find.byKey(const ValueKey('measure-$id')), findsNothing);
        } else {
          expect(find.text('另一设备新勺'), findsOneWidget);
        }
      },
    );
  }

  testWidgets(
    'confirmation during in-flight GET survives the older response offline',
    (tester) async {
      final server = _ObservedMeasureServer();
      final measures = _MeasureServer(server);
      const id = '88888888-8888-4888-8888-888888888888';
      measures.values[id] = {
        'id': id,
        'name': '读取前旧勺',
        'kind': 'spoon',
        'capacity_ml': 15,
        'created_at': '2026-10-08T00:00:00Z',
        'updated_at': '2026-10-08T00:00:00Z',
      };
      final env = TestEnv.signedIn(server: server);
      await pumpApp(tester, env: env);
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).last),
      );
      container.read(offlineSimulationProvider.notifier).set(true);
      await tester.tap(find.byKey(const ValueKey('measure-$id')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('measure-name')),
        '读取中确认新勺',
      );
      await tester.tap(find.byKey(const ValueKey('measure-save')));
      await tester.pumpAndSettle();
      final started = Completer<void>();
      final barrier = Completer<void>();
      var holdNext = true;
      server.on('GET', '/v1/me/measures', (_) async {
        final snapshot = [
          for (final row in measures.values.values)
            Map<String, dynamic>.from(row),
        ];
        if (holdNext) {
          holdNext = false;
          started.complete();
          await barrier.future;
        }
        return (200, {'items': snapshot, 'next_cursor': null});
      });
      container.read(offlineSimulationProvider.notifier).set(false);
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pump(const Duration(milliseconds: 100));
      expect(started.isCompleted, isTrue);
      await tester.runAsync(
        () => container.read(eventUploaderProvider).networkRestored(),
      );
      await tester.pump(const Duration(milliseconds: 100));
      container.read(offlineSimulationProvider.notifier).set(true);
      barrier.complete();
      await tester.pumpAndSettle();
      expect(find.text('读取中确认新勺'), findsOneWidget);
      expect(find.text('读取前旧勺'), findsNothing);
      expect(find.text('待同步'), findsNothing);
    },
  );

  testWidgets(
    'changing collection between bounded ID chunks restarts before reconciling',
    (tester) async {
      final server = _ObservedMeasureServer();
      const id = '88888888-8888-4888-8888-888888888888';
      final row = {
        'id': id,
        'name': '分块远端获胜勺',
        'kind': 'spoon',
        'capacity_ml': 15,
        'created_at': '2026-10-08T00:00:00Z',
        'updated_at': '2026-10-08T00:00:00Z',
      };
      final local = MemoryLocalStore(consentedStore());
      await local.setString(
        'personal_measures:v1:${testUser().id}',
        jsonEncode({
          'account_id': testUser().id,
          'items': [row],
        }),
      );
      final env = TestEnv.signedIn(server: server, local: local, offline: true);
      for (var i = 1; i <= 101; i++) {
        final writeId =
            '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}';
        server.observedWrites.add(writeId);
        await env.eventQueue.enqueue(
          QueuedEvent.write(
            id: writeId,
            ownerId: testUser().id,
            deviceTime: DateTime.utc(2026, 10, 8),
            writeType: 'personal_measure.change',
            payload: {
              'resource_id': id,
              'action': 'update',
              'fields': {
                'name': {
                  'value': '分块旧乐观勺',
                  'device_time': '2026-10-08T00:00:00Z',
                },
              },
            },
          ),
          businessRecord: {
            'projection': {...row, 'name': '分块旧乐观勺'},
          },
        );
      }
      final allWrites = server.observedWrites.toSet();
      server.observedWrites.clear();
      server.on(
        'POST',
        '/v1/sync/writes',
        (_) => FakeServer.error(503, 'network', 'Confirmation unavailable'),
      );
      var reads = 0;
      server.on('GET', '/v1/me/measures', (_) {
        if (++reads == 1) {
          server.observedWrites.addAll(allWrites);
          server.snapshotVersion++;
        }
        return (
          200,
          {
            'items': [row],
            'next_cursor': null,
          },
        );
      });
      await pumpApp(tester, env: env);
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
      await tester.pumpAndSettle();
      expect(find.text('分块旧乐观勺'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).last),
      );
      container.read(offlineSimulationProvider.notifier).set(false);
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(find.text('分块远端获胜勺'), findsOneWidget);
      expect(find.text('分块旧乐观勺'), findsNothing);
      expect(reads, greaterThanOrEqualTo(4)); // Mixed chunks must be retried; queue progress may cause additional reads.
      for (final request in server.calls('GET', '/v1/me/measures')) {
        expect(
          (request.headers['X-Measure-Known-Writes'] as String)
              .split(',')
              .length,
          lessThanOrEqualTo(100),
        );
      }
      container.read(offlineSimulationProvider.notifier).set(true);
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(find.text('分块远端获胜勺'), findsOneWidget);
    },
  );

  testWidgets(
    'changing paginated snapshot restarts and retains authoritative deletion offline',
    (tester) async {
      final server = _ObservedMeasureServer();
      const id = '88888888-8888-4888-8888-888888888888';
      final row = {
        'id': id,
        'name': '分页旧乐观勺',
        'kind': 'spoon',
        'capacity_ml': 15,
        'created_at': '2026-10-08T00:00:00Z',
        'updated_at': '2026-10-08T00:00:00Z',
      };
      final env = TestEnv.signedIn(server: server, offline: true);
      const writeId = '00000000-0000-4000-8000-000000000001';
      await env.eventQueue.enqueue(
        QueuedEvent.write(
          id: writeId,
          ownerId: testUser().id,
          deviceTime: DateTime.utc(2026, 10, 8),
          writeType: 'personal_measure.change',
          payload: {
            'resource_id': id,
            'action': 'create',
            'fields': {
              'name': {
                'value': '分页旧乐观勺',
                'device_time': '2026-10-08T00:00:00Z',
              },
            },
          },
        ),
        businessRecord: {'projection': row},
      );
      server.on(
        'POST',
        '/v1/sync/writes',
        (_) => FakeServer.error(503, 'network', 'Confirmation unavailable'),
      );
      var reads = 0;
      server.on('GET', '/v1/me/measures', (_) {
        reads++;
        if (reads == 1) {
          server.observedWrites.add(writeId);
          server.snapshotVersion++;
          return (200, {'items': [], 'next_cursor': 'page2'});
        }
        return (200, {'items': [], 'next_cursor': null});
      });
      await pumpApp(tester, env: env);
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
      await tester.pumpAndSettle();
      expect(find.text('分页旧乐观勺'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).last),
      );
      container.read(offlineSimulationProvider.notifier).set(false);
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(reads, greaterThanOrEqualTo(3));
      expect(find.text('分页旧乐观勺'), findsNothing);
      expect(find.text('还没有登记量具'), findsOneWidget);
      container.read(offlineSimulationProvider.notifier).set(true);
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(find.text('分页旧乐观勺'), findsNothing);
      expect(find.text('还没有登记量具'), findsOneWidget);
    },
  );

  testWidgets(
    'resolved history title and data disappear after same-owner new login generation',
    (tester) async {
      final server = FakeServer();
      final measures = _MeasureServer(server);
      const id = '88888888-8888-4888-8888-888888888888';
      measures.values[id] = {
        'id': id,
        'name': '私密历史勺',
        'kind': 'spoon',
        'capacity_ml': 15,
        'created_at': '2026-10-08T00:00:00Z',
        'updated_at': '2026-10-08T00:00:00Z',
      };
      server.on(
        'GET',
        '/v1/me/measures/$id/history',
        (_) => (
          200,
          {
            'items': [
              {
                'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
                'write_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
                'field': 'name',
                'device_time': '2026-10-08T00:00:00Z',
                'old_value': '先前私密名称',
                'new_value': '私密历史勺',
                'outcome': 'won',
              },
            ],
            'next_cursor': null,
          },
        ),
      );
      final env = TestEnv.signedIn(server: server);
      await pumpApp(tester, env: env);
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('measure-history-$id')));
      await tester.pumpAndSettle();
      expect(find.text('私密历史勺 · 修改历史'), findsOneWidget);
      expect(find.textContaining('先前私密名称'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AlertDialog)),
      );
      await container
          .read(sessionStoreProvider)
          .save(TokenPair.fromJson(server.tokens()));
      await tester.pumpAndSettle();
      expect(find.text('私密历史勺 · 修改历史'), findsNothing);
      expect(find.textContaining('先前私密名称'), findsNothing);
    },
  );

  for (final operation in ['edit', 'delete']) {
    testWidgets(
      '$operation dialog hides old owner data and cannot enqueue it for a new owner',
      (tester) async {
        final server = FakeServer();
        final measures = _MeasureServer(server);
        const id = '88888888-8888-4888-8888-888888888888';
        measures.values[id] = {
          'id': id,
          'name': '旧账号私密勺',
          'kind': 'spoon',
          'capacity_ml': 15,
          'created_at': '2026-10-08T00:00:00Z',
          'updated_at': '2026-10-08T00:00:00Z',
        };
        final env = TestEnv.signedIn(server: server);
        await pumpApp(tester, env: env);
        await tester.tap(find.text('我的'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            ValueKey(
              operation == 'edit' ? 'measure-$id' : 'measure-delete-$id',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          operation == 'edit'
              ? find.widgetWithText(TextField, '旧账号私密勺')
              : find.textContaining('旧账号私密勺').last,
          findsOneWidget,
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(AlertDialog)),
        );
        final before = server.calls('POST', '/v1/sync/writes').length;
        server.user = UserOut.fromJson({
          ...server.user.toJson(),
          'id': '99999999-9999-4999-8999-999999999999',
        });
        measures.values.clear();
        await container
            .read(sessionStoreProvider)
            .save(TokenPair.fromJson(server.tokens()));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byKey(const ValueKey('measure-save')), findsNothing);
        expect(find.text('确认删除'), findsNothing);
        expect(find.textContaining('旧账号私密勺'), findsNothing);
        final later = server.calls('POST', '/v1/sync/writes').skip(before);
        final writes = [
          for (final request in later)
            ...((request.body as Map)['writes'] as List),
        ];
        expect(
          writes.where(
            (raw) => (raw as Map)['write_type'] == 'personal_measure.change',
          ),
          isEmpty,
        );
      },
    );
  }

  for (final history in [false, true]) {
    testWidgets(
      'withdrawal drains admitted delayed ${history ? 'history' : 'list'} cache persistence before owner cleanup',
      (tester) async {
        final server = FakeServer();
        final measures = _MeasureServer(server);
        const id = '88888888-8888-4888-8888-888888888888';
        measures.values[id] = {
          'id': id,
          'name': '清理前私密勺',
          'kind': 'spoon',
          'capacity_ml': 15,
          'created_at': '2026-10-08T00:00:00Z',
          'updated_at': '2026-10-08T00:00:00Z',
        };
        server.on(
          'GET',
          '/v1/me/measures/$id/history',
          (_) => (
            200,
            {
              'items': [
                {
                  'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
                  'write_id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
                  'field': 'name',
                  'device_time': '2026-10-08T00:00:00Z',
                  'old_value': '清理前旧历史',
                  'new_value': '清理前私密勺',
                  'outcome': 'won',
                },
              ],
              'next_cursor': null,
            },
          ),
        );
        final local = _DelayedMeasureCache();
        final env = TestEnv.signedIn(server: server, local: local);
        await pumpApp(tester, env: env);
        await tester.tap(find.text('我的'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(
          tester.element(find.byType(Scaffold).last),
        );
        final session = container.read(sessionStoreProvider);
        local.delayedPrefix = history
            ? 'measure_history:'
            : 'personal_measures:';
        if (history) {
          await tester.tap(find.byKey(const ValueKey('measure-history-$id')));
          await tester.pump(const Duration(milliseconds: 100));
          expect(local.started.isCompleted, isTrue);
          await tester.tap(find.text('关闭'));
          await tester.pumpAndSettle();
        } else {
          await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
          await tester.pump(const Duration(milliseconds: 100));
          for (var i = 0; i < 20 && !local.started.isCompleted; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
          expect(local.started.isCompleted, isTrue);
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await openSettings(tester);
        await tapVisible(tester, find.text('撤回同意'));
        await tester.tap(find.text('撤回并退出'));
        await tester.pump(const Duration(milliseconds: 100));
        local.release.complete();
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('consent-agree')));
        container.read(offlineSimulationProvider.notifier).set(true);
        await session.save(TokenPair.fromJson(server.tokens()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('我的'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
        await tester.pumpAndSettle();
        expect(find.text('清理前私密勺'), findsNothing);
        expect(find.text('还没有登记量具'), findsOneWidget);
        if (history) {
          container.read(offlineSimulationProvider.notifier).set(false);
          await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
          await tester.pumpAndSettle();
          container.read(offlineSimulationProvider.notifier).set(true);
          await tester.tap(find.byKey(const ValueKey('measure-history-$id')));
          await tester.pumpAndSettle();
          expect(find.textContaining('清理前旧历史'), findsNothing);
          expect(find.text('暂无修改记录'), findsOneWidget);
        }
      },
    );
  }

  testWidgets(
    'write admitted during GET is reconciled without queue invalidation masking it',
    (tester) async {
      final server = _ObservedMeasureServer();
      final queue = _SnapshotOnlyQueue();
      const id = '88888888-8888-4888-8888-888888888888';
      const writeId = '00000000-0000-4000-8000-000000000001';
      final row = {
        'id': id,
        'name': '新写入前勺',
        'kind': 'spoon',
        'capacity_ml': 15,
        'created_at': '2026-10-08T00:00:00Z',
        'updated_at': '2026-10-08T00:00:00Z',
      };
      var admit = false;
      var injected = false;
      var reads = 0;
      server.on('GET', '/v1/me/measures', (_) async {
        reads++;
        if (admit && !injected) {
          injected = true;
          await queue.enqueue(
            QueuedEvent.write(
              id: writeId,
              ownerId: testUser().id,
              deviceTime: DateTime.utc(2026, 10, 8),
              writeType: 'personal_measure.change',
              payload: {
                'resource_id': id,
                'action': 'update',
                'fields': {
                  'name': {
                    'value': '新写入旧确认勺',
                    'device_time': '2026-10-08T00:00:00Z',
                  },
                },
              },
            ),
            businessRecord: {
              'projection': {...row, 'name': '新写入旧确认勺'},
            },
          );
          await queue.confirm(writeId, testUser().id, {
            'resource_type': 'personal_measure',
            'resource_id': id,
            'values': {...row, 'name': '新写入旧确认勺'},
          }, confirmedAt: DateTime.utc(2026, 10, 8));
          server.observedWrites.add(writeId);
          server.snapshotVersion += 2; // W then another device's newer update.
        }
        return (
          200,
          {
            'items': [
              {...row, if (injected) 'name': '新写入后远端获胜勺'},
            ],
            'next_cursor': null,
          },
        );
      });
      final env = TestEnv(
        server: server,
        eventQueue: queue,
        local: MemoryLocalStore(consentedStore()),
        secure: MemorySecureStore(signedInSecure(server.user)),
      );
      await pumpApp(tester, env: env);
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
      await tester.pumpAndSettle();
      final before = reads;
      admit = true;
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(
        reads - before,
        2,
      ); // Initial ID set cannot cover the newly admitted W.
      expect(find.text('新写入后远端获胜勺'), findsOneWidget);
      expect(find.text('新写入旧确认勺'), findsNothing);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).last),
      );
      container.read(offlineSimulationProvider.notifier).set(true);
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(find.text('新写入后远端获胜勺'), findsOneWidget);
      expect(find.text('新写入旧确认勺'), findsNothing);
    },
  );

  for (final (brightness, scale) in [
    (Brightness.light, 1.3),
    (Brightness.dark, 1.6),
  ]) {
    testWidgets('personal measure page remains usable at $scale text scale', (
      tester,
    ) async {
      final server = FakeServer();
      await pumpApp(
        tester,
        env: TestEnv.signedIn(server: server),
        brightness: brightness,
        textScale: scale,
      );
      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('personal-measures-entry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('measure-add')), findsOneWidget);
      expect(
        find.text('把空量具放在厨房秤上归零，装满水后的克数就是容量（毫升）。可用于显示或确认录入；重新校准不会修改已保存菜谱。'),
        findsOneWidget,
      );
    });
  }
}
