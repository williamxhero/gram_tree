import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../auth/auth_controller.dart';
import '../../recipes/recipe_repository.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/recipe_operations.dart';
import 'comparison_cards.dart';
import '../../l10n/app_localizations.dart';

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
            final l10n = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(preview.microadjustPrompt!),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.improvementChoiceBasis(
                        comparisonConclusionLabel(
                          preview.comparison.conclusion.value,
                        ),
                      ),
                    ),
                    if (proposal.convertible) ...[
                      Text(
                        l10n.improvementProfileProposal(
                          '${proposal.profileVersion}',
                        ),
                      ),
                      Text('${proposal.coefficients}'),
                      Text(l10n.improvementTasteOnly),
                    ] else
                      Text(proposal.reason ?? l10n.improvementTasteUnavailable),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                OutlinedButton(
                  key: const ValueKey('improvement-save-taste'),
                  onPressed: proposal.convertible
                      ? () => dispatch('improvement_taste')
                      : null,
                  child: Text(l10n.improvementSaveTaste),
                ),
                FilledButton(
                  key: const ValueKey('improvement-save-branch'),
                  onPressed: () => dispatch('improvement_branch'),
                  child: Text(l10n.improvementSaveBranch),
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
