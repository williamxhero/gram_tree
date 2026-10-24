import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import '../../events/event_queue.dart';
import '../../events/event_uploader.dart';
import '../../events/sync_status.dart';
import '../../l10n/app_localizations.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/recipe_operations.dart';
import '../../util/ids.dart';
import '../me/taste_profile_data.dart';
import '../recipes/improvement_save.dart';
import '../recipes/recipe_pages.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tab_page.dart';

final recordsProvider = FutureProvider.autoDispose<CookingRecordListOut>((
  ref,
) async {
  final auth = ref.watch(authProvider);
  if (auth.value == null) return CookingRecordListOut(items: const []);
  final session = ref.read(sessionStoreProvider);
  final identity = session.identity;
  if (identity == null) return CookingRecordListOut(items: const []);
  try {
    final response = await ref
        .watch(apiClientProvider)
        .getRecordsApi()
        .listRecords(
          extra: {
            'auth_owner_id': identity.ownerId,
            'auth_identity_epoch': identity.epoch,
          },
        );
    if (!session.matches(identity)) {
      return CookingRecordListOut(items: const []);
    }
    return response.data ?? CookingRecordListOut(items: const []);
  } catch (_) {
    // Keep the tab usable while offline; completed sessions remain in the
    // account-scoped queue and will appear on a later successful refresh.
    return CookingRecordListOut(items: const []);
  }
});

