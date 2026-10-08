import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../recipes/recipe_repository.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/recipe_operations.dart';
import '../../ui_protocol/recipe_safety.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';
import '../../util/ids.dart';
import 'reproducibility_card.dart';

/// A shared, non-persisting preview. Only the registered confirm intent saves.
class TextEditPanel extends ConsumerStatefulWidget {
  const TextEditPanel({
    super.key,
    this.recipeId,
    this.baseVersionId,
    this.generationRequestId,
    this.manualEdits = false,
    required this.onSaved,
    this.onSavingChanged,
  });
  final String? recipeId;
  final String? baseVersionId;
  final String? generationRequestId;
  final bool manualEdits;
  final Future<void> Function(RecipeDetail) onSaved;
  final ValueChanged<bool>? onSavingChanged;

  @override
  ConsumerState<TextEditPanel> createState() => _TextEditPanelState();
}

class _TextEditPanelState extends ConsumerState<TextEditPanel> {
  final _text = TextEditingController();
  final _compositionId = newUuidV4();
  final _choices = <String, ModificationDecision>{};
  AIStatus? _status;
  ModificationPreview? _preview;
  String? _error;
  String? _requestId;
  bool _busy = false;
  bool _checking = false;
  bool _checksDirty = false;
  int _selectionRevision = 0;
  int _targetRevision = 0;
  int _pendingChoices = 0;
  Timer? _editTimer;

