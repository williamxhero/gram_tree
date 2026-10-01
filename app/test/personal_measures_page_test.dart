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
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('measure-add')))
          .onPressed,
      isNull,
    );
  });
}
