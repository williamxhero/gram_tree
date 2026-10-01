import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../api/api_client.dart';
import 'recipe_photo.dart';

class RecipePhotoUploadResult {
  const RecipePhotoUploadResult({
    required this.id,
    required this.contentType,
    required this.byteSize,
    required this.width,
    required this.height,
    required this.url,
    required this.expiresInSeconds,
    this.versionId,
  });

  final String id;
  final String? versionId;
  final String contentType;
  final int byteSize;
  final int? width;
  final int? height;
  final String url;
  final int expiresInSeconds;
}

abstract interface class RecipePhotoApi {
  Future<RecipePhotoUploadResult> upload({
    required String? recipeId,
    required ProcessedRecipePhoto photo,
  });
}

/// Uses the generated OpenAPI client for both staged and version uploads.
/// Keeping the platform-facing result type here avoids leaking generated models
/// into the photo picker while preventing a second, hand-written HTTP contract.
class GeneratedRecipePhotoApi implements RecipePhotoApi {
  const GeneratedRecipePhotoApi(this._api);

  final GramtreeApi _api;

  @override
  Future<RecipePhotoUploadResult> upload({
    required String? recipeId,
    required ProcessedRecipePhoto photo,
  }) async {
    final request = RecipeImageUpload(
      contentBase64: base64Encode(photo.bytes),
      contentType: photo.contentType,
      filename: photo.filename,
    );
    final recipes = _api.getRecipesApi();
    if (recipeId == null) {
      final response = await recipes.stageRecipeImage(
        recipeImageUpload: request,
      );
      final result = response.data!;
      return RecipePhotoUploadResult(
        id: result.id,
        contentType: result.contentType,
        byteSize: result.byteSize,
        width: result.width,
        height: result.height,
        url: result.url,
        expiresInSeconds: result.expiresInSeconds,
      );
    }
    final response = await recipes.uploadRecipeImage(
      recipeId: recipeId,
      recipeImageUpload: request,
    );
    final result = response.data!;
    return RecipePhotoUploadResult(
      id: result.id,
      versionId: result.versionId,
      contentType: result.contentType,
      byteSize: result.byteSize,
      width: result.width,
      height: result.height,
      url: result.url,
      expiresInSeconds: result.expiresInSeconds,
    );
  }
}

final recipePhotoApiProvider = Provider<RecipePhotoApi>(
  (ref) => GeneratedRecipePhotoApi(ref.watch(apiClientProvider)),
);

final recipePhotoPickerProvider = Provider<RecipePhotoPicker>(
  (ref) => createRecipePhotoPicker(),
);

final recipePhotoProcessorProvider = Provider<RecipePhotoProcessor>(
  (ref) => const DefaultRecipePhotoProcessor(),
);
