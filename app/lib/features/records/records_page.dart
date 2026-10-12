import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tab_page.dart';

final recordsProvider = FutureProvider.autoDispose<CookingRecordListOut>((
  ref,
) async {
  final response = await ref
      .watch(apiClientProvider)
      .getRecordsApi()
      .listRecords();
  return response.data ?? CookingRecordListOut(items: const []);
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
                  for (final record in page.items) _RecordCard(record: record),
                ],
              ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});
  final CookingRecordOut record;

  @override
  Widget build(BuildContext context) {
    final when = DateTime.tryParse(record.occurredAt)?.toLocal();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.restaurant_outlined),
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
        trailing: record.countsAsCooked
            ? const Icon(Icons.check_circle_outline)
            : const Icon(Icons.edit_note),
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
