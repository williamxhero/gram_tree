import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';

/// No persistent copy: account switches invalidate all private profile reads.
class TasteProfileRepository {
  TasteProfileRepository(this.api, this.accountId);

  final TasteProfileApi api;
  final String accountId;

  Future<TasteProfileOut> read() async => (await api.getTasteProfile()).data!;

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
      );
    });

final tasteProfileProvider = FutureProvider.autoDispose<TasteProfileOut>(
  (ref) => ref.watch(tasteProfileRepositoryProvider).read(),
);

final tasteProfileChangesProvider =
    FutureProvider.autoDispose<List<TasteProfileChangeOut>>(
      (ref) => ref.watch(tasteProfileRepositoryProvider).changes(),
    );
