import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import '../../network/reachability.dart';
import 'dietary_statistics_cache.dart';

enum DietaryStatisticsPeriod { week, month, year }

extension DietaryStatisticsPeriodValue on DietaryStatisticsPeriod {
  String get wire => name;
  String get label => switch (this) {
    DietaryStatisticsPeriod.week => '本周',
    DietaryStatisticsPeriod.month => '本月',
    DietaryStatisticsPeriod.year => '今年',
  };
}

class DietaryStatisticsSnapshot {
  const DietaryStatisticsSnapshot({
    required this.statistics,
    required this.cachedAt,
    required this.fromCache,
  });
  final DietaryStatisticsOut statistics;
  final DateTime cachedAt;
  final bool fromCache;
}

class DietaryStatisticsRepository {
  DietaryStatisticsRepository(this.api, this.ownerId, this.session, this.cache);
  final DietaryHistoryApi api;
  final String ownerId;
  final SessionStore session;
  final DietaryStatisticsCache cache;

  SessionIdentity _identity() {
    final identity = session.identity;
    if (identity == null || identity.ownerId != ownerId) {
      throw StateError('account_unavailable');
    }
    return identity;
  }

  Future<DietaryStatisticsSnapshot> readSnapshot(
    DietaryStatisticsPeriod period,
  ) async {
    final identity = _identity();
    try {
      final response = await api.getDietaryStatistics(
        period: period.wire,
        extra: {
          'auth_owner_id': identity.ownerId,
          'auth_identity_epoch': identity.epoch,
        },
      );
      if (!session.matches(identity) || response.data == null) {
        throw StateError('stale_dietary_statistics_response');
      }
      final value = response.data!;
      await cache.write(
        ownerId,
        period.wire,
        value.toJson(),
        stillCurrent: () => session.matches(identity),
      );
      return DietaryStatisticsSnapshot(
        statistics: value,
        cachedAt: DateTime.now().toUtc(),
        fromCache: false,
      );
    } catch (error) {
      if (!isNetworkFailure(error) || !session.matches(identity)) rethrow;
      final raw = await cache.read(ownerId, period.wire);
      if (!session.matches(identity) || raw == null) rethrow;
      return DietaryStatisticsSnapshot(
        statistics: DietaryStatisticsOut.fromJson(raw),
        cachedAt: DateTime.parse(raw['generated_at'] as String).toUtc(),
        fromCache: true,
      );
    }
  }
}

final dietaryStatisticsCacheProvider = Provider<DietaryStatisticsCache>(
  (ref) => DietaryStatisticsCache(ref.watch(secureStoreProvider)),
);

final dietaryStatisticsRepositoryProvider =
    Provider.autoDispose<DietaryStatisticsRepository>((ref) {
      final ownerId = ref.watch(authProvider).value?.id;
      if (ownerId == null) throw StateError('饮食统计需要登录');
      return DietaryStatisticsRepository(
        ref.watch(apiClientProvider).getDietaryHistoryApi(),
        ownerId,
        ref.watch(sessionStoreProvider),
        ref.watch(dietaryStatisticsCacheProvider),
      );
    });

final dietaryStatisticsSnapshotProvider = FutureProvider.autoDispose
    .family<DietaryStatisticsSnapshot, DietaryStatisticsPeriod>((ref, period) {
      return ref
          .watch(dietaryStatisticsRepositoryProvider)
          .readSnapshot(period);
    });
