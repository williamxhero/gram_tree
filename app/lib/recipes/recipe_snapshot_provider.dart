import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../privacy/consent.dart';
import '../storage/local_store.dart';
import 'recipe_snapshot.dart';

/// Configurable byte budget including metadata and frozen protection copies.
/// Protected content may exceed it, with explicit SnapshotCapacity feedback.
final recipeSnapshotMaxBytesProvider = Provider<int>(
  (ref) => const int.fromEnvironment(
    'RECIPE_SNAPSHOT_MAX_BYTES',
    defaultValue: 20 * 1024 * 1024,
  ),
);

/// Anonymous/other accounts cannot read personal quantities from an old owner.
final recipeSnapshotStoreProvider = Provider<RecipeSnapshotStore?>((ref) {
  final accountId = ref.watch(authProvider.select((auth) => auth.value?.id));
  if (accountId == null || !ref.watch(privacyConsentProvider)) return null;
  final store = RecipeSnapshotStore(
    ref.watch(localStoreProvider),
    accountId: accountId,
    maxBytes: ref.watch(recipeSnapshotMaxBytesProvider),
  );
  ref.listen(privacyConsentProvider, (_, consented) {
    if (!consented) unawaited(store.clear());
  });
  return store;
});
