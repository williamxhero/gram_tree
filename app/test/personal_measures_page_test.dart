import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/events/event_uploader.dart';

import 'helpers.dart';

import 'package:gram_tree/storage/local_store.dart';

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
    server.on('POST', '/v1/sync/writes', (request) {
      final results = <Map<String, dynamic>>[];
      for (final raw in (request.body as Map)['writes'] as List) {
        final write = Map<String, dynamic>.from(raw as Map);
        if (write['write_type'] != 'personal_measure.change') {
          results.add({
            'write_id': write['write_id'],
            'status': 'confirmed',
            'result': {
              'resource_type': 'experience.event',
              'resource_id': write['write_id'],
            },
          });
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
      }
      return (200, {'results': results});
    });
  }
  final values = <String, Map<String, dynamic>>{};
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
        find.text('把空量具放在厨房秤上归零，装满水后的克数就是容量（毫升）。只影响显示，不会修改菜谱。'),
        findsOneWidget,
      );
    });
  }
}
