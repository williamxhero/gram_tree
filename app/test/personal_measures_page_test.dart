import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

import 'package:gram_tree/storage/local_store.dart';

void main() {
  testWidgets('user can create, edit, and delete a personal measure', (
    tester,
  ) async {
    final server = FakeServer();
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

    await tester.tap(
      find.byKey(
        const ValueKey('measure-66666666-6666-4666-8666-666666666666'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('measure-name')), '大白瓷勺');
    await tester.enterText(
      find.byKey(const ValueKey('measure-capacity')),
      '18',
    );
    await tester.tap(find.byKey(const ValueKey('measure-save')));
    await tester.pumpAndSettle();
    expect(find.text('大白瓷勺'), findsOneWidget);

    await tester.tap(
      find.byKey(
        const ValueKey('measure-delete-66666666-6666-4666-8666-666666666666'),
      ),
    );
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
    expect(find.text('登记自家量具'), findsNothing);
  });

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
