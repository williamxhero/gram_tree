import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/empty_state.dart';
import 'dietary_statistics_data.dart';

/// Owner dietary statistics: one series per distribution, no decorative chart.
class DietaryStatisticsWidget extends ConsumerStatefulWidget {
  const DietaryStatisticsWidget({super.key});
  @override
  ConsumerState<DietaryStatisticsWidget> createState() =>
      _DietaryStatisticsWidgetState();
}

class _DietaryStatisticsWidgetState
    extends ConsumerState<DietaryStatisticsWidget> {
  DietaryStatisticsPeriod _period = DietaryStatisticsPeriod.month;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(dietaryStatisticsSnapshotProvider(_period));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<DietaryStatisticsPeriod>(
          key: const ValueKey('dietary-statistics-period'),
          segments: [
            for (final period in DietaryStatisticsPeriod.values)
              ButtonSegment(value: period, label: Text(period.label)),
          ],
          selected: {_period},
          onSelectionChanged: (values) =>
              setState(() => _period = values.first),
        ),
        const SizedBox(height: 16),
        snapshot.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Error(
            onRetry: () =>
                ref.invalidate(dietaryStatisticsSnapshotProvider(_period)),
          ),
          data: (value) => RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(dietaryStatisticsSnapshotProvider(_period)),
            child: _StatisticsBody(snapshot: value),
          ),
        ),
      ],
    );
  }
}

class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody({required this.snapshot});
  final DietaryStatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final stats = snapshot.statistics;
    if (stats.cookingCount == 0) {
      return const EmptyState(
        icon: Icons.query_stats_outlined,
        title: '这个时段还没有做菜统计',
        message: '做完菜点“做好了”，这里会显示你的饮食回报。',
      );
    }
    return ListView(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ListTile(
          title: const Text('做菜次数'),
          trailing: Text('${stats.cookingCount}'),
          subtitle: Text(
            snapshot.fromCache
                ? '离线结果 · ${snapshot.cachedAt.toLocal()}'
                : '已更新',
          ),
        ),
        _Distribution(title: '主料分布', items: stats.ingredientDistribution),
        _Distribution(title: '菜系分布', items: stats.cuisineDistribution),
        if (stats.frequentDishes.isNotEmpty)
          _DishList(title: '常做的菜', items: stats.frequentDishes),
        if (stats.newDishes.isNotEmpty)
          _DishList(title: '新尝试', items: stats.newDishes),
        if (stats.unclassifiedDishCount > 0)
          ListTile(
            title: const Text('未归一菜名'),
            subtitle: const Text('这些记录未能安全合并为同一道菜，未用于宣称首次尝试。'),
            trailing: Text('${stats.unclassifiedDishCount}'),
          ),
      ],
    );
  }
}

class _Distribution extends StatelessWidget {
  const _Distribution({required this.title, required this.items});
  final String title;
  final List<dynamic> items;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(title),
    children: [
      for (final item in items)
        ListTile(
          title: Text(item.key as String),
          trailing: Text('${item.count}'),
        ),
    ],
  );
}

class _DishList extends StatelessWidget {
  const _DishList({required this.title, required this.items});
  final String title;
  final List<dynamic> items;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(title),
    children: [
      for (final item in items)
        ListTile(
          title: Text(item.name as String),
          trailing: Text('${item.count}'),
        ),
    ],
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text('统计暂时不可用'),
      TextButton(onPressed: onRetry, child: const Text('重试')),
    ],
  );
}
