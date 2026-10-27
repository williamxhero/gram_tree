import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/features/records/dietary_statistics_cache.dart';
import 'package:gram_tree/features/records/dietary_statistics_data.dart';
import 'package:gram_tree/features/records/dietary_statistics_widget.dart';
import 'package:gram_tree/events/event_recorder.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/features/records/monthly_review.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gram_tree/privacy/consent.dart';
import 'package:gram_tree/storage/secure_store.dart';
import 'package:gramtree_api/gramtree_api.dart';

class _RecordingEventRecorder extends EventRecorder {
  _RecordingEventRecorder(super.ref, this.events);

  final List<Map<String, dynamic>> events;

  @override
  Future<void> record({
    required String eventType,
    required int typeVersion,
    EventCorrelationIds? correlation,
    Map<String, dynamic>? content,
  }) async {
    events.add({'type': eventType, 'version': typeVersion, 'content': content});
  }
}

void main() {
  test('统计缓存按账号隔离并可清除', () async {
    final store = MemorySecureStore();
    final cache = DietaryStatisticsCache(store);
    final value = {'generated_at': '2026-03-15T00:00:00Z', 'cooking_count': 2};
    await cache.write('alice', 'month', value, stillCurrent: () => true);
    expect(await cache.read('alice', 'month'), value);
    expect(await cache.read('bob', 'month'), isNull);
    await cache.clearOwner('alice');
    expect(await cache.read('alice', 'month'), isNull);
  });

  testWidgets('月回顾每个历史月份只记录一次查看事件', (tester) async {
    final now = DateTime.now().toUtc();
    final initialMonth = DateTime(now.year, now.month - 1);
    final olderMonth = DateTime(initialMonth.year, initialMonth.month - 1);
    final events = <Map<String, dynamic>>[];

    DietaryStatisticsOut statistics(DateTime month, int count) {
      final start = DateTime.utc(month.year, month.month);
      final end = DateTime.utc(month.year, month.month + 1);
      return DietaryStatisticsOut(
        cookingCount: count,
        cuisineDistribution: [],
        endAt: end.toIso8601String(),
        frequentDishes: [],
        generatedAt: now.toIso8601String(),
        ingredientDistribution: [],
        ingredientRecordCount: 0,
        localEnd: DateTime(end.year, end.month),
        localStart: DateTime(start.year, start.month),
        newDishes: [],
        period: DietaryStatisticsOutPeriodEnum.month,
        startAt: start.toIso8601String(),
        timezone: 'UTC',
        unclassifiedDishCount: 0,
        unclassifiedDishes: [],
      );
    }

    MonthlyReviewSnapshot snapshotFor(DateTime month) => MonthlyReviewSnapshot(
      month: month,
      current: statistics(month, 2),
      previous: statistics(DateTime(month.year, month.month - 1), 1),
      changes: const [],
      cachedAt: now,
      fromCache: false,
    );

    Widget page() => ProviderScope(
      overrides: [
        eventRecorderProvider.overrideWith(
          (ref) => _RecordingEventRecorder(ref, events),
        ),
        monthlyReviewProvider(initialMonth)
            .overrideWith((ref) async => snapshotFor(initialMonth)),
        monthlyReviewProvider(olderMonth)
            .overrideWith((ref) async => snapshotFor(olderMonth)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          extensions: const [
            GramTreeColors(
              paper: GramTreePalette.paper,
              card: GramTreePalette.card,
              ink: GramTreePalette.ink,
              accent: GramTreePalette.accent,
              verified: GramTreePalette.verified,
            ),
          ],
        ),
        home: const Scaffold(
          body: SingleChildScrollView(child: MonthlyReviewSection()),
        ),
      ),
    );

    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(events, hasLength(1));
    expect(events.single['type'], 'records.monthly_review_opened');
    expect(events.single['content'], {
      'month':
          '${initialMonth.year.toString().padLeft(4, '0')}-${initialMonth.month.toString().padLeft(2, '0')}',
    });

    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(events, hasLength(1));

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(events, hasLength(2));
    expect(events.last['content'], {
      'month':
          '${olderMonth.year.toString().padLeft(4, '0')}-${olderMonth.month.toString().padLeft(2, '0')}',
    });
  });

  testWidgets('月回顾离线展示自动变化并禁用档案操作', (tester) async {
    final current = DietaryStatisticsOut(
      cookingCount: 3,
      cuisineDistribution: [],
      endAt: '2026-03-31T16:00:00Z',
      frequentDishes: [],
      generatedAt: '2026-04-01T00:00:00Z',
      ingredientDistribution: [],
      ingredientRecordCount: 0,
      localEnd: DateTime(2026, 4),
      localStart: DateTime(2026, 3),
      newDishes: [],
      period: DietaryStatisticsOutPeriodEnum.month,
      startAt: '2026-02-28T16:00:00Z',
      timezone: 'Asia/Shanghai',
      unclassifiedDishCount: 0,
      unclassifiedDishes: [],
    );
    final previous = DietaryStatisticsOut(
      cookingCount: 1,
      cuisineDistribution: [],
      endAt: '2026-02-28T16:00:00Z',
      frequentDishes: [],
      generatedAt: '2026-03-01T00:00:00Z',
      ingredientDistribution: [],
      ingredientRecordCount: 0,
      localEnd: DateTime(2026, 3),
      localStart: DateTime(2026, 2),
      newDishes: [],
      period: DietaryStatisticsOutPeriodEnum.month,
      startAt: '2026-01-31T16:00:00Z',
      timezone: 'Asia/Shanghai',
      unclassifiedDishCount: 0,
      unclassifiedDishes: [],
    );
    final change = TasteProfileChangeOut(
      createdAt: '2026-03-10T00:00:00Z',
      field: 'flavors.spicy',
      id: 'change-1',
      newValue: {'coefficient': 1.1},
      oldValue: {'coefficient': 1.0},
      origin: TasteProfileChangeOutOriginEnum.auto,
      reason: '近期做菜时调整过辣度',
      source_: TasteProfileChangeOutSource_Enum.learning,
      status: TasteProfileChangeOutStatusEnum.pending,
      version: 1,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privacyConsentProvider.overrideWithValue(false),
          monthlyReviewProvider(
            DateTime(DateTime.now().year, DateTime.now().month - 1),
          ).overrideWith(
            (ref) async => MonthlyReviewSnapshot(
              month: DateTime(DateTime.now().year, DateTime.now().month - 1),
              current: current,
              previous: previous,
              changes: [change],
              cachedAt: DateTime.utc(2026, 4, 1),
              fromCache: true,
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            extensions: const [
              GramTreeColors(
                paper: GramTreePalette.paper,
                card: GramTreePalette.card,
                ink: GramTreePalette.ink,
                accent: GramTreePalette.accent,
                verified: GramTreePalette.verified,
              ),
            ],
          ),
          home: const Scaffold(
            body: SingleChildScrollView(child: MonthlyReviewSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('较再上月 增加 2 次'), findsOneWidget);
    expect(find.text('自动学习的口味变化'), findsOneWidget);
    expect(find.textContaining('离线回顾'), findsOneWidget);
    expect(find.text('离线时不能确认或撤销，联网后重试。'), findsOneWidget);
    final confirmButton = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == '确认',
    );
    expect(tester.widget<IconButton>(confirmButton).onPressed, isNull);
    expect(find.byKey(const ValueKey('monthly-review-2026-3')), findsNothing);
  });

  testWidgets('统计组件显示次数、分布和离线更新时间', (tester) async {
    final statistics = DietaryStatisticsOut(
      cookingCount: 2,
      cuisineDistribution: [DietaryDistributionItem(key: '川菜', count: 2)],
      endAt: '2026-04-01T00:00:00Z',
      frequentDishes: [],
      generatedAt: '2026-03-15T00:00:00Z',
      ingredientDistribution: [DietaryDistributionItem(key: '蔬菜', count: 1)],
      ingredientRecordCount: 1,
      localEnd: DateTime(2026, 4),
      localStart: DateTime(2026, 3),
      newDishes: [],
      period: DietaryStatisticsOutPeriodEnum.month,
      startAt: '2026-03-01T00:00:00Z',
      timezone: 'Asia/Shanghai',
      unclassifiedDishCount: 0,
      unclassifiedDishes: [],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dietaryStatisticsSnapshotProvider(DietaryStatisticsPeriod.month)
              .overrideWith(
                (ref) async => DietaryStatisticsSnapshot(
                  statistics: statistics,
                  cachedAt: DateTime.parse('2026-03-15T00:00:00Z'),
                  fromCache: true,
                ),
              ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: DietaryStatisticsWidget()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('离线结果'), findsOneWidget);
    expect(find.text('主料分布'), findsOneWidget);
    expect(find.text('菜系分布'), findsOneWidget);
  });
}
