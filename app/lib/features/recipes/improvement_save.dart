import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../auth/auth_controller.dart';
import '../../recipes/recipe_repository.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/recipe_operations.dart';
import 'comparison_cards.dart';

/// Both form and confirmed one-line proposals use the same server comparison,
/// explicit microadjust choice and retry key. Cancelling never commits a branch.
Future<ImprovementSaveOut?> saveImprovementWithChoice(
  BuildContext context,
  WidgetRef ref, {
  required String recipeId,
  required String versionId,
  required String requestId,
  RecipeSnapshot? snapshot,
  String? modificationId,
  int? modificationRevision,
  String? recordId,
  String changeNote = '',
  String? explanationFingerprint,
}) async {
  final owner = ref.read(authProvider).value?.id;
  if (owner == null) return null;
  bool sameAccount() =>
      context.mounted && ref.read(authProvider).value?.id == owner;
  final repository = ref.read(recipeRepositoryProvider);
  final preview = await repository.previewImprovement(
    recipeId,
    ImprovementPreviewInput(
      sourceVersionId: versionId,
      snapshot: snapshot,
      modificationRequestId: modificationId,
      modificationRevision: modificationRevision,
      fromCookingRecordId: recordId,
      changeNote: changeNote,
      explanationFingerprint: explanationFingerprint,
    ),
  );
  if (!context.mounted || !sameAccount()) return null;
  String? choice;
  if (preview.microadjustPrompt != null) {
    choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => RecipeOperationScope(
        handlers: {
          'improvement_taste': (_) => Navigator.pop(dialogContext, 'taste'),
          'improvement_branch': (_) => Navigator.pop(dialogContext, 'branch'),
        },
        child: Builder(
          builder: (context) {
            Future<void> dispatch(String operation) => ref
                .read(intentDispatcherProvider)
                .dispatch(
                  context,
                  compositionId: requestId,
                  componentId: 'microadjust-choice',
                  action: ActionDescriptor(
                    intent: 'recipe_operation',
                    params: {'operation': operation},
                  ),
                );
            final proposal = preview.tasteProposal;
            return AlertDialog(
              title: Text(preview.microadjustPrompt!),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '依据：${comparisonConclusionLabel(preview.comparison.conclusion.value)}；确定性规则判定，与来源精确版本比较。',
                    ),
                    if (proposal.convertible) ...[
                      Text('拟更新口味档案第 ${proposal.profileVersion} 版：'),
                      Text('${proposal.coefficients}'),
                      const Text('确认后只更新我的口味，不生成菜谱。'),
                    ] else
                      Text(proposal.reason ?? '这些微调不能安全转换为口味系数，可坚持保存微调分支。'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                OutlinedButton(
                  key: const ValueKey('improvement-save-taste'),
                  onPressed: proposal.convertible
                      ? () => dispatch('improvement_taste')
                      : null,
                  child: const Text('存进我的口味'),
                ),
                FilledButton(
                  key: const ValueKey('improvement-save-branch'),
                  onPressed: () => dispatch('improvement_branch'),
                  child: const Text('仍然保存'),
                ),
              ],
            );
          },
        ),
      ),
    );
    if (choice == null || !sameAccount()) return null;
  }
  return repository.saveImprovement(
    recipeId,
    ImprovementSaveInput(
      requestId: requestId,
      sourceVersionId: versionId,
      snapshot: snapshot,
      modificationRequestId: modificationId,
      modificationRevision: modificationRevision,
      fromCookingRecordId: recordId,
      changeNote: changeNote,
      explanationFingerprint: explanationFingerprint,
      microadjustChoice: switch (choice) {
        'taste' => ImprovementSaveInputMicroadjustChoiceEnum.taste,
        'branch' => ImprovementSaveInputMicroadjustChoiceEnum.branch,
        _ => null,
      },
      expectedProfileVersion: choice == 'taste'
          ? preview.tasteProposal.profileVersion
          : null,
    ),
  );
}
