import 'package:image_picker/image_picker.dart';

import 'recipe_photo_types.dart';

class ImagePickerRecipePhotoPicker implements RecipePhotoPicker {
  ImagePickerRecipePhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<RecipePhotoAsset?> pick(RecipePhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == RecipePhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return RecipePhotoAsset(
      bytes: bytes,
      filename: file.name,
      contentType: _contentType(file.name),
    );
  }

  String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

RecipePhotoPicker createRecipePhotoPicker() => ImagePickerRecipePhotoPicker();
