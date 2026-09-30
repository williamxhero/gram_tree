import 'recipe_photo_types.dart';

/// Test/stub implementation used by unsupported targets.
class StubRecipePhotoPicker implements RecipePhotoPicker {
  const StubRecipePhotoPicker();

  @override
  Future<RecipePhotoAsset?> pick(RecipePhotoSource source) async => null;
}

RecipePhotoPicker createRecipePhotoPicker() => const StubRecipePhotoPicker();
