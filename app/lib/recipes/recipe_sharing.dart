import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart' hide RecipeShareLink;

import '../api/api_client.dart';

class RecipeShareLink {
  const RecipeShareLink({required this.url, required this.appPath});
  final String url;
  final String appPath;
}

abstract interface class RecipeSharing {
  Future<RecipeShareLink> create(String recipeId);
  Future<String> resolve(String shareId);
}

class ApiRecipeSharing implements RecipeSharing {
  ApiRecipeSharing(this._api);
  final GramtreeApi _api;

  @override
  Future<RecipeShareLink> create(String recipeId) async {
    final response = await _api.getRecipeSharingApi().createRecipeShare(
      recipeId: recipeId,
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Missing recipe share response');
    }
    final url = Uri.parse(data.url);
    if (url.scheme != 'https' ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        url.path != '/s/${data.shareId}' ||
        url.hasQuery ||
        url.hasFragment) {
      throw const FormatException('Invalid recipe share URL');
    }
    _validatePath(data.appPath, recipeId);
    return RecipeShareLink(url: url.toString(), appPath: data.appPath);
  }

  @override
  Future<String> resolve(String shareId) async {
    final response = await _api.getRecipeSharingApi().resolveRecipeShare(
      shareId: shareId,
      extra: const {'public_request': true},
    );
    final data = response.data;
    if (data == null || data.shareId != shareId) {
      throw const FormatException('Missing recipe share target');
    }
    _validatePath(data.appPath, data.recipeId);
    return data.appPath;
  }

  static void _validatePath(String path, String recipeId) {
    if (recipeId.isEmpty ||
        path != '/recipes/${Uri.encodeComponent(recipeId)}') {
      throw const FormatException('Invalid recipe app path');
    }
  }
}

final recipeSharingProvider = Provider<RecipeSharing>(
  (ref) => ApiRecipeSharing(ref.watch(apiClientProvider)),
);
