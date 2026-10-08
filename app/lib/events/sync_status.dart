import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../l10n/app_localizations.dart';
import 'event_queue.dart';

class SyncStatus {
  const SyncStatus({required this.entries, this.ownerId, this.lastSuccess});
  final String? ownerId;
  final List<QueueEntry> entries;
  final DateTime? lastSuccess;
  int get pendingCount => entries.where((entry) => entry.needsSync).length;
  List<QueueEntry> get failures =>
      entries.where((entry) => entry.state == WriteState.failed).toList();
  List<QueueEntry> get conflicts =>
      entries.where((entry) => entry.state == WriteState.conflict).toList();

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
    yield const SyncStatus(entries: []);
    return;
  }
  final queue = ref.watch(eventQueueProvider);
  Future<SyncStatus> snapshot() async {
    final entries = await queue.entries(ownerId: owner);
    final successes =
        entries.map((e) => e.confirmedAt).whereType<DateTime>().toList()
          ..sort();
    return SyncStatus(
      ownerId: owner,
      entries: List.unmodifiable(entries),
      lastSuccess: successes.lastOrNull,
    );
  }

  // Subscribe before initial read so a write during loading cannot be missed.
  final events = StreamController<void>();
  final subscription = queue.changes.listen((_) => events.add(null));
  ref.onDispose(() {
    subscription.cancel();
    events.close();
  });
  yield await snapshot();
  await for (final _ in events.stream) {
    yield await snapshot();
  }
});

/// Unlike account delivery status, only unowned migration evidence is device
/// scoped. Keep this boundary count-only, including while signed out.
final _legacyQueueDiagnosticsProvider = StreamProvider<LegacyQueueDiagnostics>((
  ref,
) async* {
  final queue = ref.watch(eventQueueProvider);
  final events = StreamController<void>();
  final subscription = queue.changes.listen((_) => events.add(null));
  ref.onDispose(() {
    subscription.cancel();
    events.close();
  });
  yield await queue.legacyDiagnostics();
  await for (final _ in events.stream) {
    yield await queue.legacyDiagnostics();
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
