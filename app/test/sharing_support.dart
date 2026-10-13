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

RecipeDetail sharedDetail() => RecipeDetail.fromJson({
  ...recipeSnapshotFixture(sharedVersionId, recipe: sharedRecipeId).toJson(),
  'visibility': 'public',
  'author': RecipeAuthor(
    id: testUser().id,
    nickname: testUser().nickname,
  ).toJson(),
});

class RecordingSystemShare implements SystemShare {
  final texts = <String>[];
  @override
  Future<void> shareText(String text) async => texts.add(text);
}

class SharingTestEnv extends TestEnv {
  SharingTestEnv({
    bool signedIn = true,
    bool consented = true,
    this.nativeSharing = false,
  }) : super(
         local: MemoryLocalStore(
           consented ? consentedStore() : {'device_id': 'device-test'},
         ),
         secure: MemorySecureStore(signedIn ? signedInSecure(testUser()) : {}),
       ) {
    server.on(
      'GET',
      '/v1/recipes/$sharedRecipeId',
      (_) => (200, sharedDetail().toJson()),
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
