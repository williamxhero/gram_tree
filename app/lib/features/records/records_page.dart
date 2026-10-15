import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
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
    return TabPage(
      child: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _RecordsError(onRetry: () => ref.invalidate(recordsProvider)),
        data: (page) => page.items.isEmpty
            ? const EmptyState(
                icon: Icons.menu_book_outlined,
                title: '还没有做菜记录',
                message: '每次做完菜后的记录和心得会保存在这里。',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  Text(
                    '做过记录',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  for (final record in page.items)
                    _RecordCard(key: ValueKey(record.id), record: record),
                ],
              ),
      ),
    );
  }
}

class _RecordCard extends ConsumerStatefulWidget {
  const _RecordCard({super.key, required this.record});
  final CookingRecordOut record;

  @override
  ConsumerState<_RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends ConsumerState<_RecordCard> {
  bool _deleting = false;

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
    final record = widget.record;
    final when = DateTime.tryParse(record.occurredAt)?.toLocal();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          record.countsAsCooked ? Icons.check_circle_outline : Icons.edit_note,
        ),
        title: Text(record.dishName ?? '未命名菜谱'),
        subtitle: Text(
          [
            if (when != null) '${when.year}/${when.month}/${when.day}',
            record.source_ == CookingRecordOutSource_Enum.cookingSession
                ? '做菜模式'
                : '手动记录',
            if (record.adjustments.isNotEmpty) '有临时调整',
          ].join(' · '),
        ),
        trailing: IconButton(
          key: ValueKey('record-delete-${record.id}'),
          tooltip: '删除记录',
          onPressed: _deleting ? null : _delete,
          icon: const Icon(Icons.delete_outline),
        ),
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
