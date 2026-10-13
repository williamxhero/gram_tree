import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:gram_tree/platform/system_share.dart';
import 'package:gram_tree/storage/local_store.dart';
import 'package:gram_tree/storage/secure_store.dart';
import 'package:gramtree_api/gramtree_api.dart' hide RecipeShareLink;

import 'helpers.dart';
import 'recipe_snapshot_test.dart' show recipeSnapshotFixture;

const sharedRecipeId = '11111111-1111-4111-8111-111111111111';
const sharedVersionId = '22222222-2222-4222-8222-222222222222';
const publicShareId = 'random-public-share';
const publicShareUrl = 'https://gramtree.app/s/$publicShareId';
const sharedImageId = '44444444-4444-4444-8444-444444444444';
// Generated-contract image fixture: a single opaque PNG pixel, not user data.
const testPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl2l9sAAAAASUVORK5CYII=';
final testImageBytes = base64Decode(testPngBase64);

RecipeDetail sharedDetail({bool withImage = false}) => RecipeDetail.fromJson({
  ...recipeSnapshotFixture(sharedVersionId, recipe: sharedRecipeId).toJson(),
  if (withImage)
    'version': {
      ...recipeSnapshotFixture(
        sharedVersionId,
        recipe: sharedRecipeId,
      ).version.toJson(),
      'images': [
        RecipeImageOut(
          byteSize: testImageBytes.length,
          contentType: 'image/png',
          expiresInSeconds: 900,
          id: sharedImageId,
          url: 'https://untrusted.example/image.png',
          versionId: sharedVersionId,
        ).toJson(),
      ],
    },
  'visibility': 'public',
  'author': RecipeAuthor(
    id: testUser().id,
    nickname: testUser().nickname,
  ).toJson(),
});

class RecordingSystemShare implements SystemShare {
  final texts = <String>[];
  final images = <Uint8List?>[];
  @override
  Future<void> shareText(
    String text, {
    Uint8List? imageBytes,
    String? imageContentType,
  }) async {
    texts.add(text);
    images.add(imageBytes);
  }
}

class SharingTestEnv extends TestEnv {
  SharingTestEnv({
    bool signedIn = true,
    bool consented = true,
    this.nativeSharing = false,
    bool publicRecipes = true,
    bool withImage = false,
  }) : super(
         features: {'public_recipes': publicRecipes},
         local: MemoryLocalStore(
           consented ? consentedStore() : {'device_id': 'device-test'},
         ),
         secure: MemorySecureStore(signedIn ? signedInSecure(testUser()) : {}),
       ) {
    server.on(
      'GET',
      '/v1/recipes/$sharedRecipeId',
      (_) => (200, sharedDetail(withImage: withImage).toJson()),
    );
    server.on(
      'GET',
      '/v1/risk/captcha/challenge-123',
      (_) => (
        200,
        {
          'challenge_id': 'challenge-123',
          'prompt': '输入图中的字符',
          'image_data_uri': 'data:image/png;base64,$testPngBase64',
        },
      ),
    );
    server.on(
      'GET',
      '/v1/recipes/$sharedRecipeId/images/$sharedImageId',
      (_) => (200, testImageBytes),
    );
    server.on(
      'POST',
      '/v1/recipes/$sharedRecipeId/share',
      (_) => (
        200,
        {
          'share_id': publicShareId,
          'url': publicShareUrl,
          'app_path': '/recipes/$sharedRecipeId',
        },
      ),
    );
    server.on(
      'GET',
      '/v1/shares/$publicShareId',
      (_) => (
        200,
        {
          'share_id': publicShareId,
          'recipe_id': sharedRecipeId,
          'app_path': '/recipes/$sharedRecipeId',
        },
      ),
    );
  }
  final bool nativeSharing;
  final sharing = RecordingSystemShare();
  @override
  List<Override> get overrides => [
    ...super.overrides,
    if (!nativeSharing) systemShareProvider.overrideWithValue(sharing),
  ];
}
