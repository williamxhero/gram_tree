import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/features/records/records_page.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';
import 'lazy_list_controls_support.dart';

const _recordId = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
final _record = CookingRecordOut.fromJson({
  'id': _recordId,
  'client_id': _recordId,
  'dish_name': '私人记录',
  'source': 'external_cooking',
  'verification': 'unverified',
  'counts_as_cooked': false,
  'created_at': '2026-10-15T00:00:00Z',
  'occurred_at': '2026-10-15T00:00:00Z',
  'recipe_id': null,
  'recipe_version_id': null,
  'meal': null,
  'snapshot': null,
  'adjustments': [],
  'source_context': {},
  'taste_summary': {},
  'co_diner_ids': [],
  'photos': [],
}).toJson();

void main() {
  testWidgets('单条记录删除：取消不发请求，确认后刷新且保留未选中的记录', (tester) async {
    final server = FakeServer();
    var deleted = false;
    server.on(
      'GET',
      '/v1/records',
      (_) => (
        200,
        {
          'items': [
            if (!deleted) _record,
            {
              ..._record,
              'id': 'ffffffff-ffff-4fff-8fff-ffffffffffff',
              'dish_name': '另一条私人记录',
            },
          ],
          'next_cursor': null,
        },
      ),
    );
    server.on('DELETE', '/v1/records/$_recordId', (_) {
      deleted = true;
      return (204, null);
    });
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await tapVisible(tester, find.text('记录'));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('record-delete-$_recordId')),
    );
    await tapVisible(tester, find.text('取消'));
    expect(server.calls('DELETE', '/v1/records/$_recordId'), isEmpty);
    expect(find.text('私人记录'), findsOneWidget);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('record-delete-$_recordId')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('record-delete-confirm')),
    );
    expect(find.text('私人记录'), findsNothing);
    expect(find.text('另一条私人记录'), findsOneWidget);
    expect(
      server
          .calls('DELETE', '/v1/records/$_recordId')
          .single
          .headers['Authorization'],
      'Bearer access-0',
    );
  });

  testWidgets('日历下未构建的记录可通过有界滚动取消再确认删除', (tester) async {
    final server = FakeServer();
    final now = DateTime.now().toUtc();
    final first = DateTime.utc(now.year, now.month);
    var deleted = false;
    server.on('GET', '/v1/records/calendar-context', (_) {
      final days = <Map<String, dynamic>>[];
      for (
        var day = first;
        day.month == first.month;
        day = day.add(const Duration(days: 1))
      ) {
        days.add({
          'date': day.toIso8601String().substring(0, 10),
          'start': day.toIso8601String(),
          'end': day.add(const Duration(days: 1)).toIso8601String(),
        });
      }
      return (
        200,
        {'timezone': 'UTC', 'year': now.year, 'month': now.month, 'days': days},
      );
    });
    server.on(
      'GET',
      '/v1/records',
      (_) => (
        200,
        {
          'items': [
            if (!deleted) {..._record, 'occurred_at': now.toIso8601String()},
          ],
          'next_cursor': null,
        },
      ),
    );
    server.on('DELETE', '/v1/records/$_recordId', (_) {
      deleted = true;
      return (204, null);
    });
    await pumpApp(
      tester,
      env: TestEnv.signedIn(server: server),
      size: const Size(800, 360),
    );
    await tapVisible(tester, find.text('记录'));
    final deleteButton = find.byKey(const ValueKey('record-delete-$_recordId'));
    expect(deleteButton, findsNothing);
    // Waiting alone cannot build this card beyond the lazy list's cache extent.
    await tester.pump(const Duration(seconds: 10));
    expect(deleteButton, findsNothing);
    final scrollable = find
        .descendant(
          of: find.byType(RecordsPage),
          matching: find.byType(Scrollable),
        )
        .first;
    await revealLazyListControl(tester, deleteButton, scrollable: scrollable);
    await tester.tap(deleteButton.hitTestable());
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('取消'));
    expect(server.calls('DELETE', '/v1/records/$_recordId'), isEmpty);
    expect(find.text('私人记录'), findsOneWidget);
    await revealLazyListControl(tester, deleteButton, scrollable: scrollable);
    await tester.tap(deleteButton.hitTestable());
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('record-delete-confirm')),
    );
    await revealLazyListControl(
      tester,
      find.text('还没有做菜记录'),
      scrollable: scrollable,
    );
    expect(find.text('私人记录'), findsNothing);
    expect(server.calls('DELETE', '/v1/records/$_recordId'), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('单条删除被拒绝时保留记录并显示错误', (tester) async {
    final server = FakeServer();
    server.on(
      'GET',
      '/v1/records',
      (_) => (
        200,
        {
          'items': [_record],
          'next_cursor': null,
        },
      ),
    );
    server.on(
      'DELETE',
      '/v1/records/$_recordId',
      (_) => FakeServer.error(404, 'not_found', '没有找到这条记录'),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await tapVisible(tester, find.text('记录'));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('record-delete-$_recordId')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('record-delete-confirm')),
    );
    expect(find.text('私人记录'), findsOneWidget);
    expect(find.text('没有找到这条记录'), findsOneWidget);
  });

  testWidgets('删除确认途中换账号：不能给新账号发送旧账号删除请求', (tester) async {
    final server = FakeServer();
    server.on(
      'GET',
      '/v1/records',
      (_) => (
        200,
        {
          'items': [_record],
          'next_cursor': null,
        },
      ),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await tapVisible(tester, find.text('记录'));
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(RecordsPage)),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('record-delete-$_recordId')),
    );
    server.user = server.user.copyWith(
      id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    );
    server.on(
      'GET',
      '/v1/records',
      (_) => (200, {'items': [], 'next_cursor': null}),
    );
    await scope
        .read(sessionStoreProvider)
        .save(TokenPair.fromJson(server.tokens()));
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('record-delete-confirm')),
    );
    expect(server.calls('DELETE', '/v1/records/$_recordId'), isEmpty);
    expect(find.text('私人记录'), findsNothing);
  });

  testWidgets('旧账号在途记录列表不会显示给新账号', (tester) async {
    final server = FakeServer();
    final response = Completer<(int, Object?)>();
    server.on('GET', '/v1/records', (_) => response.future);
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await tester.tap(find.text('记录'));
    await tester.pump(const Duration(milliseconds: 100));
    final scope = ProviderScope.containerOf(
      tester.element(find.byType(RecordsPage)),
    );
    server.user = server.user.copyWith(
      id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    );
    server.on(
      'GET',
      '/v1/records',
      (_) => (200, {'items': [], 'next_cursor': null}),
    );
    await scope
        .read(sessionStoreProvider)
        .save(TokenPair.fromJson(server.tokens()));
    response.complete((
      200,
      {
        'items': [_record],
        'next_cursor': null,
      },
    ));
    await tester.pumpAndSettle();
    expect(find.text('私人记录'), findsNothing);
    expect(find.text('还没有做菜记录'), findsOneWidget);
  });
}
