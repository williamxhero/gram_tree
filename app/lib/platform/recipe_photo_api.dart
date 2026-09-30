import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  factory RecipePhotoUploadResult.fromJson(Map<String, dynamic> json) =>
      RecipePhotoUploadResult(
        id: json['id'] as String,
        versionId: json['version_id'] as String?,
        contentType: json['content_type'] as String,
        byteSize: json['byte_size'] as int,
        width: json['width'] as int?,
        height: json['height'] as int?,
        url: json['url'] as String,
        expiresInSeconds: json['expires_in_seconds'] as int,
      );

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

class DioRecipePhotoApi implements RecipePhotoApi {
  const DioRecipePhotoApi(this._dio);

  final Dio _dio;

  @override
  Future<RecipePhotoUploadResult> upload({
    required String? recipeId,
    required ProcessedRecipePhoto photo,
  }) async {
    final path = recipeId == null
        ? '/v1/recipes/images/staging'
        : '/v1/recipes/$recipeId/images';
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: {
        'content_base64': base64Encode(photo.bytes),
        'content_type': photo.contentType,
        'filename': photo.filename,
      },
    );
    return RecipePhotoUploadResult.fromJson(response.data!);
  }
}

final recipePhotoApiProvider = Provider<RecipePhotoApi>(
  (ref) => DioRecipePhotoApi(ref.watch(dioProvider)),
);

final recipePhotoPickerProvider = Provider<RecipePhotoPicker>(
  (ref) => createRecipePhotoPicker(),
);

final recipePhotoProcessorProvider = Provider<RecipePhotoProcessor>(
  (ref) => const DefaultRecipePhotoProcessor(),
);
