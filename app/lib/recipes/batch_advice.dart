import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'recipe_repository.dart';

// A request is scoped to the exact immutable version and serving selection.
// Disposing that selection also discards any late response.
typedef BatchAdviceTarget = ({String recipeId, String versionId, int servings});

class BatchAdviceRequest extends Notifier<AsyncValue<RecipeBatchAdviceOut>?> {
  BatchAdviceRequest(this.target);

  final BatchAdviceTarget target;

  @override
  AsyncValue<RecipeBatchAdviceOut>? build() {
    ref.watch(recipeRepositoryProvider);
    return null;
  }

  Future<void> request() async {
    if (state?.isLoading == true) return;
    state = const AsyncLoading();
    try {
      final result = await ref
          .read(recipeRepositoryProvider)
          .batchAdvice(target.recipeId, target.versionId, target.servings);
      if (!ref.mounted) return;
      state = AsyncData(result);
    } catch (error, stack) {
      if (!ref.mounted) return;
      state = AsyncError(error, stack);
    }
  }
}

final batchAdviceProvider = NotifierProvider.autoDispose
    .family<
      BatchAdviceRequest,
      AsyncValue<RecipeBatchAdviceOut>?,
      BatchAdviceTarget
    >(BatchAdviceRequest.new);

bool validateBatchAdviceParams(Map<String, dynamic> params) =>
    params['recipe_id'] is String &&
    (params['recipe_id'] as String).isNotEmpty &&
    params['version_id'] is String &&
    (params['version_id'] as String).isNotEmpty &&
    params['target_servings'] is int &&
    (params['target_servings'] as int) > 0;

Future<void> handleBatchAdvice(
  BuildContext context,
  Ref ref,
  Map<String, dynamic> params,
) => ref
    .read(
      batchAdviceProvider((
        recipeId: params['recipe_id'] as String,
        versionId: params['version_id'] as String,
        servings: params['target_servings'] as int,
      )).notifier,
    )
    .request();
