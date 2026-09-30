import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../storage/local_store.dart';
import 'ingredient_api_client.dart';
import 'ingredient_cache.dart';
import 'ingredient_repository.dart';

/// The UI depends on this repository, not on Dio or on the mobile database.
final ingredientRepositoryProvider = Provider<IngredientRepository>((ref) {
  final cache = createIngredientCacheStore(ref.watch(localStoreProvider));
  ref.onDispose(() {
    if (cache case final CloseableIngredientCacheStore closeable) {
      unawaited(closeable.close());
    }
  });
  return IngredientRepository(
    api: GeneratedIngredientSyncApi(
      ref.watch(apiClientProvider).getIngredientsApi(),
    ),
    cache: cache,
  );
});
