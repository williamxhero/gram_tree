import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../app/theme.dart';
import '../../auth/auth_controller.dart';
import '../../auth/session.dart';
import '../../l10n/app_localizations.dart';
import '../../recipes/personal_measure_repository.dart';
import '../../ui_protocol/components/component_scaffold.dart';

class PersonalMeasuresPage extends ConsumerWidget {
  const PersonalMeasuresPage({super.key});

  static const path = '/me/measures';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = GramTreeColors.of(context);
    final measures = ref.watch(personalMeasuresProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.personalMeasuresTitle)),
      body: measures.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ApiFailure.from(error).message),
              TextButton(
                onPressed: () => ref.invalidate(personalMeasuresProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async {
            final session = ref.read(sessionStoreProvider);
            final identity = session.identity;
            try {
              ref.invalidate(personalMeasuresProvider);
              await ref.read(personalMeasuresProvider.future);
            } catch (_) {
              // A disposed old-owner refresh may be cancelled by privacy cleanup.
              if (context.mounted &&
                  identity != null &&
                  session.matches(identity)) {
                rethrow;
              }
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Text(l10n.personalMeasuresIntro),
              const SizedBox(height: 12),
              if (ref.read(personalMeasureRepositoryProvider).offline)
                Text(l10n.personalMeasuresOffline),
              FilledButton.icon(
                key: const ValueKey('measure-add'),
                onPressed: () => _edit(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l10n.personalMeasuresAdd),
              ),
              if (items.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(l10n.personalMeasuresEmpty),
                ),
              for (final item in items)
                ComponentCard(
                  key: ValueKey('measure-${item.id}'),
                  detail: ComponentDescriptorDetailEnum.standard,
                  conclusion: Text(item.name),
                  conclusionSemanticsText:
                      '${item.name}，${_kindLabel(item.kind.value, l10n)}',
                  onTapConclusion: () => _edit(context, ref, item),
                  standardExtra: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_kindLabel(item.kind.value, l10n)} · ${l10n.personalMeasuresCapacityValue(item.capacityMl.toString())}',
                          style: colors.numberStyle(
                            Theme.of(context).textTheme.bodyMedium ??
                                const TextStyle(),
                          ),
                        ),
                      ),
                      if (ref
                          .read(personalMeasureRepositoryProvider)
                          .pendingIds
                          .contains(item.id))
                        const Text('待同步'),
                      IconButton(
                        key: ValueKey('measure-history-${item.id}'),
                        tooltip: '修改历史',
                        icon: const Icon(Icons.history),
                        onPressed: () => _history(context, ref, item),
                      ),
                      IconButton(
                        key: ValueKey('measure-delete-${item.id}'),
                        tooltip: l10n.personalMeasuresDeleteTooltip,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(context, ref, item),
                      ),
                    ],
                  ),
                ),
              for (final item
                  in ref
                      .read(personalMeasureRepositoryProvider)
                      .deletedMeasures
                      .values)
                TextButton.icon(
                  key: ValueKey('measure-history-${item.id}'),
                  onPressed: () => _history(context, ref, item),
                  icon: const Icon(Icons.history),
                  label: Text(
                    '${item.name} · 已删除${ref.read(personalMeasureRepositoryProvider).pendingIds.contains(item.id) ? '（待同步）' : ''} · 修改历史',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _history(
    BuildContext context,
    WidgetRef ref,
    PersonalMeasureOut item,
  ) async {
    final session = ref.read(sessionStoreProvider);
    final identity = session.identity;
    if (identity == null) return;
    final future = ref.read(personalMeasureRepositoryProvider).history(item.id);
    await showDialog<void>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, dialogRef, _) {
          final owner = dialogRef.watch(authProvider).value?.id;
          return ListenableBuilder(
            listenable: session,
            builder: (context, _) {
              if (owner != identity.ownerId || !session.matches(identity)) {
                return const SizedBox.shrink();
              }
              return AlertDialog(
                title: Text('${item.name} · 修改历史'),
                content: SizedBox(
                  width: 440,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(ApiFailure.from(snapshot.error!).message);
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final rows = snapshot.data!;
                      if (rows.isEmpty) return const Text('暂无修改记录');
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final row in rows)
                              ListTile(
                                title: Text(
                                  '${_historyField(row['field'] as String)}：${row['old_value'] ?? '未设置'} → ${row['new_value'] ?? '清空'}',
                                ),
                                subtitle: Text(
                                  '${_historyOutcome(row['outcome'] as String)} · ${row['device_time']}',
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    PersonalMeasureOut? item,
  ]) async {
    final session = ref.read(sessionStoreProvider);
    final identity = session.identity;
    if (identity == null) return;
    final repository = ref.read(personalMeasureRepositoryProvider);
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _MeasureDialog(
        item: item,
        identity: identity,
        repository: repository,
      ),
    );
    if (saved == true && context.mounted && session.matches(identity)) {
      ref.invalidate(personalMeasuresProvider);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PersonalMeasureOut item,
  ) async {
    final l10n = AppLocalizations.of(context);
    final session = ref.read(sessionStoreProvider);
    final identity = session.identity;
    if (identity == null) return;
    final repository = ref.read(personalMeasureRepositoryProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _IdentityDialog(
        identity: identity,
        child: AlertDialog(
          title: Text(l10n.personalMeasuresDeleteTitle),
          content: Text(l10n.personalMeasuresDeleteBody(item.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.recipeDeleteConfirm),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted || !session.matches(identity)) {
      return;
    }
    try {
      await repository.delete(item.id);
      if (context.mounted && session.matches(identity)) {
        ref.invalidate(personalMeasuresProvider);
      }
    } catch (error) {
      if (context.mounted && session.matches(identity)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
      }
    }
  }
}

String _historyField(String field) => switch (field) {
  'name' => '名称',
  'kind' => '类型',
  'capacity_ml' => '容量（毫升）',
  'deleted' => '删除',
  _ => field,
};

String _historyOutcome(String outcome) => switch (outcome) {
  'won' => '已生效',
  'lost' => '未生效：另一设备的较新修改优先',
  'unchanged' => '值未改变',
  'tombstoned' => '未生效：量具已删除',
  'pending' => '待同步',
  _ => outcome,
};

String _kindLabel(String kind, AppLocalizations l10n) => switch (kind) {
  'bowl' => l10n.personalMeasuresBowl,
  'cup' => l10n.personalMeasuresCup,
  _ => l10n.personalMeasuresSpoon,
};

class _IdentityDialog extends ConsumerWidget {
  const _IdentityDialog({required this.identity, required this.child});
  final SessionIdentity identity;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(authProvider).value?.id;
    final session = ref.watch(sessionStoreProvider);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        if (owner != identity.ownerId || !session.matches(identity)) {
          return const SizedBox.shrink();
        }
        return child;
      },
    );
  }
}

class _MeasureDialog extends ConsumerStatefulWidget {
  const _MeasureDialog({
    this.item,
    required this.identity,
    required this.repository,
  });
  final PersonalMeasureOut? item;
  final SessionIdentity identity;
  final PersonalMeasureRepository repository;

  @override
  ConsumerState<_MeasureDialog> createState() => _MeasureDialogState();
}

class _MeasureDialogState extends ConsumerState<_MeasureDialog> {
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _capacity = TextEditingController(
    text: widget.item?.capacityMl.toString() ?? '',
  );
  late String _kind = widget.item?.kind.value ?? 'spoon';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final capacity = double.tryParse(_capacity.text);
    if (name.isEmpty ||
        name.length > 64 ||
        capacity == null ||
        !capacity.isFinite ||
        capacity <= 0 ||
        capacity > 10000) {
      setState(
        () => _error = AppLocalizations.of(context).personalMeasuresValidation,
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!ref.read(sessionStoreProvider).matches(widget.identity)) return;
      final repository = widget.repository;
      if (widget.item == null) {
        await repository.create(
          PersonalMeasureInput(
            name: name,
            kind: PersonalMeasureInputKindEnum.values.firstWhere(
              (value) => value.value == _kind,
            ),
            capacityMl: capacity,
          ),
        );
      } else {
        await repository.update(
          widget.item!.id,
          PersonalMeasureUpdate(
            name: name,
            kind: PersonalMeasureUpdateKindEnum.values.firstWhere(
              (value) => value.value == _kind,
            ),
            capacityMl: capacity,
          ),
        );
      }
      if (mounted && ref.read(sessionStoreProvider).matches(widget.identity)) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _IdentityDialog(
      identity: widget.identity,
      child: AlertDialog(
        title: Text(
          widget.item == null
              ? l10n.personalMeasuresRegister
              : l10n.personalMeasuresEdit,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('measure-name'),
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.personalMeasuresName,
                ),
              ),
              DropdownButtonFormField<String>(
                key: const ValueKey('measure-kind'),
                initialValue: _kind,
                decoration: InputDecoration(
                  labelText: l10n.personalMeasuresKind,
                ),
                items: [
                  for (final kind in ['spoon', 'bowl', 'cup'])
                    DropdownMenuItem(
                      value: kind,
                      child: Text(_kindLabel(kind, l10n)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _kind = value);
                },
              ),
              TextField(
                key: const ValueKey('measure-capacity'),
                controller: _capacity,
                style: const TextStyle(fontFamily: numberFont),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.personalMeasuresCapacity,
                ),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('measure-save'),
            onPressed: _busy ? null : _save,
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
