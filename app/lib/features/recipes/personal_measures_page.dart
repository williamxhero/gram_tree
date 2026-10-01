import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../recipes/personal_measure_repository.dart';

class PersonalMeasuresPage extends ConsumerWidget {
  const PersonalMeasuresPage({super.key});

  static const path = '/me/measures';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measures = ref.watch(personalMeasuresProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('自家量具')),
      body: measures.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ApiFailure.from(error).message),
              TextButton(
                onPressed: () => ref.invalidate(personalMeasuresProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (items) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('把空量具放在厨房秤上归零，装满水后的克数就是容量（毫升）。只影响显示，不会修改菜谱。'),
            const SizedBox(height: 12),
            if (ref.read(personalMeasureRepositoryProvider).offline)
              const Text('离线：正在使用已缓存的量具；登记、修改和删除需要联网。'),
            FilledButton.icon(
              key: const ValueKey('measure-add'),
              onPressed: ref.read(personalMeasureRepositoryProvider).offline
                  ? null
                  : () => _edit(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('登记量具'),
            ),
            if (items.isEmpty) const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('还没有登记量具'),
            ),
            for (final item in items)
              Card(
                child: ListTile(
                  key: ValueKey('measure-${item.id}'),
                  title: Text(item.name),
                  subtitle: Text('${_kindLabel(item.kind.value)} · ${item.capacityMl} 毫升'),
                  onTap: ref.read(personalMeasureRepositoryProvider).offline
                      ? null
                      : () => _edit(context, ref, item),
                  trailing: IconButton(
                    key: ValueKey('measure-delete-${item.id}'),
                    tooltip: '删除量具',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: ref.read(personalMeasureRepositoryProvider).offline
                        ? null
                        : () => _delete(context, ref, item),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, [PersonalMeasureOut? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _MeasureDialog(item: item),
    );
    if (saved == true) ref.invalidate(personalMeasuresProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, PersonalMeasureOut item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除量具？'),
        content: Text('删除“${item.name}”不会改动菜谱。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('确认删除')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(personalMeasureRepositoryProvider).delete(item.id);
      ref.invalidate(personalMeasuresProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
      }
    }
  }
}

String _kindLabel(String kind) => switch (kind) {
  'bowl' => '碗',
  'cup' => '杯',
  _ => '勺',
};

class _MeasureDialog extends ConsumerStatefulWidget {
  const _MeasureDialog({this.item});
  final PersonalMeasureOut? item;

  @override
  ConsumerState<_MeasureDialog> createState() => _MeasureDialogState();
}

class _MeasureDialogState extends ConsumerState<_MeasureDialog> {
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _capacity = TextEditingController(text: widget.item?.capacityMl.toString() ?? '');
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
    if (name.isEmpty || name.length > 64 || capacity == null || !capacity.isFinite || capacity <= 0 || capacity > 10000) {
      setState(() => _error = '名称需为 1–64 个字，容量需大于 0 且不超过 10000 毫升');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repository = ref.read(personalMeasureRepositoryProvider);
      if (widget.item == null) {
        await repository.create(PersonalMeasureInput(
          name: name,
          kind: PersonalMeasureInputKindEnum.values.firstWhere((value) => value.value == _kind),
          capacityMl: capacity,
        ));
      } else {
        await repository.update(widget.item!.id, PersonalMeasureUpdate(
          name: name,
          kind: PersonalMeasureUpdateKindEnum.values.firstWhere((value) => value.value == _kind),
          capacityMl: capacity,
        ));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? '登记量具' : '修改量具'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(key: const ValueKey('measure-name'), controller: _name, decoration: const InputDecoration(labelText: '量具名称')),
          DropdownButtonFormField<String>(
            key: const ValueKey('measure-kind'),
            initialValue: _kind,
            decoration: const InputDecoration(labelText: '种类'),
            items: [for (final kind in ['spoon', 'bowl', 'cup']) DropdownMenuItem(value: kind, child: Text(_kindLabel(kind)))],
            onChanged: (value) { if (value != null) setState(() => _kind = value); },
          ),
          TextField(key: const ValueKey('measure-capacity'), controller: _capacity, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '满水容量（毫升）')),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('取消')),
      FilledButton(key: const ValueKey('measure-save'), onPressed: _busy ? null : _save, child: const Text('保存')),
    ],
  );
}
