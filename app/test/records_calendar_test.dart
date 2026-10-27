import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gram_tree/features/records/records_calendar.dart';
import 'package:gram_tree/features/records/records_history.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gramtree_api/gramtree_api.dart';

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
  test('离线历史上下文使用快照IANA时区跨夏令时计算日期', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final snapshot = RecordHistorySnapshot(
      accountId: 'account',
      timezone: 'America/Los_Angeles',
      cachedAt: DateTime.utc(2026, 10),
      items: const [],
      contexts: const {},
    );
    final march = container
        .read(recordsHistoryProvider)
        .contextFor(snapshot, 2026, 3);
    expect(march.dayFor(DateTime.utc(2026, 3, 9, 6, 30))?.date, '2026-03-08');
    expect(march.dayFor(DateTime.utc(2026, 3, 9, 7, 30))?.date, '2026-03-09');
    final springDay = march.days.singleWhere((day) => day.date == '2026-03-08');
    expect(
      springDay.end.difference(springDay.start),
      const Duration(hours: 23),
    );
    final november = container
        .read(recordsHistoryProvider)
        .contextFor(snapshot, 2026, 11);
    final fallDay = november.days.singleWhere(
      (day) => day.date == '2026-11-01',
    );
    expect(fallDay.end.difference(fallDay.start), const Duration(hours: 25));
  });
  testWidgets('月日历可离线生成任意历史月份并保留记录集合', (tester) async {
    final now = DateTime.now().toUtc();
    final current = DateTime.utc(now.year, now.month);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final context = container
        .read(recordsHistoryProvider)
        .localContext('America/Los_Angeles', current.year, current.month);
    final expected = DateTime.utc(current.year, current.month - 3);
    final older = historyRecord(
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      '三个月前的晚餐',
      DateTime.utc(expected.year, expected.month, 2, 6, 30).toIso8601String(),
    );
    final recent = historyRecord(
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      '这个月的午餐',
      DateTime.utc(current.year, current.month, 2, 20).toIso8601String(),
    );
    final snapshot = RecordHistorySnapshot(
      accountId: 'account',
      timezone: 'America/Los_Angeles',
      cachedAt: now,
      items: [recent, older],
      contexts: {'${current.year}-${current.month}': context},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: TestEnv.signedIn(offline: true).overrides,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RecordsCalendar(
              snapshot: RecordHistorySnapshot.fromJson(snapshot.toJson()),
              records: [
                (CookingRecordOut.fromJson(recent), null, false),
                (CookingRecordOut.fromJson(older), null, false),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
    }
    expect(find.text('${expected.year} 年 ${expected.month} 月'), findsOneWidget);
    final date =
        '${expected.year}-${expected.month.toString().padLeft(2, '0')}-01';
    await tapVisible(tester, find.byKey(ValueKey('calendar-day-$date')));
    await tester.scrollUntilVisible(
      find.text('三个月前的晚餐'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('三个月前的晚餐'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, 1800));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tapVisible(tester, find.byTooltip('下个月'));
    }
    final recentDate =
        '${current.year}-${current.month.toString().padLeft(2, '0')}-02';
    await tapVisible(tester, find.byKey(ValueKey('calendar-day-$recentDate')));
    await tester.scrollUntilVisible(
      find.text('这个月的午餐'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('这个月的午餐'), findsOneWidget);
  });
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
