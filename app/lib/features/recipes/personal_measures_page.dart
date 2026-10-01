import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../recipes/personal_measure_repository.dart';

class PersonalMeasuresPage extends ConsumerWidget {
  const PersonalMeasuresPage({super.key});

  static const path = '/me/measures';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
        data: (items) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.personalMeasuresIntro),
            const SizedBox(height: 12),
            if (ref.read(personalMeasureRepositoryProvider).offline)
              Text(l10n.personalMeasuresOffline),
            FilledButton.icon(
              key: const ValueKey('measure-add'),
              onPressed: ref.read(personalMeasureRepositoryProvider).offline
                  ? null
                  : () => _edit(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.personalMeasuresAdd),
            ),
            if (items.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(l10n.personalMeasuresEmpty),
              ),
            for (final item in items)
              Card(
                child: ListTile(
                  key: ValueKey('measure-${item.id}'),
                  title: Text(item.name),
                  subtitle: Text(
                    '${_kindLabel(item.kind.value, l10n)} · ${l10n.personalMeasuresCapacityValue(item.capacityMl.toString())}',
                  ),
                  onTap: ref.read(personalMeasureRepositoryProvider).offline
                      ? null
                      : () => _edit(context, ref, item),
                  trailing: IconButton(
                    key: ValueKey('measure-delete-${item.id}'),
                    tooltip: l10n.personalMeasuresDeleteTooltip,
                    icon: const Icon(Icons.delete_outline),
                    onPressed:
                        ref.read(personalMeasureRepositoryProvider).offline
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

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    PersonalMeasureOut? item,
  ]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _MeasureDialog(item: item),
    );
    if (saved == true) ref.invalidate(personalMeasuresProvider);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PersonalMeasureOut item,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
    );
    if (confirmed != true) return;
    try {
      await ref.read(personalMeasureRepositoryProvider).delete(item.id);
      ref.invalidate(personalMeasuresProvider);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(ApiFailure.from(error).message)));
      }
    }
  }
}

String _kindLabel(String kind, AppLocalizations l10n) => switch (kind) {
  'bowl' => l10n.personalMeasuresBowl,
  'cup' => l10n.personalMeasuresCup,
  _ => l10n.personalMeasuresSpoon,
};

class _MeasureDialog extends ConsumerStatefulWidget {
  const _MeasureDialog({this.item});
  final PersonalMeasureOut? item;

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
      final repository = ref.read(personalMeasureRepositoryProvider);
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
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
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
              decoration: InputDecoration(labelText: l10n.personalMeasuresName),
            ),
            DropdownButtonFormField<String>(
              key: const ValueKey('measure-kind'),
              initialValue: _kind,
              decoration: InputDecoration(labelText: l10n.personalMeasuresKind),
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
    );
  }
}
