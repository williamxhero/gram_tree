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
    final image = await ref.read(shareImageProvider)(link);
    if (!ref.mounted || !session.matches(identity)) return false;
    imageBytes = image.$1;
    imageContentType = image.$2 ?? imageContentType;
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

/// Reuse the approved share's selected image, not a snapshot-supplied URL.
/// Only the validated share path is used on the configured API origin; public
/// requests send no credentials and never follow redirects to another origin.
final shareImageProvider =
    Provider<Future<(Uint8List, String?)> Function(RecipeShareLink)>((ref) {
      final dio = ref.watch(dioProvider);
      return (link) async {
        final response = await dio.get<List<int>>(
          '${Uri.parse(link.url).path}/image',
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            extra: const {'public_request': true},
          ),
        );
        final bytes = response.data;
        if (bytes == null || bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
          throw const FormatException('Invalid recipe share image');
        }
        // The public route selects the newest approved image, which need not
        // have the same MIME type as the snapshot image used to show the button.
        return (
          Uint8List.fromList(bytes),
          response.headers.value('content-type'),
        );
      };
    });
