import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/features/records/dietary_statistics_cache.dart';
import 'package:gram_tree/features/records/dietary_statistics_data.dart';
import 'package:gram_tree/features/records/dietary_statistics_widget.dart';
import 'package:gram_tree/storage/secure_store.dart';
import 'package:gramtree_api/gramtree_api.dart';

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
        child: const MaterialApp(
          home: Scaffold(body: DietaryStatisticsWidget()),
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
