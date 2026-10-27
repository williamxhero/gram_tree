import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final snapshot = ref.watch(dietaryStatisticsSnapshotProvider(_period));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<DietaryStatisticsPeriod>(
          key: const ValueKey('dietary-statistics-period'),
          segments: [
            for (final period in DietaryStatisticsPeriod.values)
              ButtonSegment(value: period, label: Text(period.label(l10n))),
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
    final l10n = AppLocalizations.of(context);
    if (stats.cookingCount == 0) {
      return EmptyState(
        icon: Icons.query_stats_outlined,
        title: l10n.dietaryStatisticsEmptyTitle,
        message: l10n.dietaryStatisticsEmptyBody,
      );
    }
    return ListView(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ListTile(
          title: Text(l10n.dietaryStatisticsCookingCount),
          trailing: Text('${stats.cookingCount}'),
          subtitle: Text(
            snapshot.fromCache
                ? l10n.dietaryStatisticsCached(
                    snapshot.cachedAt.toLocal().toString(),
                  )
                : l10n.dietaryStatisticsUpdated,
          ),
        ),
        _Distribution(
          title: l10n.dietaryStatisticsIngredient,
          unknownLabel: l10n.dietaryStatisticsUnknown,
          items: stats.ingredientDistribution,
        ),
        _Distribution(
          title: l10n.dietaryStatisticsCuisine,
          unknownLabel: l10n.dietaryStatisticsUnknown,
          items: stats.cuisineDistribution,
        ),
        if (stats.frequentDishes.isNotEmpty)
          _DishList(
            title: l10n.dietaryStatisticsFrequent,
            items: stats.frequentDishes,
          ),
        if (stats.newDishes.isNotEmpty)
          _DishList(title: l10n.dietaryStatisticsNew, items: stats.newDishes),
        if (stats.unclassifiedDishCount > 0)
          ListTile(
            title: Text(l10n.dietaryStatisticsUnclassified),
            subtitle: Text(l10n.dietaryStatisticsUnclassifiedBody),
            trailing: Text('${stats.unclassifiedDishCount}'),
          ),
      ],
    );
  }
}

class _Distribution extends StatelessWidget {
  const _Distribution({
    required this.title,
    required this.unknownLabel,
    required this.items,
  });
  final String title;
  final String unknownLabel;
  final List<dynamic> items;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(title),
    children: [
      for (final item in items)
        ListTile(
          title: Text(
            item.key as String == 'unclassified'
                ? unknownLabel
                : item.key as String,
          ),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(l10n.dietaryStatisticsUnavailable),
        TextButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}
