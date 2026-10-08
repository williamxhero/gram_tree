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

/// Minimal common marker for page-generated events; the full status screen is
/// #218. Hidden after all this account's entries have been confirmed.
class SyncPendingBadge extends ConsumerWidget {
  const SyncPendingBadge({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(syncStatusProvider).value?.pendingCount ?? 0;
    return count == 0
        ? const SizedBox.shrink()
        : Text(
            AppLocalizations.of(context).syncPendingCount(count),
            key: const ValueKey('sync-pending'),
            style: Theme.of(context).textTheme.labelSmall,
          );
  }
}
