import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Map<String, dynamic> historyRecord(
  String id,
  String name,
  String at, {
  String source = 'external_cooking',
}) => {
  'id': id,
  'client_id': id,
  'dish_name': name,
  'source': source,
  'verification': 'unverified',
  'counts_as_cooked': source != 'dining',
  'created_at': at,
  'occurred_at': at,
  'recipe_id': null,
  'recipe_version_id': null,
  'meal': null,
  'snapshot': null,
  'adjustments': [],
  'source_context': {},
  'taste_summary': {},
  'co_diner_ids': [],
  'photos': [],
};

void main() {
  testWidgets('月日历取完全部分页并按账号时区跨日显示不同来源', (tester) async {
    final now = DateTime.now().toUtc();
    final month = DateTime.utc(now.year, now.month);
    final at = month.add(const Duration(hours: 16, minutes: 30));
    final server = FakeServer();
    server.on('GET', '/v1/records/calendar-context', (request) {
      final first = DateTime.utc(now.year, now.month);
      final days = <Map<String, dynamic>>[];
      for (var i = 0; i < 31; i++) {
        final start = first.add(Duration(days: i));
        if (start.month != now.month) break;
        days.add({
          'date': start.toIso8601String().substring(0, 10),
          'start': start.toIso8601String(),
          'end': start.add(const Duration(days: 1)).toIso8601String(),
        });
      }
      return (
        200,
        {
          'timezone': 'Asia/Shanghai',
          'year': now.year,
          'month': now.month,
          'days': days,
        },
      );
    });
    server.on(
      'GET',
      '/v1/records',
      (request) => (
        200,
        {
          'items': [
            historyRecord(
              request.query['cursor'] == 'page-two'
                  ? 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'
                  : 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
              request.query['cursor'] == 'page-two' ? '外卖晚餐' : '自己炒菜',
              at.toIso8601String(),
              source: request.query['cursor'] == 'page-two'
                  ? 'dining'
                  : 'external_cooking',
            ),
          ],
          'next_cursor': request.query['cursor'] == 'page-two'
              ? null
              : 'page-two',
        },
      ),
    );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await tapVisible(tester, find.text('记录'));
    expect(
      server
          .calls('GET', '/v1/records')
          .any((r) => r.query['cursor'] == 'page-two'),
      isTrue,
    );
    await tapVisible(
      tester,
      find.byKey(
        ValueKey('calendar-day-${at.toIso8601String().substring(0, 10)}'),
      ),
    );
    expect(find.text('自己炒菜'), findsOneWidget);
    expect(find.text('外卖晚餐'), findsOneWidget);
    expect(find.textContaining('App 外做菜'), findsWidgets);
    expect(find.textContaining('外食/外卖'), findsWidgets);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('record-bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb')),
    );
    expect(find.text('记录详情'), findsOneWidget);
    expect(find.text('没有关联菜谱，不能直接再做一次。'), findsOneWidget);
  });
}
