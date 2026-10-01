import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'recipe_photo_types.dart';

/// Pure-Dart normalization shared by mobile and web.
class DefaultRecipePhotoProcessor implements RecipePhotoProcessor {
  const DefaultRecipePhotoProcessor();

  static const _maxPixels = 40 * 1000 * 1000;
  static const _maxDimension = 2048;

  @override
  ProcessedRecipePhoto process(RecipePhotoAsset asset) {
    try {
      final decoded = img.decodeImage(asset.bytes);
      if (decoded == null) {
        throw const RecipePhotoProcessingException(RecipePhotoError.unreadable);
      }
      if (decoded.width * decoded.height > _maxPixels) {
        throw const RecipePhotoProcessingException(RecipePhotoError.tooLarge);
      }
      // bakeOrientation reads EXIF orientation, then the JPEG encoder below
      // writes a fresh image with no EXIF/GPS/application metadata.
      var normalized = img.bakeOrientation(decoded);
      if (normalized.width > _maxDimension ||
          normalized.height > _maxDimension) {
        normalized = img.copyResize(
          normalized,
          width: normalized.width >= normalized.height ? _maxDimension : null,
          height: normalized.height > normalized.width ? _maxDimension : null,
          interpolation: img.Interpolation.cubic,
        );
      }
      final bytes = img.encodeJpg(normalized, quality: 85);
      return ProcessedRecipePhoto(
        bytes: Uint8List.fromList(bytes),
        filename: 'recipe-photo.jpg',
        contentType: 'image/jpeg',
      );
    } on RecipePhotoProcessingException {
      rethrow;
    } catch (_) {
      throw const RecipePhotoProcessingException(RecipePhotoError.unsafe);
    }
  }
}
