export 'recipe_photo_processing.dart';
export 'recipe_photo_types.dart';

import 'recipe_photo_types.dart';

import 'recipe_photo_stub.dart'
    if (dart.library.io) 'recipe_photo_mobile.dart'
    if (dart.library.html) 'recipe_photo_web.dart' as platform;

RecipePhotoPicker createRecipePhotoPicker() => platform.createRecipePhotoPicker();
