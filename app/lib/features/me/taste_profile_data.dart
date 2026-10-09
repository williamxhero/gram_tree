import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import 'taste_profile_cache.dart';

class TasteProfileSnapshot {
  const TasteProfileSnapshot({
    required this.profile,
    required this.cachedAt,
    required this.fromCache,
  });

  final TasteProfileOut profile;
  final DateTime cachedAt;
  final bool fromCache;
}

/// Online reads replace the secure snapshot. Offline reads are deliberately
/// read-only and never enter the event queue.
class TasteProfileRepository {
  TasteProfileRepository(this.api, this.accountId, this.session, this.cache);

  final TasteProfileApi api;
  final String accountId;
  final SessionStore session;
  final TasteProfileCache cache;

  Future<TasteProfileSnapshot> readSnapshot() async {
    final identity = session.identity;
    if (identity == null || identity.ownerId != accountId) {
      throw StateError('account_unavailable');
    }
    try {
      final profile = (await api.getTasteProfile()).data!;
      if (!session.matches(identity)) {
        throw StateError('stale_profile_response');
      }
      await cache.writeProfile(
        accountId,
        profile,
        stillCurrent: () => session.matches(identity),
      );
      return TasteProfileSnapshot(
        profile: profile,
        cachedAt: DateTime.now().toUtc(),
        fromCache: false,
      );
    } catch (error) {
      if (error is DioException && error.response?.statusCode != null) rethrow;
      if (error is StateError || !session.matches(identity)) rethrow;
      final response = await cache.read(accountId);
      if (response?.profile == null) rethrow;
      return TasteProfileSnapshot(
        profile: response!.profile!,
        cachedAt: response.cachedAt,
        fromCache: true,
      );
    }
  }

  Future<TasteProfileOut> read() async => (await readSnapshot()).profile;

  Future<TasteProfileOut> setLevel(String flavor, num coefficient) async =>
      (await api.updateTasteProfile(
        tasteProfilePatch: TasteProfilePatch(flavors: {flavor: coefficient}),
      )).data!;

  Future<TasteProfileOut> setPreferences(
    List<IngredientPreference> preferences,
  ) async => (await api.updateTasteProfile(
    tasteProfilePatch: TasteProfilePatch(ingredientPreferences: preferences),
  )).data!;

  Future<TasteProfileOut> reset() async =>
      (await api.resetTasteProfile()).data!;

  Future<List<TasteProfileChangeOut>> changes() async {
    final items = <TasteProfileChangeOut>[];
    String? cursor;
    do {
      final page = (await api.listTasteProfileChanges(cursor: cursor)).data!;
      items.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    return items;
  }
}

final tasteProfileRepositoryProvider =
    Provider.autoDispose<TasteProfileRepository>((ref) {
      final accountId = ref.watch(authProvider).value?.id;
      if (accountId == null) throw StateError('口味档案需要登录');
      return TasteProfileRepository(
        ref.watch(apiClientProvider).getTasteProfileApi(),
        accountId,
        ref.watch(sessionStoreProvider),
        ref.watch(tasteProfileCacheProvider),
      );
    });

final tasteProfileSnapshotProvider =
    FutureProvider.autoDispose<TasteProfileSnapshot>(
      (ref) => ref.watch(tasteProfileRepositoryProvider).readSnapshot(),
    );

final tasteProfileProvider = FutureProvider.autoDispose<TasteProfileOut>(
  (ref) => ref
      .watch(tasteProfileSnapshotProvider.future)
      .then((value) => value.profile),
);

final tasteProfileChangesProvider =
    FutureProvider.autoDispose<List<TasteProfileChangeOut>>(
      (ref) => ref.watch(tasteProfileRepositoryProvider).changes(),
    );
