import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/event_queue.dart';
import '../../events/event_uploader.dart';
import '../../events/sync_status.dart';
import '../../l10n/app_localizations.dart';
import '../../ui_protocol/source_mark.dart';

/// One view of the persisted delivery queue, not a second business-state store.
class SyncStatusPage extends ConsumerStatefulWidget {
  const SyncStatusPage({super.key});
  static const path = '/me/sync';

  @override
  ConsumerState<SyncStatusPage> createState() => _SyncStatusPageState();
}

class _SyncStatusPageState extends ConsumerState<SyncStatusPage> {
  bool _retrying = false;
  String? _retryError;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() {
      _retrying = true;
      _retryError = null;
    });
    final owner = ref.read(syncStatusProvider).value?.ownerId;
    try {
      await ref.read(eventUploaderProvider).retryCurrentAccount();
    } catch (_) {
      // A raw storage/network exception can contain private data.
      if (mounted && ref.read(syncStatusProvider).value?.ownerId == owner) {
        setState(
          () => _retryError = AppLocalizations.of(context).syncRetryError,
        );
      }
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncStatus = ref.watch(syncStatusProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncStatusTitle)),
      body: asyncStatus.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.syncLoadingError)),
        data: (status) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.syncUnfinishedCount(status.pendingCount),
              key: const ValueKey('sync-unfinished-count'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              status.lastSuccess == null
                  ? l10n.syncNever
                  : l10n.syncLastSuccess(
                      status.lastSuccess!.toLocal().toString(),
                    ),
              key: const ValueKey('sync-last-success'),
            ),
            const SizedBox(height: 8),
            SourceMark(
              sourceType: 'author_filled',
              componentId: 'sync_status',
              value: l10n.syncUnfinishedCount(status.pendingCount),
              basisText: l10n.syncBasis,
              required: true,
              feedbackEnabled: false,
              neutral: true,
              showWhenAuthorFilled: true,
              labelOverride: l10n.syncQueueSource,
              onAction: null,
            ),
            const SizedBox(height: 16),
            for (final category in [
              (l10n.syncWaiting, status.waitingCount),
              (l10n.syncDeferred, status.deferredCount),
              (l10n.syncLoginPaused, status.loginPausedCount),
              (l10n.syncConflict, status.conflicts.length),
              (l10n.syncFailed, status.failures.length),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(l10n.syncCategoryCount(category.$1, category.$2)),
              ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('sync-manual-retry'),
              onPressed: !_retrying && status.canRetry ? _retry : null,
              child: Text(l10n.syncRetryAction),
            ),
            if (_retryError != null) Text(_retryError!),
            const SizedBox(height: 16),
            for (final entry in status.unfinished)
              Card(
                key: ValueKey('sync-item-${entry.write.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.syncItemIdentity(
                          _typeLabel(entry, l10n),
                          entry.sequence,
                        ),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(_diagnosis(entry, l10n)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _typeLabel(QueueEntry entry, AppLocalizations l10n) =>
    switch (entry.write.writeType) {
      'experience.event' => l10n.syncEventType,
      'recipe.save' ||
      'recipe.version' ||
      'recipe.draft' => l10n.syncRecipeType,
      'personal_measure.fields' ||
      'personal_measure.update' => l10n.syncMeasureType,
      _ => l10n.syncOtherType,
    };

String _diagnosis(QueueEntry entry, AppLocalizations l10n) {
  final reason = entry.reasonCode?.split(':').first;
  if (entry.state == WriteState.conflict || reason == 'dependency_conflict') {
    return l10n.syncConflictReason;
  }
  if (entry.state == WriteState.loginPaused) return l10n.syncLoginReason;
  return switch (reason) {
    'retry_limit_exceeded' => l10n.syncExhaustedReason,
    'network_or_server_failure' ||
    'invalid_or_lost_response' => l10n.syncNetworkReason,
    'dependency_cycle' => l10n.syncDependencyCycleReason,
    'dependency_failed' ||
    'dependency_not_arrived' ||
    'dependency_not_confirmed' => l10n.syncDependencyReason,
    'forbidden' ||
    'invalid_content' ||
    'owner_mismatch' ||
    'dependency_unavailable' ||
    'write_id_unavailable' ||
    'write_id_reused' ||
    'unknown_write_type' ||
    'write_rejected' => l10n.syncPermissionReason,
    _ => switch (entry.state) {
      WriteState.uploading => l10n.syncUploadingReason,
      WriteState.failed => l10n.syncUnknownReason,
      WriteState.deferred => l10n.syncDependencyReason,
      _ => l10n.syncPendingReason,
    },
  };
}
