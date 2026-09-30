import '../storage/local_store.dart';
import 'ingredient_repository.dart';

import 'ingredient_cache_stub.dart'
    if (dart.library.io) 'ingredient_cache_mobile.dart'
    if (dart.library.js_interop) 'ingredient_cache_web.dart';

IngredientCacheStore createIngredientCacheStore(LocalStore localStore) =>
    createPlatformIngredientCacheStore(localStore);
