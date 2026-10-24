import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../auth/session.dart';
import '../../events/event_queue.dart';
import '../../events/event_uploader.dart';
import '../../events/write_registry.dart';
import '../../util/ids.dart';
import '../../recipes/recipe_repository.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/recipe_operations.dart';
import 'comparison_cards.dart';
import '../../l10n/app_localizations.dart';

final _recordSaveLocks = Expando<Future<void>>();

// Serialize retained-ID discovery across simultaneously mounted record cards.
Future<T> _serializeRecordSave<T>(
  EventQueue queue,
  Future<T> Function() action,
) async {
  final previous = _recordSaveLocks[queue];
  final completion = Completer<void>();
  _recordSaveLocks[queue] = completion.future;
  await previous;
  try {
    return await action();
  } finally {
    completion.complete();
  }
}

// Persist the retry ID before delivery so response loss cannot create a second version.
Future<ImprovementSaveOut?> enqueueRecordImprovementSave(
  WidgetRef ref, {
  required String requestId,
  String? recordId,
  String? recordWriteId,
  String? recordClientId,
  required String recipeId,
  required String sourceVersionId,
  required String changeNote,
  String? microadjustChoice,
  int? expectedProfileVersion,
  ValueChanged<ImprovementPreviewOut>? onPreview,
}) async {
  final identity = ref.read(sessionStoreProvider).identity;
  if (identity == null) return null;
  final session = ref.read(sessionStoreProvider);
  final payload = <String, dynamic>{
    'record_id': ?recordId,
    'record_write_id': ?recordWriteId,
    'recipe_id': recipeId,
    'source_version_id': sourceVersionId,
    'change_note': changeNote,
    'microadjust_choice': ?microadjustChoice,
    'expected_profile_version': ?expectedProfileVersion,
  };
  final queue = ref.read(eventQueueProvider);
  final write = await _serializeRecordSave<QueuedEvent?>(queue, () async {
    final entries = await queue.entries(ownerId: identity.ownerId);
    final resourceIds = <String>{?recordId};
    final producerIds = <String>{?recordWriteId};
    for (final entry in entries.where(
      (entry) => entry.write.writeType == 'cooking_record.create',
    )) {
      final record = entry.write.payload['record'];
      final resourceId = entry.result?['resource_id'];
      if (producerIds.contains(entry.write.id) ||
          (recordClientId != null &&
              record is Map &&
              record['client_id'] == recordClientId) ||
          resourceIds.contains(resourceId)) {
        producerIds.add(entry.write.id);
        if (resourceId is String) resourceIds.add(resourceId);
      }
    }
    final existing = entries.where((entry) {
      final retained = entry.write.payload;
      final sameRecord =
          (recordClientId != null &&
              entry.businessRecord?['record_client_id'] == recordClientId) ||
          resourceIds.contains(retained['record_id']) ||
          producerIds.contains(retained['record_write_id']);
      return entry.write.writeType == recordImprovementWriteType &&
          sameRecord &&
          retained['recipe_id'] == recipeId &&
          retained['source_version_id'] == sourceVersionId &&
          retained['change_note'] == changeNote &&
          (microadjustChoice == null ||
              (retained['microadjust_choice'] == microadjustChoice &&
                  retained['expected_profile_version'] ==
                      expectedProfileVersion));
    }).toList()..sort((a, b) => b.sequence.compareTo(a.sequence));
    final latest = existing.firstOrNull;
    final refreshRejectedTaste =
        microadjustChoice == null &&
        latest?.state == WriteState.failed &&
        latest?.reasonCode == 'profile_changed';
    final write =
        (refreshRejectedTaste ? null : latest?.write) ??
        QueuedEvent.write(
          id: refreshRejectedTaste ? newUuidV4() : requestId,
          ownerId: identity.ownerId,
          deviceTime: DateTime.now().toUtc(),
          writeType: recordImprovementWriteType,
          payload: payload,
          dependencies: recordWriteId == null ? const [] : [recordWriteId],
        );
    if (!session.matches(identity)) return null;
    await queue.enqueue(
      write,
      businessRecord: {
        'record_id': ?recordId,
        'record_write_id': ?recordWriteId,
        'record_client_id': ?recordClientId,
        'recipe_id': recipeId,
        'source_version_id': sourceVersionId,
        'request_id': write.id,
      },
    );
    return write;
  });
  if (write == null || !ref.context.mounted || !session.matches(identity)) {
    return null;
  }
  await ref.read(eventUploaderProvider).triggerUpload(waitForDrain: true);
  if (!ref.context.mounted || !session.matches(identity)) return null;
  final entry = (await queue.entries(ownerId: identity.ownerId))
      .where((candidate) => candidate.write.id == write.id)
      .firstOrNull;
  if (entry == null) return null;
  if (entry.state == WriteState.failed || entry.state == WriteState.conflict) {
    throw StateError(
      'Record improvement requires attention: ${entry.reasonCode}',
    );
  }
  if (entry.state != WriteState.confirmed || entry.result == null) return null;
  final values = entry.result!['values'];
  final preview = values is Map ? values['preview'] : null;
  if (preview is Map) {
    onPreview?.call(
      ImprovementPreviewOut.fromJson(Map<String, dynamic>.from(preview)),
    );
  }
  final response = values is Map ? values['response'] : null;
  return response is Map
      ? ImprovementSaveOut.fromJson(Map<String, dynamic>.from(response))
      : null;
}

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
  String? recordWriteId,
  String? recordClientId,
  String changeNote = '',
  String? explanationFingerprint,
  VoidCallback? onCancelled,
}) async {
  final session = ref.read(sessionStoreProvider);
  final identity = session.identity;
  if (identity == null) return null;
  bool sameAccount() => context.mounted && session.matches(identity);
  final repository = ref.read(recipeRepositoryProvider);
  ImprovementPreviewOut? recordPreview;
  if (recordId != null || recordWriteId != null) {
    final saved = await enqueueRecordImprovementSave(
      ref,
      requestId: requestId,
      recordId: recordId,
      recordWriteId: recordWriteId,
      recordClientId: recordClientId,
      recipeId: recipeId,
      sourceVersionId: versionId,
      changeNote: changeNote,
      onPreview: (value) => recordPreview = value,
    );
    if (saved != null || recordPreview == null || !sameAccount()) return saved;
  }
  final preview =
      recordPreview ??
      await repository.previewImprovement(
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
    if (choice == null) {
      onCancelled?.call();
      return null;
    }
    if (!sameAccount()) return null;
  }
  if (recordId != null || recordWriteId != null) {
    return enqueueRecordImprovementSave(
      ref,
      requestId: newUuidV4(),
      recordId: recordId,
      recordWriteId: recordWriteId,
      recordClientId: recordClientId,
      recipeId: recipeId,
      sourceVersionId: versionId,
      changeNote: changeNote,
      microadjustChoice: choice,
      expectedProfileVersion: choice == 'taste'
          ? preview.tasteProposal.profileVersion
          : null,
    );
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