  RecipeRepository get _repo => ref.read(recipeRepositoryProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_loadStatus());
  }

  @override
  void didUpdateWidget(TextEditPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.manualEdits && !oldWidget.manualEdits) {
      // A proposal targets an immutable baseline, not subsequent form edits.
      _targetRevision++;
      _preview = null;
      _choices.clear();
      _editTimer?.cancel();
      _checksDirty = false;
    }
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _repo.modificationStatus();
      if (mounted) setState(() => _status = status);
    } catch (_) {
      if (mounted) {
        setState(() => _error = '暂时无法读取修改额度，请重试。手动编辑和保存不受影响。');
      }
    }
  }

  Future<void> _propose(String text) async {
    if (_busy || _checking || widget.manualEdits || text.trim().isEmpty) return;
    final targetRevision = ++_targetRevision;
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
      _choices.clear();
      _checksDirty = false;
    });
    try {
      _requestId ??= newUuidV4();
      final preview = await _repo.proposeModification(
        ModificationInput(
          requestId: _requestId,
          text: text.trim(),
          recipeId: widget.recipeId,
          baseVersionId: widget.baseVersionId,
          generationRequestId: widget.generationRequestId,
        ),
      );
      if (!mounted) return;
      setState(() => _status = preview.status);
      if (targetRevision != _targetRevision) return;
      setState(() {
        _preview = preview;
        _error = preview.error == null ? null : _reason(preview.error);
        _requestId = null;
      });
    } catch (error) {
      if (mounted && targetRevision == _targetRevision) {
        setState(() => _error = ApiFailure.from(error).message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _choose(Map<String, dynamic> params) {
    final preview = _preview;
    if (preview == null || _busy || widget.manualEdits) return;
    final id = params['operation_id'] as String;
    if (!(preview.operations ?? const <ModificationOperation>[]).any(
      (operation) => operation.operationId == id,
    )) {
      return;
    }
    setState(() {
      _choices[id] = ModificationDecision.fromJson({
        'operation_id': id,
        'decision': params['decision'],
        if (params['decision'] == 'modify') 'after': params['after'],
      });
      _selectionRevision++;
      _checksDirty = true;
      _error = null;
    });
    _editTimer?.cancel();
    // Serialize checks so a slow old request cannot overwrite a newer selection.
    _editTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(_checkSelection());
    });
  }

  Future<void> _checkSelection() async {
    if (_checking || !_checksDirty || _preview == null) return;
    final targetRevision = _targetRevision;
    final id = _preview!.id;
    setState(() => _checking = true);
    try {
      while (mounted && targetRevision == _targetRevision && _checksDirty) {
        final revision = _selectionRevision;
        final result = await _repo.decideModification(
          id,
          _choices.values.toList(),
        );
        if (!mounted || targetRevision != _targetRevision) return;
        if (revision != _selectionRevision) continue;
        setState(() {
          _preview = result;
          _checksDirty = false;
          _choices.clear();
          for (final choice
              in result.decisions ?? const <ModificationDecisionOut>[]) {
            if (choice.decision.value != 'pending') {
              _choices[choice.operationId] = ModificationDecision.fromJson({
                'operation_id': choice.operationId,
                'decision': choice.decision.value,
                if (choice.decision.value == 'modify')
                  'after': choice.after ?? '',
              });
            }
          }
        });
      }
    } catch (error) {
      if (mounted && targetRevision == _targetRevision) {
        setState(() => _error = ApiFailure.from(error).message);
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  bool get _canConfirm {
    final preview = _preview;
    return preview != null &&
        preview.error == null &&
        preview.operations?.isNotEmpty == true &&
        preview.decisions?.length == preview.operations!.length &&
        preview.decisions!.every(
          (choice) => choice.decision.value != 'pending',
        ) &&
        preview.safety.canSave == true &&
        (widget.generationRequestId != null ||
            preview.decisions!.any(
              (choice) => choice.decision.value != 'reject',
            )) &&
        !_busy &&
        !_checking &&
        _pendingChoices == 0 &&
        !_checksDirty &&
        !widget.manualEdits;
  }

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    final preview = _preview!;
    widget.onSavingChanged?.call(true);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final detail = await _repo.confirmModification(
        preview.id,
        preview.revision,
      );
      if (!mounted) return;
      await widget.onSaved(detail);
    } catch (error) {
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    } finally {
      if (mounted) {
        widget.onSavingChanged?.call(false);
        setState(() => _busy = false);
      }
    }
  }

  void _cancel() {
    _targetRevision++;
    _editTimer?.cancel();
    setState(() {
      _preview = null;
      _choices.clear();
      _checksDirty = false;
      _error = null;
    });
  }

  Future<void> _dispatch(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final choosing = params['operation'] == 'text_choose';
    if (choosing) {
      // Visible edits invalidate confirmation before the dispatcher awaits local
      // event persistence. Slow storage must not leave the old check usable.
      setState(() => _pendingChoices++);
    }
    try {
      await ref
          .read(intentDispatcherProvider)
          .dispatch(
            context,
            compositionId: CompositionIdScope.of(context) ?? _compositionId,
            componentId: 'recipe-text-edit',
            action: ActionDescriptor(
              intent: 'recipe_operation',
              params: params,
            ),
          );
    } finally {
      if (choosing && mounted) setState(() => _pendingChoices--);
    }
  }

  Widget _operation(BuildContext context, ModificationOperation operation) {
    final choice = _choices[operation.operationId];
    final returned = (_preview!.decisions ?? const <ModificationDecisionOut>[])
        .where((decision) => decision.operationId == operation.operationId)
        .firstOrNull;
    final pendingDependencies = (operation.dependsOn ?? const <String>[])
        .where((id) => !_choices.containsKey(id))
        .toList();
    final evidence =
        '${operation.reason}\n风险：${operation.risk}\n把握程度：${(operation.confidence * 100).round()}%\n依赖操作：${operation.dependsOn?.isNotEmpty == true ? operation.dependsOn!.join('、') : '无'}';
    return ComponentCard(
      key: ValueKey('text-edit-operation-${operation.operationId}'),
      detail: ComponentDescriptorDetailEnum.detailed,
      conclusion: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('目标：${operation.id ?? '菜谱信息'} · ${operation.field}'),
          Text('修改前：${operation.before ?? '无'}'),
          Text('建议后值：${operation.after ?? '无'}'),
        ],
      ),
      conclusionSemanticsText:
          '操作 ${operation.operationId}，${operation.before} 改为 ${operation.after}',
      basisText: operation.reason,
      detailedExtra: Text(
        '操作：${operation.operationId} · ${operation.type.value}\n影响范围：${operation.scope.join('、')}\n具体意图：${operation.intent}\n$evidence',
      ),
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SourceMark(
            key: ValueKey('text-edit-why-${operation.operationId}'),
            sourceType: sourceTypeAiEstimated,
            componentId: 'text-edit-${operation.operationId}',
            value: operation.after ?? '无',
            originalValue: operation.before,
            basisText: evidence,
            required: false,
            feedbackEnabled: false,
            onAction: null,
          ),
          Text(
            '本条处理：${switch (choice?.decision.value) {
              'accept' => '接受',
              'reject' => '拒绝',
              'modify' => '修改后值',
              _ => '待处理',
            }}',
          ),
          if (pendingDependencies.isNotEmpty)
            Text('上游操作尚待处理：${pendingDependencies.join('、')}；请先处理依赖。'),
          if (returned?.blockedBy?.isNotEmpty == true)
            Text('依赖被拒绝，已默认拒绝：${returned!.blockedBy!.join('、')}'),
          Wrap(
            spacing: 8,
            children: [
              for (final decision in ['accept', 'reject', 'modify'])
                OutlinedButton(
                  key: ValueKey('text-edit-$decision-${operation.operationId}'),
                  onPressed:
                      _busy ||
                          _checking ||
                          widget.manualEdits ||
                          (decision != 'reject' &&
                              (pendingDependencies.isNotEmpty ||
                                  returned?.blockedBy?.isNotEmpty == true))
                      ? null
                      : () => _dispatch(context, {
                          'operation': 'text_choose',
                          'operation_id': operation.operationId,
                          'decision': decision,
                          if (decision == 'modify')
                            'after': choice?.after ?? operation.after ?? '',
                        }),
                  child: Text(switch (decision) {
                    'accept' => '接受',
                    'reject' => '拒绝',
                    _ => '修改后值',
                  }),
                ),
            ],
          ),
          if (choice?.decision.value == 'modify')
            TextFormField(
              key: ValueKey('text-edit-after-${operation.operationId}'),
              initialValue: choice?.after ?? operation.after ?? '',
              enabled: !_busy && !widget.manualEdits,
              maxLength: 4000,
              minLines: 1,
              maxLines: 6,
              decoration: const InputDecoration(labelText: '修改后的文字'),
              onChanged: (after) => unawaited(
                _dispatch(context, {
                  'operation': 'text_choose',
                  'operation_id': operation.operationId,
                  'decision': 'modify',
                  'after': after,
                }),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _editTimer?.cancel();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RecipeOperationScope(
    handlers: {
      'text_preview': (params) => _propose(params['text'] as String),
      'text_choose': _choose,
      'text_confirm': (_) => _confirm(),
      'text_cancel': (_) => _cancel(),
    },
    child: Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('一句话改文字', style: Theme.of(context).textTheme.titleMedium),
          const Text('只支持改文字；其他修改暂未支持。确认前不会保存。'),
          const Text('请勿输入个人敏感信息。手动编辑和保存始终可用。'),
          if (widget.manualEdits) const Text('当前有未保存的表单修改，请先手动保存，再请求文字修改。'),
          Text(
            _status == null ? '正在读取今日修改额度…' : '今日修改剩余 ${_status!.remaining} 次',
            key: const ValueKey('text-edit-quota'),
          ),
          if (_status?.available == false) Text(_reason(_status?.reason)),
          TextField(
            key: const ValueKey('text-edit-input'),
            controller: _text,
            enabled: !_busy && !_checking && !widget.manualEdits,
            maxLength: 1000,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(labelText: '想改哪段文字？'),
            onChanged: (_) {
              _requestId = null;
              _cancel();
            },
            onSubmitted: (text) {
              if (_status?.available == true) {
                unawaited(
                  _dispatch(context, {
                    'operation': 'text_preview',
                    'text': text,
                  }),
                );
              }
            },
          ),
          OutlinedButton(
            key: const ValueKey('text-edit-preview'),
            onPressed:
                _busy ||
                    _checking ||
                    widget.manualEdits ||
                    _status?.available != true ||
                    _text.text.trim().isEmpty
                ? null
                : () => _dispatch(context, {
                    'operation': 'text_preview',
                    'text': _text.text,
                  }),
            child: const Text('预览文字修改'),
          ),
          if (_busy || _checking) const LinearProgressIndicator(),
          if (_error != null) ...[
            Text(_error!, key: const ValueKey('text-edit-error')),
            if (_status == null)
              TextButton(onPressed: _loadStatus, child: const Text('重试读取修改额度')),
          ],
          if (_preview != null && _preview!.error == null) ...[
            for (final operation
                in _preview!.operations ?? const <ModificationOperation>[])
              _operation(context, operation),
            const Text('实际待确认结果 · 仅包含已接受或修改的操作；待处理不会应用。'),
            if (_checksDirty || _checking || _pendingChoices > 0)
              const Text('选择或后值已改变，正在更新检查。旧检查不可用于确认。')
            else ...[
              for (final step
                  in _preview!.snapshot.steps ?? const <RecipeStep>[])
                Text('待确认步骤 ${step.id}：${step.instruction}'),
              FoodSafetyCard(result: _preview!.safety),
              AllergenCard(result: _preview!.safety),
              ReproducibilityCard(result: _preview!.reproducibility),
              for (final warning in _preview!.warnings ?? const <String>[])
                Text(warning),
            ],
            if (_checksDirty && !_checking)
              TextButton(
                onPressed: _checkSelection,
                child: const Text('重试检查所选修改'),
              ),
            const Text('请逐条处理后确认。只保存私有版本，不公开，也不修改口味档案。'),
            FilledButton(
              key: const ValueKey('text-edit-confirm'),
              onPressed: _canConfirm
                  ? () => _dispatch(context, {'operation': 'text_confirm'})
                  : null,
              child: const Text('确认并保存所选修改'),
            ),
            TextButton(
              key: const ValueKey('text-edit-cancel'),
              onPressed: _busy
                  ? null
                  : () => _dispatch(context, {'operation': 'text_cancel'}),
              child: const Text('取消预览，继续手动编辑'),
            ),
          ],
        ],
      ),
    ),
  );
}

String _reason(String? reason) => switch (reason) {
  'daily_quota' => '今日修改额度已用完。手动编辑和保存不受影响。',
  'monthly_budget' => '平台月预算已达到上限，AI 暂停。手动编辑和保存不受影响。',
  'configuration' => '模型配置暂不可用。手动编辑和保存不受影响。',
  'invalid_output' => 'AI 修改校验未通过，已纠正一次仍失败。原话保留，可重试或手动编辑。',
  'unsupported_intent' => '识别到其他修改类别，目前只支持改文字，不会应用。请手动编辑。',
  'uncertain_intent' => '没把握理解这次修改。请换个说法，或手动编辑，不会硬改。',
  _ => '模型暂不可用。原话保留，可重试或手动编辑。',
};
