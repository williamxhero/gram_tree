import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/features/records/records_page.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

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
