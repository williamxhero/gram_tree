import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../recipes/personal_measure_repository.dart';
import '../../ui_protocol/source_mark.dart';

/// Only the returned, explicitly accepted server conversion changes the editor.
Future<MeasureInputOut?> showMeasureInputDialog(
  BuildContext context, {
  required String? ingredientId,
}) => showDialog<MeasureInputOut>(
  context: context,
  builder: (_) => _MeasureInputDialog(ingredientId: ingredientId),
);

class _MeasureInputDialog extends ConsumerStatefulWidget {
  const _MeasureInputDialog({required this.ingredientId});
  final String? ingredientId;

  @override
  ConsumerState<_MeasureInputDialog> createState() =>
      _MeasureInputDialogState();
}

class _MeasureInputDialogState extends ConsumerState<_MeasureInputDialog> {
  final _quantity = TextEditingController(text: '1');
  String? _measureId;
  String _unit = 'ml';
  MeasureInputOut? _preview;
  String? _error;
  bool _loading = false;
  int _revision = 0;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  void _invalidate() {
    setState(() {
      _preview = null;
      _error = null;
      _loading = false;
      _revision++;
    });
  }

  Future<void> _convert({bool acceptEstimate = false}) async {
    final l10n = AppLocalizations.of(context);
    final quantity = double.tryParse(_quantity.text);
    if (quantity == null ||
        !quantity.isFinite ||
        quantity < 0 ||
        quantity > 10000000) {
      setState(() => _error = l10n.measureInputInvalid);
      return;
    }
    final repository = ref.read(personalMeasureRepositoryProvider);
    if (repository.offline) {
      setState(() => _error = l10n.measureInputOffline);
      return;
    }
    final revision = ++_revision;
    setState(() {
      _loading = true;
      _preview = null;
      _error = null;
    });
    try {
      final result = await repository.previewInput(
        MeasureInputRequest(
          measureId: _measureId!,
          ingredientId: widget.ingredientId,
          quantity: quantity,
          baseUnit: _unit == 'g'
              ? MeasureInputRequestBaseUnitEnum.g
              : MeasureInputRequestBaseUnitEnum.ml,
          acceptEstimate: acceptEstimate,
        ),
      );
      if (mounted && revision == _revision) setState(() => _preview = result);
    } catch (error) {
      if (mounted && revision == _revision) {
        final failure = ApiFailure.from(error);
        setState(
          () => _error = failure.code == 'network'
              ? l10n.measureInputOffline
              : failure.message,
        );
      }
    } finally {
      if (mounted && revision == _revision) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final measures = ref.watch(personalMeasuresProvider);
    final tools = measures.asData?.value ?? const <PersonalMeasureOut>[];
    if (_measureId == null && tools.isNotEmpty) _measureId = tools.first.id;
    final preview = _preview;
    return AlertDialog(
      title: Text(l10n.measureInputTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.measureInputUnchanged),
              TextButton(
                key: const ValueKey('measure-input-manage'),
                onPressed: () async {
                  // Close the modal before visiting the existing management page;
                  // the author can reopen input without losing the editor draft.
                  final router = GoRouter.of(context);
                  Navigator.pop(context);
                  await router.push('/me/measures');
                },
                child: Text(l10n.recipeMeasureManage),
              ),
              if (measures.isLoading) const LinearProgressIndicator(),
              if (measures.hasError ||
                  ref.read(personalMeasureRepositoryProvider).offline)
                Text(l10n.measureInputOffline),
              if (!measures.isLoading && !measures.hasError && tools.isEmpty)
                Text(l10n.measureInputNoTools),
              if (tools.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  key: const ValueKey('measure-input-tool'),
                  initialValue: _measureId,
                  decoration: InputDecoration(labelText: l10n.measureInputTool),
                  items: [
                    for (final tool in tools)
                      DropdownMenuItem(
                        value: tool.id,
                        child: Text('${tool.name} · ${tool.capacityMl} ml'),
                      ),
                  ],
                  onChanged: (value) {
                    _measureId = value;
                    _invalidate();
                  },
                ),
                TextField(
                  key: const ValueKey('measure-input-count'),
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.measureInputCount,
                  ),
                  onChanged: (_) => _invalidate(),
                ),
                DropdownButtonFormField<String>(
                  key: const ValueKey('measure-input-unit'),
                  initialValue: _unit,
                  decoration: InputDecoration(
                    labelText: l10n.measureInputBaseUnit,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'ml',
                      child: Text(l10n.recipeMeasureMillilitre),
                    ),
                    DropdownMenuItem(
                      value: 'g',
                      child: Text(l10n.recipeMeasureGram),
                    ),
                  ],
                  onChanged: (value) {
                    _unit = value!;
                    _invalidate();
                  },
                ),
                TextButton(
                  key: const ValueKey('measure-input-preview'),
                  onPressed: _loading ? null : () => _convert(),
                  child: Text(l10n.measureInputPreview),
                ),
              ],
              if (_loading) const LinearProgressIndicator(),
              if (_error != null) Text(_error!),
              if (preview != null) ...[
                Text(preview.original),
                if (preview.baseQuantity != null)
                  Text(
                    '${preview.baseQuantity!.toDouble().toString().replaceFirst(RegExp(r'\.0$'), '')} ${preview.baseUnit.value}',
                  ),
                Text(preview.basis),
                SourceMark(
                  sourceType:
                      preview.quantitySource?.source_.value ?? 'author_filled',
                  componentId: 'measure-input',
                  value:
                      '${preview.baseQuantity ?? "—"} ${preview.baseUnit.value}',
                  originalValue: preview.original,
                  basisText: preview.basis,
                  required: false,
                  feedbackEnabled: false,
                  neutral: true,
                  showWhenAuthorFilled: true,
                  labelOverride: l10n.measureInputEvidence,
                  onAction: null,
                ),
                if (preview.status ==
                    MeasureInputOutStatusEnum.estimateConfirmationRequired)
                  TextButton(
                    key: const ValueKey('measure-input-accept-estimate'),
                    onPressed: _loading
                        ? null
                        : () => _convert(acceptEstimate: true),
                    child: Text(l10n.measureInputEstimate),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('measure-input-cancel'),
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.measureInputFallback),
        ),
        FilledButton(
          key: const ValueKey('measure-input-confirm'),
          onPressed:
              preview?.status == MeasureInputOutStatusEnum.ready && !_loading
              ? () => Navigator.pop(context, preview)
              : null,
          child: Text(l10n.measureInputConfirm),
        ),
      ],
    );
  }
}
