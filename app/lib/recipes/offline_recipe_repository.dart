import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../auth/auth_controller.dart';
import '../events/event_queue.dart';
import '../events/write_registry.dart';
import '../privacy/consent.dart';
import '../util/ids.dart';
import 'recipe_repository.dart';

const recipeVersionWriteType = 'recipe_version.save';

WriteRegistration get recipeVersionWriteRegistration => WriteRegistration(
  type: recipeVersionWriteType,
  conflictRule: WriteConflictRule.preserveBoth,
  validate: (payload) {
    if (payload['recipe_id'] is! String ||
        payload['candidate_version_id'] is! String ||
        (payload['baseline_version_id'] == null) ==
            (payload['baseline_write_id'] == null)) {
      throw ArgumentError('A recipe save requires exactly one stable baseline');
    }
    final candidate = RecipeVersionCreate.fromJson(payload['candidate']);
    if (candidate.aiAssisted == true ||
        (candidate.imageIds?.isNotEmpty ?? false)) {
      throw ArgumentError('Only manual recipe versions can be saved offline');
    }
    final snapshot = candidate.snapshot;
    final ingredients = snapshot.ingredients ?? const <RecipeIngredient>[];
    final steps = snapshot.steps ?? const <RecipeStep>[];
    final ingredientIds = ingredients.map((item) => item.id).toSet();
    final stepIds = steps.map((item) => item.id).toSet();
    if (snapshot.servings < 1 ||
        ingredientIds.length != ingredients.length ||
        stepIds.length != steps.length ||
        ingredients.any(
          (item) =>
              !item.quantity.isFinite ||
              item.quantity < 0 ||
              item.displayName.trim().isEmpty ||
              item.unit.trim().isEmpty,
        ) ||
        steps.any(
          (step) =>
              step.instruction.trim().isEmpty ||
              (step.ingredientIds ?? const []).any(
                (id) => !ingredientIds.contains(id),
              ) ||
              (step.dependsOn ?? const []).any((id) => !stepIds.contains(id)),
        )) {
      throw ArgumentError('Invalid structured recipe');
    }
    final visiting = <String>{};
    final visited = <String>{};
    final byId = {for (final step in steps) step.id: step};
    void visit(String id) {
      if (visiting.contains(id)) throw ArgumentError('Cyclic recipe steps');
      if (visited.contains(id)) return;
      visiting.add(id);
      for (final dependency in byId[id]!.dependsOn ?? const <String>[]) {
        visit(dependency);
      }
      visiting.remove(id);
      visited.add(id);
    }

    for (final id in stepIds) {
      visit(id);
    }
  },
  applyResult: (record, result) {
    if (record == null || result['resource_type'] != 'recipe.version') {
      throw StateError('Recipe confirmation has no retained candidate');
    }
    final values = result['values'] as Map?;
    if (values?['detail'] is! Map<String, dynamic>) {
      throw StateError('Recipe confirmation has no server detail');
    }
    final detail = RecipeDetail.fromJson(values!['detail']);
    if (detail.id != record['recipe_id'] ||
        detail.version.id != record['candidate_version_id'] ||
        result['resource_id'] != detail.version.id) {
      throw StateError('Recipe confirmation does not match its candidate');
    }
    return {...record, 'detail': detail.toJson()};
  },
);

/// The retained queue business record is the authority for a local saved
/// version. The disposable frozen execution cache is never updated in its place.
class LocalRecipeVersion {
  LocalRecipeVersion(this.entry, this.detail);
  final QueueEntry entry;
  final RecipeDetail detail;
  bool get pending => entry.state != WriteState.confirmed;
  String get status => switch (entry.state) {
    WriteState.conflict => '等待处理：两份修改均已保留',
    WriteState.failed => '同步失败：${entry.reasonCode ?? '请重试'}',
    WriteState.loginPaused => '待同步：请重新登录',
    WriteState.deferred => '待同步：等待前置版本',
    WriteState.confirmed => '已同步',
    _ => '待同步',
  };
}

class OfflineRecipeRepository {
  OfflineRecipeRepository(this.queue, this.ownerId);
  final EventQueue queue;
  final String ownerId;