class RecordsPage extends ConsumerWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recordsProvider);
    final queued =
        ref.watch(syncStatusProvider).value?.entries ?? const <QueueEntry>[];
    ref.listen(
      confirmedCookingRecordRevisionProvider,
      (_, _) => ref.invalidate(recordsProvider),
    );
    return TabPage(
      child: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _RecordsError(onRetry: () => ref.invalidate(recordsProvider)),
        data: (page) {
          final byId = <String, (CookingRecordOut, String?, bool)>{
            for (final record in page.items) record.id: (record, null, false),
          };
          for (final entry in queued.where(
            (entry) => entry.write.writeType == 'cooking_record.create',
          )) {
            final raw = entry.write.payload['record'];
            if (raw is! Map || raw['client_id'] is! String) continue;
            final remote = page.items
                .where((record) => record.clientId == raw['client_id'])
                .firstOrNull;
            if (remote == null && entry.state == WriteState.confirmed) continue;
            try {
              final local =
                  remote ??
                  CookingRecordOut.fromJson({
                    ...Map<String, dynamic>.from(raw),
                    'id': raw['client_id'],
                    'created_at': entry.write.deviceTime.toIso8601String(),
                    'verification': 'unverified',
                    'counts_as_cooked': false,
                    'meal': raw['meal'],
                    'taste_summary': <String, Object>{},
                  });
              byId[local.id] = (local, entry.write.id, remote == null);
            } catch (_) {
              // A legacy malformed write remains on the sync page, not a broken record card.
            }
          }
          if (byId.isEmpty) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              title: '还没有做菜记录',
              message: '每次做完菜后的记录和心得会保存在这里。',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text('做过记录', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              for (final (record, writeId, pending) in byId.values)
                _RecordCard(
                  key: ValueKey(record.id),
                  record: record,
                  recordWriteId: writeId,
                  pending: pending,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RecordCard extends ConsumerStatefulWidget {
  const _RecordCard({
    super.key,
    required this.record,
    this.recordWriteId,
    this.pending = false,
  });
  final CookingRecordOut record;
  final String? recordWriteId;
  final bool pending;

  @override
  ConsumerState<_RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends ConsumerState<_RecordCard> {
  bool _saving = false;
  bool _deleting = false;
  final _requestId = newUuidV4();
  CookingRecordOut get record => widget.record;

  RecipeDetail? get _savedDetail {
    final raw = record.snapshot;
    if (raw is! Map || raw['detail'] is! Map) return null;
    try {
      return RecipeDetail.fromJson(
        Map<String, dynamic>.from(raw['detail'] as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    final session = ref.read(sessionStoreProvider);
    final identity = session.identity;
    final owner = identity?.ownerId;
    if (_saving ||
        record.recipeId == null ||
        record.recipeVersionId == null ||
        owner == null ||
        identity == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final own = _savedDetail?.author.id == owner;
      var cancelled = false;
      final result = own
          ? await enqueueRecordImprovementSave(
              ref,
              requestId: _requestId,
              recordId: widget.recordWriteId == null ? record.id : null,
              recordWriteId: widget.recordWriteId,
              recordClientId: record.clientId,
              recipeId: record.recipeId!,
              sourceVersionId: record.recipeVersionId!,
              changeNote: AppLocalizations.of(context).cookingAdjustmentTitle,
            )
          : await saveImprovementWithChoice(
              context,
              ref,
              recipeId: record.recipeId!,
              versionId: record.recipeVersionId!,
              requestId: _requestId,
              recordId: widget.recordWriteId == null ? record.id : null,
              recordWriteId: widget.recordWriteId,
              recordClientId: record.clientId,
              changeNote: AppLocalizations.of(context).cookingAdjustmentTitle,
              onCancelled: () => cancelled = true,
            );
      if (!mounted || !session.matches(identity) || cancelled) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).syncPendingReason),
          ),
        );
        return;
      }
      ref.invalidate(myRecipesProvider);
      ref.invalidate(tasteProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.recipe == null
                ? AppLocalizations.of(context).improvementSavedTaste
                : own
                ? AppLocalizations.of(context).recordSavedVersion
                : AppLocalizations.of(context).recordSavedImprovement,
          ),
        ),
      );
    } catch (error) {
      if (mounted && session.matches(identity)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnapshot() {
    final saved = _savedDetail;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          record.dishName ?? AppLocalizations.of(context).recordCookingTitle,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppLocalizations.of(context).recordSnapshotGuidance),
              if (saved != null) ...[
                Text(
                  AppLocalizations.of(context).recordSnapshotVersion(
                    saved.version.versionNumber,
                    saved.author.nickname,
                  ),
                ),
                for (final item
                    in saved.version.snapshot.ingredients ??
                        <RecipeIngredient>[])
                  Text('${item.displayName} ${item.quantity} ${item.unit}'),
                for (final step
                    in saved.version.snapshot.steps ?? <RecipeStep>[])
                  Text(step.instruction),
              ] else
                Text(AppLocalizations.of(context).recordNoSnapshot),
              for (final adjustment in record.adjustments) Text('$adjustment'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).familyClose),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final session = ref.read(sessionStoreProvider);
    final identity = session.identity;
    if (identity == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这条做菜记录？'),
        content: const Text(
          '记录和修订将从个人历史中删除，经验统计只保留不可关联账号的字段。此操作不可撤回，不影响其他人的记录。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            key: const ValueKey('record-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !session.matches(identity)) return;
    setState(() => _deleting = true);
    try {
      await ref
          .read(apiClientProvider)
          .getRecordsApi()
          .deleteRecord(
            recordId: widget.record.id,
            extra: {
              'auth_owner_id': identity.ownerId,
              'auth_identity_epoch': identity.epoch,
            },
          );
      if (mounted && session.matches(identity)) ref.invalidate(recordsProvider);
    } catch (error) {
      if (mounted && session.matches(identity)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
      }
    } finally {
      if (mounted && session.matches(identity)) {
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final when = DateTime.tryParse(record.occurredAt)?.toLocal();
    final saved = _savedDetail;
    final own = saved?.author.id == ref.watch(authProvider).value?.id;
    final canSave =
        saved != null &&
        record.recipeId != null &&
        record.recipeVersionId != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            key: ValueKey('record-${record.id}'),
            onTap: _showSnapshot,
            leading: const Icon(Icons.restaurant_outlined),
            title: Text(
              record.dishName ??
                  AppLocalizations.of(context).recordUnnamedRecipe,
            ),
            subtitle: Text(
              [
                if (when != null) '${when.year}/${when.month}/${when.day}',
                record.source_ == CookingRecordOutSource_Enum.cookingSession
                    ? AppLocalizations.of(context).recordCookingMode
                    : AppLocalizations.of(context).recordManual,
                if (widget.pending)
                  AppLocalizations.of(context).syncPendingReason,
                if (record.adjustments.isNotEmpty)
                  AppLocalizations.of(context).recordHasAdjustments,
              ].join(' · '),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                record.countsAsCooked
                    ? const Icon(Icons.check_circle_outline)
                    : const Icon(Icons.edit_note),
                if (!widget.pending)
                  IconButton(
                    key: ValueKey('record-delete-${record.id}'),
                    tooltip: '删除记录',
                    onPressed: _deleting ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ),
          if (canSave)
            RecipeOperationScope(
              handlers: {'improvement_save': (_) => _save()},
              child: Builder(
                builder: (context) => TextButton(
                  key: ValueKey('record-improve-${record.id}'),
                  onPressed: _saving
                      ? null
                      : () => ref
                            .read(intentDispatcherProvider)
                            .dispatch(
                              context,
                              compositionId: _requestId,
                              componentId: 'record-improvement',
                              action: ActionDescriptor(
                                intent: 'recipe_operation',
                                params: {'operation': 'improvement_save'},
                              ),
                            ),
                  child: Text(
                    _saving
                        ? AppLocalizations.of(context).recordSaving
                        : own
                        ? AppLocalizations.of(context).recordSaveVersion
                        : AppLocalizations.of(context).recordSaveImprovement,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecordsError extends StatelessWidget {
  const _RecordsError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('记录暂时无法读取'),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('重试')),
      ],
    ),
  );
}
