import '../storage/local_store.dart';
import 'ingredient_repository.dart';

IngredientCacheStore createPlatformIngredientCacheStore(
  LocalStore localStore,
) => LocalStoreIngredientCache(localStore);