  Future<List<LocalRecipeVersion>> versions() async => [
    for (final entry in await queue.entries(ownerId: ownerId))
      if (entry.write.writeType == recipeVersionWriteType &&
          entry.businessRecord?['detail'] != null)
        LocalRecipeVersion(
          entry,
          RecipeDetail.fromJson(entry.businessRecord!['detail']),
        ),
  ];

  Future<LocalRecipeVersion?> read(
    String recipeId, {
    String? versionId,
    bool pendingOnly = false,
  }) async {
    final matching = (await versions())
        .where(
          (version) =>
              version.detail.id == recipeId &&
              (!pendingOnly || version.pending) &&
              (versionId == null || version.detail.version.id == versionId),
        )
        .toList();
    matching.sort((a, b) => b.entry.sequence.compareTo(a.entry.sequence));
    return matching.firstOrNull;
  }

  Future<LocalRecipeVersion> save(
    RecipeDetail baseline,
    RecipeForm form,
  ) async {
    if (baseline.author.id != ownerId || form.imageIds.isNotEmpty) {
      throw StateError(
        'This recipe cannot be saved offline by the current account',
      );
    }
    final candidate = RecipeVersionCreate(
      snapshot: form.snapshot,
      changeNote: form.changeNote,
      aiAssisted: false,
    ).toJson();
    // A crash after atomic enqueue but before leaving the editor must resume
    // the same saved version rather than make another one from its old draft.
    final existing = await versions();
    for (final version in existing.reversed) {
      if (version.entry.businessRecord?['baseline_version_id'] ==
              baseline.version.id &&
          jsonEncode(version.entry.write.payload['candidate']) ==
              jsonEncode(candidate)) {
        return version;
      }
    }
    final producer = existing
        .where((version) => version.detail.version.id == baseline.version.id)
        .firstOrNull;
    final writeId = newUuidV4();
    final candidateId = newUuidV4();
    final now = DateTime.now().toUtc();
    final detailJson = baseline.toJson();
    detailJson['updated_at'] = now.toIso8601String();
    final versionJson = Map<String, dynamic>.from(detailJson['version'] as Map);
    versionJson.addAll({
      'id': candidateId, 'previous_version_id': baseline.version.id,
      'version_number': baseline.version.versionNumber + 1,
      'snapshot': form.snapshot.toJson(), 'change_note': form.changeNote,
      'ai_assisted': false, 'created_at': now.toIso8601String(),
      'edit_operations': [],
      'reproducibility': null,
      'safety': null,
      'safety_at_save': null,
      // Derived estimates and policy checks belong to the server. Never copy
      // stale nutrition/safety evidence onto the manually changed candidate.
      'derived': RecipeDerived(
        totalTimeSeconds: 0,
        activeTimeSeconds: 0,
      ).toJson(),
    });
    detailJson['version'] = versionJson;
    final payload = <String, dynamic>{
      'recipe_id': baseline.id,
      'candidate_version_id': candidateId,
      if (producer != null)
        'baseline_write_id': producer.entry.write.id
      else
        'baseline_version_id': baseline.version.id,
      'candidate': candidate,
    };
    final write = QueuedEvent.write(
      id: writeId,
      ownerId: ownerId,
      deviceTime: now,
      writeType: recipeVersionWriteType,
      payload: payload,
      dependencies: producer == null ? const [] : [producer.entry.write.id],
    );
    await queue.enqueue(
      write,
      businessRecord: {
        'recipe_id': baseline.id,
        'candidate_version_id': candidateId,
        'baseline_version_id': baseline.version.id,
        'detail': detailJson,
      },
    );
    return (await read(baseline.id, versionId: candidateId))!;
  }
}

final offlineRecipeRepositoryProvider = Provider<OfflineRecipeRepository?>((
  ref,
) {
  final owner = ref.watch(authProvider).value?.id;
  if (owner == null || !ref.watch(privacyConsentProvider)) return null;
  return OfflineRecipeRepository(ref.watch(eventQueueProvider), owner);
});

final localRecipeVersionsProvider = StreamProvider<List<LocalRecipeVersion>>((
  ref,
) async* {
  final repository = ref.watch(offlineRecipeRepositoryProvider);
  if (repository == null) {
    yield const [];
    return;
  }
  yield await repository.versions();
  await for (final _ in repository.queue.changes) {
    yield await repository.versions();
  }
});
