import 'dart:typed_data';

/// Where a recipe photo comes from.
enum RecipePhotoSource { camera, gallery }

/// Bytes returned by the platform picker before normalization.
class RecipePhotoAsset {
  const RecipePhotoAsset({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

/// Normalized image sent to the API.  The processor always removes metadata.
class ProcessedRecipePhoto {
  const ProcessedRecipePhoto({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

abstract interface class RecipePhotoPicker {
  Future<RecipePhotoAsset?> pick(RecipePhotoSource source);
}

abstract interface class RecipePhotoProcessor {
  ProcessedRecipePhoto process(RecipePhotoAsset asset);
}

enum RecipePhotoError { unreadable, tooLarge, unsafe }

class RecipePhotoProcessingException implements Exception {
  const RecipePhotoProcessingException(this.code);

  final RecipePhotoError code;
}
