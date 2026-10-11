import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../l10n/app_localizations.dart';
import 'event_queue.dart';

class SyncStatus {
  SyncStatus({
    required List<QueueEntry> entries,
    this.ownerId,
    this.lastSuccess,
  }) : entries = List.unmodifiable(
         {
           for (final entry in entries)
             if (ownerId == null || entry.write.ownerId == ownerId)
               entry.write.id: entry,
         }.values,
       );
  final String? ownerId;
  final List<QueueEntry> entries;
  final DateTime? lastSuccess;
  int get pendingCount => entries.where((entry) => entry.needsSync).length;
  List<QueueEntry> get failures =>
      entries.where((entry) => entry.state == WriteState.failed).toList();
  List<QueueEntry> get conflicts =>
      entries.where((entry) => entry.state == WriteState.conflict).toList();

  List<QueueEntry> get unfinished =>
      entries.where((entry) => entry.needsSync).toList();
  int get waitingCount => entries
      .where(
        (entry) =>
            entry.state == WriteState.pending ||
            entry.state == WriteState.uploading,
      )
      .length;
  int get deferredCount =>
      entries.where((entry) => entry.state == WriteState.deferred).length;
  int get loginPausedCount =>
      entries.where((entry) => entry.state == WriteState.loginPaused).length;
  bool get canRetry => manualRetryEntries(entries).isNotEmpty;

  int reasonCount(String code) => entries
      .where(
        (entry) =>
            entry.needsSync &&
            (entry.reasonCode == code ||
                entry.reasonCode?.startsWith('$code:') == true),
      )
      .length;
}

/// Account-specific presentation boundary for #218/#219. No other account's
/// payloads, failure messages or counts are exposed when authentication changes.
final syncStatusProvider = Provider<AsyncValue<SyncStatus>>((ref) {
  final owner = ref.watch(authProvider).value?.id;
  final status = ref.watch(_syncStatusStreamProvider);
  // Riverpod preserves previous stream data while recomputing. Do not let the
  // previous account's cached AsyncValue leak into a new owner's page frame.
  if (status.value != null && status.value!.ownerId != owner) {
    return AsyncData(SyncStatus(entries: const [], ownerId: owner));
  }
  return status;
});

final _syncStatusStreamProvider = StreamProvider<SyncStatus>((ref) async* {
  final owner = ref.watch(authProvider).value?.id;
  if (owner == null) {
    yield SyncStatus(entries: []);
    return;
  }
  final queue = ref.watch(eventQueueProvider);
  Future<SyncStatus> snapshot() async {
    final entries = await queue.entries(ownerId: owner);
    final successes =
        entries
            .where((entry) => entry.state == WriteState.confirmed)
            .map((entry) => entry.confirmedAt)
            .whereType<DateTime>()
            .toList()
          ..sort();
    return SyncStatus(
      ownerId: owner,
      entries: List.unmodifiable(entries),
      lastSuccess: successes.lastOrNull,
    );
  }

  // Subscribe before initial read so a write during loading cannot be missed.
  final events = StreamController<void>();
  final subscription = queue.changes.listen((_) {
    if (ref.mounted) events.add(null);
  });
  ref.onDispose(() {
    subscription.cancel();
    events.close();
  });
  final initial = await snapshot();
  if (!ref.mounted) return;
  yield initial;
  await for (final _ in events.stream) {
    if (!ref.mounted) return;
    final next = await snapshot();
    if (!ref.mounted) return;
    yield next;
  }
});

/// Unlike account delivery status, only unowned migration evidence is device
/// scoped. Keep this boundary count-only, including while signed out.
final _legacyQueueDiagnosticsProvider = StreamProvider<LegacyQueueDiagnostics>((
  ref,
) async* {
  final queue = ref.watch(eventQueueProvider);
  final events = StreamController<void>();
  final subscription = queue.changes.listen((_) {
    if (ref.mounted) events.add(null);
  });
  ref.onDispose(() {
    subscription.cancel();
    events.close();
  });
  final initial = await queue.legacyDiagnostics();
  if (!ref.mounted) return;
  yield initial;
  await for (final _ in events.stream) {
    // Buffered notifications outlive disposal while an earlier query awaits.
    // They must not initiate another request on the closing root's database.
    if (!ref.mounted) return;
    final snapshot = await queue.legacyDiagnostics();
    if (!ref.mounted) return;
    yield snapshot;
  }
});

/// Minimal common marker for page-generated events; the full status screen is
/// #218. Account markers disappear after confirmation; unowned migration
/// evidence remains a separate device-level explanation.
class SyncPendingBadge extends ConsumerWidget {
  const SyncPendingBadge({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider).value;
    final legacy = ref.watch(_legacyQueueDiagnosticsProvider).value;
    final count = status?.pendingCount ?? 0;
    final l10n = AppLocalizations.of(context);
    final diagnostics = <String>[];
    void reason(String code, String Function(int) label) {
      final count = status?.reasonCount(code) ?? 0;
      if (count > 0) diagnostics.add(label(count));
    }

    // Only localized, allowlisted reasons are displayed. A server's arbitrary
    // reason string might contain payloads and must never become UI copy.
    reason('retry_limit_exceeded', l10n.syncRetryExhaustedCount);
    reason('dependency_failed', l10n.syncDependencyFailedCount);
    reason('dependency_conflict', l10n.syncDependencyConflictCount);
    reason('dependency_not_arrived', l10n.syncDependencyMissingCount);
    reason('dependency_cycle', l10n.syncDependencyCycleCount);
    if ((legacy?.ownerUnknownCount ?? 0) > 0) {
      diagnostics.add(
        l10n.syncLegacyOwnerUnknownCount(legacy!.ownerUnknownCount),
      );
    }
    if ((legacy?.rejectedCount ?? 0) > 0) {
      diagnostics.add(l10n.syncLegacyRejectedCount(legacy!.rejectedCount));
    }
    if (count == 0 && diagnostics.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (count > 0)
          Text(
            l10n.syncPendingCount(count),
            key: const ValueKey('sync-pending'),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        for (final diagnostic in diagnostics)
          Text(diagnostic, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
