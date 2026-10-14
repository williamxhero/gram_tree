import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../ui_protocol/recipe_operations.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../util/ids.dart';
import '../me/taste_profile_data.dart';
import '../recipes/improvement_save.dart';
import '../recipes/recipe_pages.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tab_page.dart';

final recordsProvider = FutureProvider.autoDispose<CookingRecordListOut>((
  ref,
) async {
  ref.watch(authProvider.select((value) => value.value?.id));
  try {
    final response = await ref
        .watch(apiClientProvider)
        .getRecordsApi()
        .listRecords();
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
  bool _saving = false;
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
    final owner = ref.read(authProvider).value?.id;
    if (_saving ||
        record.recipeId == null ||
        record.recipeVersionId == null ||
        owner == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final own = _savedDetail?.author.id == owner;
      final result = own
          ? (await ref
                    .read(apiClientProvider)
                    .getImprovementsApi()
                    .saveRecordVersion(
                      recordId: record.id,
                      recordVersionSaveInput: RecordVersionSaveInput(
                        requestId: _requestId,
                        changeNote: '临场调整',
                      ),
                    ))
                .data
          : await saveImprovementWithChoice(
              context,
              ref,
              recipeId: record.recipeId!,
              versionId: record.recipeVersionId!,
              requestId: _requestId,
              recordId: record.id,
              changeNote: '临场调整',
            );
      if (!mounted ||
          owner != ref.read(authProvider).value?.id ||
          result == null) {
        return;
      }
      ref.invalidate(myRecipesProvider);
      ref.invalidate(tasteProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.recipe == null
                ? '已存进我的口味，没有生成改良版。'
                : own
                ? '已存为我的新一版；公开状态以服务端同步结果为准。'
                : '已存成改良版；公开状态以服务端同步结果为准。',
          ),
        ),
      );
    } catch (error) {
      if (mounted && owner == ref.read(authProvider).value?.id) {
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
        title: Text(record.dishName ?? '做菜记录'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('当时显示的内容快照；来源下架后仍可回看。'),
              if (saved != null) ...[
                Text(
                  '第 ${saved.version.versionNumber} 版 · @${saved.author.nickname}',
                ),
                for (final item
                    in saved.version.snapshot.ingredients ??
                        <RecipeIngredient>[])
                  Text('${item.displayName} ${item.quantity} ${item.unit}'),
                for (final step
                    in saved.version.snapshot.steps ?? <RecipeStep>[])
                  Text(step.instruction),
              ] else
                const Text('这条记录没有保留配方快照。'),
              for (final adjustment in record.adjustments) Text('$adjustment'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
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
                        ? '正在保存…'
                        : own
                        ? '存为我的新一版'
                        : '存成改良版',
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
