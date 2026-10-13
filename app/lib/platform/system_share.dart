import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/session.dart';
import '../features_flags/features.dart';
import '../recipes/recipe_sharing.dart';

import 'system_share_stub.dart'
    if (dart.library.io) 'system_share_mobile.dart'
    if (dart.library.js_interop) 'system_share_web.dart';

abstract interface class SystemShare {
  Future<void> shareText(
    String text, {
    Uint8List? imageBytes,
    String? imageContentType,
  });
}

final systemShareProvider = Provider<SystemShare>((ref) => createSystemShare());

SystemShare createSystemShare() => createPlatformSystemShare();

/// The registered share intent owns the whole asynchronous handoff. A rotated
/// credential is allowed; another login generation must never receive the panel.
Future<bool> shareRecipe(
  Ref ref, {
  required String recipeId,
  String? imageId,
  String? imageContentType,
}) async {
  if (!ref.read(featureEnabledProvider(Feature.publicRecipes))) return false;
  final session = ref.read(sessionStoreProvider);
  final identity = session.identity;
  if (identity == null) return false;
  final link = await ref.read(recipeSharingProvider).create(recipeId);
  if (!ref.mounted || !session.matches(identity)) return false;
  Uint8List? imageBytes;
  if (!kIsWeb && imageId != null) {
    imageBytes = await ref.read(shareImageProvider)(recipeId, imageId);
    if (!ref.mounted || !session.matches(identity)) return false;
  }
  await ref
      .read(systemShareProvider)
      .shareText(
        link.url,
        imageBytes: imageBytes,
        imageContentType: imageContentType,
      );
  return true;
}

/// Download only the recipe image API, never a snapshot-supplied absolute URL.
/// Credentials remain on the configured API origin and cross-origin redirects
/// are disabled. The native panel receives bytes, not a remotely supplied URI.
final shareImageProvider = Provider<Future<Uint8List> Function(String, String)>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return (recipeId, imageId) async {
    final response = await dio.get<List<int>>(
      '/v1/recipes/${Uri.encodeComponent(recipeId)}/images/${Uri.encodeComponent(imageId)}',
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
      ),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
      throw const FormatException('Invalid recipe share image');
    }
    return Uint8List.fromList(bytes);
  };
});
