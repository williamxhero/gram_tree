import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../recipes/recipe_draft.dart';
import '../../recipes/recipe_repository.dart';
import '../../storage/local_store.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/recipe_operations.dart';
import '../../ui_protocol/recipe_safety.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';
import '../../util/ids.dart';
import 'reproducibility_card.dart';
import 'change_explanation_panel.dart';

/// A shared, locally recoverable preview. Only the confirm intent saves a recipe.
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

class _TextEditPanelState extends ConsumerState<TextEditPanel>
    with AutomaticKeepAliveClientMixin<TextEditPanel> {
  // The generation result is a lazy list. Scrolling must not discard unsaved
  // text, pending choices or the exact preview bound to a confirmation click.
  @override
  bool get wantKeepAlive => true;

  final _text = TextEditingController();
  final _compositionId = newUuidV4();
  final _choices = <String, ModificationDecision>{};
  final _afterInputs = <String, String>{};
  final _invalidAfter = <String, String>{};
  AIStatus? _status;
  ChangeExplanationSuggestion? _explanationResult;
  ModificationPreview? _preview;
  ModificationPreview? _confirmingPreview;
  Map<String, dynamic>? _pendingConfirmation;
  RecipeDetail? _savedDetail;
  bool get _locked => _busy || _pendingConfirmation != null;
  String _changeNote = '';
  bool? _changeNoteAuthored;
  bool? _tagsAuthored;
  List<String>? _tags;
  String? _explanationFingerprint;
  ({String note, List<String>? tags, String? fingerprint})?
  _confirmingExplanation;
  String? _error;
  String? _requestId;
  bool _failedRequest = false;
  bool _busy = false;
  bool _checking = false;
  bool _checksDirty = false;
  int _selectionRevision = 0;
  int _targetRevision = 0;
  int _pendingChoices = 0;
  Future<void> _choiceDispatch = Future<void>.value();
  Timer? _editTimer;
  late final RecipeDraftStore _draftStore;
  late final String _accountId;
  late int _draftEpoch;

  String get _recipeKey =>
      widget.recipeId ?? 'ai-${widget.generationRequestId}';
  RecipeRepository get _repo => ref.read(recipeRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _draftStore = RecipeDraftStore(ref.read(localStoreProvider));
    _accountId = ref.read(authProvider).value?.id ?? 'anonymous';
    _draftEpoch = _draftStore.modificationEpoch(
      recipeKey: _recipeKey,
      accountId: _accountId,
      baselineVersionId: widget.baseVersionId,
    );
    _restore();
    unawaited(_loadStatus());
    if (_pendingConfirmation != null) {
      // Resume an already-issued save, not a new decision replay on a saved job.
      unawaited(Future<void>.microtask(_resumeConfirmation));
    } else if (_checksDirty) {
      unawaited(_checkSelection());
    }
  }

  void _restore() {
    final draft = _draftStore.readModification(
      recipeKey: _recipeKey,
      accountId: _accountId,
      baselineVersionId: widget.baseVersionId,
    );
    if (draft == null) return;
    try {
      final payload = draft.payload;
      final preview = payload['preview'] == null
          ? null
          : ModificationPreview.fromJson(
              Map<String, dynamic>.from(payload['preview'] as Map),
            );
      final choices = [
        for (final value in payload['choices'] as List)
          ModificationDecision.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
      ];
      _text.text = payload['text'] as String;
      _requestId = payload['request_id'] as String?;
      _failedRequest = payload['failed_request'] == true;
      _afterInputs.addAll(
        Map<String, String>.from(payload['after_inputs'] as Map? ?? {}),
      );
      _invalidAfter.addAll(
        Map<String, String>.from(payload['invalid_after'] as Map? ?? {}),
      );
      _preview = preview;
      _changeNote = payload['change_note'] as String? ?? '';
      _changeNoteAuthored = payload['note_authored'] as bool?;
      _tagsAuthored = payload['tags_authored'] as bool?;
      _tags = payload['tags'] == null
          ? null
          : List<String>.from(payload['tags'] as List);
      _explanationFingerprint = payload['explanation_fingerprint'] as String?;
      for (final choice in choices) {
        _choices[choice.operationId] = choice;
      }
      // Cached checks are evidence to show again, never permission to save.
      // Replay the exact local decisions through server-owned checks first.
      final confirmation = payload['pending_confirmation'];
      if (confirmation is Map &&
          confirmation['id'] == preview?.id &&
          confirmation['revision'] == preview?.revision) {
        _pendingConfirmation = Map<String, dynamic>.from(confirmation);
        if (payload['saved_detail'] is Map) {
          _savedDetail = RecipeDetail.fromJson(
            Map<String, dynamic>.from(payload['saved_detail'] as Map),
          );
        }
      }
      _checksDirty = preview != null && _pendingConfirmation == null;
    } catch (_) {
      // Old form drafts and malformed modification drafts cannot grant a save.
      _preview = null;
      _choices.clear();
    }
  }

  Future<void> _persist() => _draftStore.saveModification(
    expectedEpoch: _draftEpoch,
    recipeKey: _recipeKey,
    accountId: _accountId,
    baselineVersionId: widget.baseVersionId,
    payload: {
      'text': _text.text,
      'request_id': _requestId,
      'failed_request': _failedRequest,
      'after_inputs': Map<String, String>.from(_afterInputs),
      'invalid_after': Map<String, String>.from(_invalidAfter),
      'preview': _preview?.toJson(),
      'pending_confirmation': _pendingConfirmation,
      'saved_detail': _savedDetail?.toJson(),
      'change_note': _changeNote,
      'note_authored': _changeNoteAuthored,
      'tags_authored': _tagsAuthored,
      'tags': _tags == null ? null : List<String>.of(_tags!),
      'explanation_fingerprint': _explanationFingerprint,
      'choices': [for (final choice in _choices.values) choice.toJson()],
    },
  );

  void _persistLater() {
    unawaited(
      _persist().catchError((Object error) {
        if (mounted) {
          setState(() => _error = '本机草稿保存失败，请保留当前页面并重试。');
        }
      }),
    );
  }

  Future<void> _discard() async {
    try {
      await _draftStore.discardModification(
        recipeKey: _recipeKey,
        accountId: _accountId,
        baselineVersionId: widget.baseVersionId,
      );
    } finally {
      _draftEpoch = _draftStore.modificationEpoch(
        recipeKey: _recipeKey,
        accountId: _accountId,
        baselineVersionId: widget.baseVersionId,
      );
    }
  }

  @override
  void didUpdateWidget(TextEditPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.manualEdits && !oldWidget.manualEdits) {
      // A proposal targets an immutable baseline, not subsequent form edits.
      _targetRevision++;
      _editTimer?.cancel();
      // Keep the user's decisions recoverable, but never apply an immutable
      // baseline proposal on top of unrelated unsaved form changes.
      _checksDirty = _preview != null;
    }
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _repo.modificationStatus();
      if (mounted) {
        setState(() {
          _status = status;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '暂时无法读取修改额度，请重试。手动编辑和保存不受影响。');
      }
    }
  }

  Future<void> _propose(String text) async {
    if (_locked ||
        _checking ||
        _pendingChoices > 0 ||
        widget.manualEdits ||
        text.trim().isEmpty) {
      return;
    }
    final targetRevision = ++_targetRevision;
    setState(() {
      _busy = true;
      _explanationFingerprint = null;
      _error = null;
    });
    try {
      _requestId ??= newUuidV4();
      await _persist();
      final preview = await _repo.proposeModification(
        ModificationInput.fromJson({
          'request_id': _requestId,
          'text': text.trim(),
          'recipe_id': widget.recipeId,
          'base_version_id': widget.baseVersionId,
          'generation_request_id': widget.generationRequestId,
          'retry_failed': _failedRequest,
        }),
      );
      if (!mounted || targetRevision != _targetRevision) return;
      setState(() {
        _status = preview.status;
        _error = preview.error == null ? null : _reason(preview.error);
        _failedRequest = preview.error != null;
        // A failed later request must not erase the last usable checked result.
        if (preview.error == null) {
          _preview = preview;
          _choices.clear();
          _afterInputs.clear();
          _invalidAfter.clear();
          _checksDirty = false;
          _requestId = null;
        }
      });
      _persistLater();
    } catch (error) {
      if (mounted && targetRevision == _targetRevision) {
        setState(() {
          _error = ApiFailure.from(error).message;
          _failedRequest = true;
        });
        _persistLater();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _choose(Map<String, dynamic> params) {
    final preview = _preview;
    if (preview == null || _locked || widget.manualEdits) return;
    final id = params['operation_id'] as String;
    // Invalid raw input is newer than any still-persisting modify intent.
    // Accept/reject remain explicit ways to abandon the invalid edited value.
    if (params['decision'] == 'modify' && _invalidAfter.containsKey(id)) return;
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
      _invalidAfter.remove(id);
      if (params['decision'] != 'modify') _afterInputs.remove(id);
      _selectionRevision++;
      _checksDirty = true;
      _error = null;
    });
    _persistLater();
    _editTimer?.cancel();
    // Serialize checks so a slow old request cannot overwrite a newer selection.
    _editTimer = Timer(const Duration(milliseconds: 250), () {
      unawaited(_checkSelection());
    });
  }

  Future<void> _checkSelection() async {
    if (_checking ||
        _pendingConfirmation != null ||
        !_checksDirty ||
        _preview == null ||
        _invalidAfter.isNotEmpty) {
      return;
    }
    final targetRevision = _targetRevision;
    final id = _preview!.id;
    setState(() => _checking = true);
    try {
      while (mounted &&
          targetRevision == _targetRevision &&
          _checksDirty &&
          _invalidAfter.isEmpty) {
        final revision = _selectionRevision;
        await _persist();
        if (!mounted || targetRevision != _targetRevision) return;
        final result = await _repo.decideModification(
          id,
          _choices.values.toList(),
        );
        if (!mounted || targetRevision != _targetRevision) return;
        if (revision != _selectionRevision) continue;
        setState(() {
          _preview = result;
          _error = null;
          _checksDirty = false;
          _choices.clear();
          for (final choice
              in result.decisions ?? const <ModificationDecisionOut>[]) {
            if (choice.decision.value != 'pending') {
              _choices[choice.operationId] = ModificationDecision.fromJson({
                'operation_id': choice.operationId,
                'decision': choice.decision.value,
                if (choice.decision.value == 'modify') 'after': choice.after,
              });
            }
          }
        });
        _persistLater();
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
    if (_pendingConfirmation != null) {
      return preview != null && !_busy && !widget.manualEdits;
    }
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
        _invalidAfter.isEmpty &&
        !widget.manualEdits;
  }

  Future<void> _confirm() async {
    final preview = _confirmingPreview;
    final explanation = _confirmingExplanation;
    if (preview == null ||
        explanation == null ||
        !identical(preview, _preview) ||
        widget.manualEdits) {
      return;
    }
    final onSaved = widget.onSaved;
    final repo = _repo;
    try {
      _pendingConfirmation ??= {
        'id': preview.id,
        'revision': preview.revision,
        'note': explanation.note,
        'tags': explanation.tags,
        'fingerprint': explanation.fingerprint,
      };
      await _persist();
      final pending = _pendingConfirmation!;
      final detail =
          _savedDetail ??
          await repo.confirmModification(
            pending['id'] as String,
            pending['revision'] as int,
            changeNote: pending['note'] as String,
            tags: pending['tags'] == null
                ? null
                : List<String>.from(pending['tags'] as List),
            explanationFingerprint: pending['fingerprint'] as String?,
          );
      _savedDetail = detail;
      await _persist();
      // A committed save still owns its cleanup after the editor is disposed.
      // The captured parent callback guards navigation, not durable removal.
      await _discard();
      await onSaved(detail);
    } catch (error) {
      if (_savedDetail != null) {
        // Parent cleanup may have removed our scope before another removal
        // failed. Retain the committed receipt so reopen can finish cleanup.
        _draftEpoch = _draftStore.modificationEpoch(
          recipeKey: _recipeKey,
          accountId: _accountId,
          baselineVersionId: widget.baseVersionId,
        );
        _persistLater();
      }
      if (mounted) setState(() => _error = ApiFailure.from(error).message);
    }
  }

  Future<void> _resumeConfirmation() async {
    if (!mounted || _preview == null || _pendingConfirmation == null) return;
    _confirmingPreview = _preview;
    _confirmingExplanation = (
      note: _changeNote,
      tags: _tags,
      fingerprint: _explanationFingerprint,
    );
    setState(() => _busy = true);
    widget.onSavingChanged?.call(true);
    try {
      await _confirm();
    } finally {
      _confirmingPreview = null;
      _confirmingExplanation = null;
      if (mounted) {
        widget.onSavingChanged?.call(false);
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _cancel() async {
    _targetRevision++;
    _editTimer?.cancel();
    setState(() => _busy = true);
    try {
      await _discard();
      if (!mounted) return;
      setState(() {
        _preview = null;
        _pendingConfirmation = null;
        _savedDetail = null;
        _choices.clear();
        _afterInputs.clear();
        _invalidAfter.clear();
        _checksDirty = false;
        _requestId = null;
        _failedRequest = false;
        _changeNote = '';
        _changeNoteAuthored = null;
        _tags = null;
        _tagsAuthored = null;
        _explanationFingerprint = null;
        _text.clear();
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _checksDirty = _preview != null;
          _error = '本机草稿清理失败，已保留修改，请重试。';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _canRequest =>
      _status?.available == true ||
      (_failedRequest &&
          _requestId != null &&
          _status?.reason != 'monthly_budget');

  Future<void> _dispatch(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final choosing = params['operation'] == 'text_choose';
    final confirming = params['operation'] == 'text_confirm';
    if (confirming) {
      if (!_canConfirm) return;
      // Bind this click and lock edits before asynchronous event persistence.
      // A delayed confirm intent must never capture a later checked result.
      _confirmingPreview = _preview;
      _confirmingExplanation = (
        note: _changeNote,
        tags: _tags == null ? null : List<String>.of(_tags!),
        fingerprint: _explanationFingerprint,
      );
      setState(() {
        _busy = true;
        _error = null;
      });
      widget.onSavingChanged?.call(true);
    }
    final previous = _choiceDispatch;
    final completion = choosing ? Completer<void>() : null;
    if (choosing) {
      // Visible edits invalidate confirmation before the dispatcher awaits local
      // event persistence. Slow storage must not leave the old check usable.
      setState(() {
        _pendingChoices++;
        _explanationFingerprint = null;
      });
      // EventQueue does not promise ordered completion. Keep edited-after
      // handlers in input order even while the field permits more typing.
      _choiceDispatch = completion!.future;
    }
    try {
      if (choosing) await previous;
      if (!context.mounted) return;
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
      // A failed dispatch must not strand the remaining input behind its tail.
      completion?.complete();
      if (choosing && mounted) setState(() => _pendingChoices--);
      if (confirming) {
        _confirmingPreview = null;
        _confirmingExplanation = null;
        if (mounted) {
          widget.onSavingChanged?.call(false);
          setState(() => _busy = false);
        }
      }
    }
  }

  Future<ChangeExplanationSuggestion> _dispatchExplanation(
    BuildContext context,
  ) async {
    _explanationResult = null;
    await _dispatch(context, {'operation': 'explain_changes'});
    return _explanationResult ??
        const ChangeExplanationSuggestion(available: false);
  }

  Future<ChangeExplanationSuggestion> _explain(
    ModificationPreview preview,
  ) async {
    final target = _targetRevision;
    final selection = _selectionRevision;
    try {
      final result = await _repo.explainChanges(
        ChangeExplanationInput(
          modificationId: preview.id,
          revision: preview.revision,
        ),
      );
      if (!mounted ||
          target != _targetRevision ||
          selection != _selectionRevision ||
          !identical(preview, _preview) ||
          _pendingChoices > 0 ||
          _checksDirty) {
        return const ChangeExplanationSuggestion(available: false);
      }
      // Explanation quota is a different product from modification quota.
      return ChangeExplanationSuggestion.fromResult(result);
    } catch (error) {
      return ChangeExplanationSuggestion(
        available: false,
        error: ApiFailure.from(error).message,
      );
    }
  }

  void _editAfter(
    BuildContext context,
    ModificationOperation operation,
    String input,
  ) {
    final expected = operation.after ?? operation.before;
    Object? after;
    try {
      after = expected is String ? input : jsonDecode(input);
      final matches = switch (expected) {
        num() => after is num,
        bool() => after is bool,
        List() => after is List,
        Map() => after is Map,
        String() => after is String,
        _ => true,
      };
      if (!matches ||
          !validateRecipeOperation({
            'operation': 'text_choose',
            'operation_id': operation.operationId,
            'decision': 'modify',
            'after': after,
          })) {
        throw const FormatException();
      }
    } catch (_) {
      setState(() {
        _afterInputs[operation.operationId] = input;
        _invalidAfter[operation.operationId] = expected is num
            ? '请输入有效的 JSON 数值。'
            : '请输入与原值类型一致的有效 JSON（最多 4000 字符）。';
        _selectionRevision++;
        _checksDirty = true;
        _explanationFingerprint = null;
      });
      _editTimer?.cancel();
      _persistLater();
      return;
    }
    setState(() {
      _afterInputs[operation.operationId] = input;
      _invalidAfter.remove(operation.operationId);
    });
    unawaited(
      _dispatch(context, {
        'operation': 'text_choose',
        'operation_id': operation.operationId,
        'decision': 'modify',
        'after': after,
      }),
    );
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
        '${operation.reason}\n风险：${operation.risk}\n把握程度：${operation.confidence >= 0.8
            ? '高'
            : operation.confidence >= 0.5
            ? '中'
            : '低'}\n依赖操作：${operation.dependsOn?.isNotEmpty == true ? operation.dependsOn!.join('、') : '无'}';
    return ComponentCard(
      key: ValueKey('text-edit-operation-${operation.operationId}'),
      detail: ComponentDescriptorDetailEnum.detailed,
      conclusion: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('目标：${operation.id ?? '菜谱信息'} · ${operation.field}'),
          Text('修改前：${_displayValue(operation.before)}'),
          Text('建议后值：${_displayValue(operation.after)}'),
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
            value: _displayValue(operation.after),
            originalValue: operation.before == null
                ? null
                : _displayValue(operation.before),
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
                      _locked ||
                          _checking ||
                          _pendingChoices > 0 ||
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
                            'after': choice?.after ?? operation.after,
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
              initialValue:
                  _afterInputs[operation.operationId] ??
                  _editValue(choice?.after ?? operation.after),
              enabled: !_locked && !widget.manualEdits,
              maxLength: 4000,
              minLines: 1,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: (operation.after ?? operation.before) is String
                    ? '修改后的文字'
                    : '修改后的 JSON 值',
                errorText: _invalidAfter[operation.operationId],
              ),
              onChanged: (after) => _editAfter(context, operation, after),
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
  Widget build(BuildContext context) {
    super.build(context);
    return RecipeOperationScope(
      handlers: {
        'text_preview': (params) => _propose(params['text'] as String),
        'text_choose': _choose,
        'text_confirm': (_) => _confirm(),
        'text_cancel': (_) => _cancel(),
        'text_retry_status': (_) => _loadStatus(),
        'text_retry_checks': (_) => _checkSelection(),
        'explain_changes': (_) async {
          if (_canConfirm && _pendingConfirmation == null) {
            _explanationResult = await _explain(_preview!);
          }
        },
      },
      child: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('一句话修改菜谱', style: Theme.of(context).textTheme.titleMedium),
            const Text('支持改文字、换厨具、调整时间或难度、调整做法；口味和缺料替代暂未支持。确认前不会保存。'),
            const Text('请勿输入个人敏感信息。手动编辑和保存始终可用。'),
            if (widget.manualEdits) const Text('当前有未保存的表单修改，请先手动保存，再请求文字修改。'),
            Text(
              _status == null
                  ? '正在读取今日修改额度…'
                  : '今日修改剩余 ${_status!.remaining} 次',
              key: const ValueKey('text-edit-quota'),
            ),
            if (_status?.available == false) Text(_reason(_status?.reason)),
            TextField(
              key: const ValueKey('text-edit-input'),
              controller: _text,
              enabled:
                  !_locked &&
                  !_checking &&
                  _pendingChoices == 0 &&
                  !widget.manualEdits,
              maxLength: 1000,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '想怎样修改菜谱？'),
              onChanged: (_) {
                setState(() {
                  _requestId = null;
                  _failedRequest = false;
                });
                _persistLater();
              },
              onSubmitted: (text) {
                if (_canRequest) {
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
                  _locked ||
                      _checking ||
                      _pendingChoices > 0 ||
                      widget.manualEdits ||
                      !_canRequest ||
                      _text.text.trim().isEmpty
                  ? null
                  : () => _dispatch(context, {
                      'operation': 'text_preview',
                      'text': _text.text,
                    }),
              child: const Text('预览菜谱修改'),
            ),
            if (_busy || _checking) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(_error!, key: const ValueKey('text-edit-error')),
              if (_status == null)
                TextButton(
                  key: const ValueKey('text-edit-retry-status'),
                  onPressed: () =>
                      _dispatch(context, {'operation': 'text_retry_status'}),
                  child: const Text('重试读取修改额度'),
                ),
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
              if (_checksDirty && !_checking && _pendingChoices == 0)
                TextButton(
                  key: const ValueKey('text-edit-retry-checks'),
                  onPressed: () =>
                      _dispatch(context, {'operation': 'text_retry_checks'}),
                  child: const Text('重试检查所选修改'),
                ),
              if (_preview!.decisions?.isNotEmpty == true &&
                  _preview!.decisions!.every(
                    (choice) => choice.decision.value != 'pending',
                  ) &&
                  !widget.manualEdits)
                AbsorbPointer(
                  absorbing: !_canConfirm || _locked,
                  child: ChangeExplanationPanel(
                    key: const ValueKey('text-edit-explanation'),
                    // Check receipts may advance without changing selected
                    // content, including after restoring an unsaved draft.
                    bindingKey: (
                      _preview!.id,
                      jsonEncode([
                        for (final choice in _preview!.decisions!)
                          choice.toJson(),
                      ]),
                      _selectionRevision,
                    ),
                    changeNote: _changeNote,
                    noteAuthored: _changeNoteAuthored,
                    tagsAuthored: _tagsAuthored,
                    tagsTouched: _tags != null,
                    changesFingerprint: _explanationFingerprint,
                    tags: _tags ?? _preview!.snapshot.tags ?? [],
                    explain: _canConfirm && !_locked
                        ? () => _dispatchExplanation(context)
                        : null,
                    onChanged: (draft) {
                      setState(() {
                        _changeNote = draft.changeNote;
                        _changeNoteAuthored = draft.noteAuthored;
                        _tagsAuthored = draft.tagsAuthored;
                        _tags = draft.tagsTouched
                            ? List<String>.of(draft.tags)
                            : null;
                        _explanationFingerprint = draft.changesFingerprint;
                      });
                      _persistLater();
                    },
                  ),
                ),
              const Text('请逐条处理后确认。只保存私有版本，不公开，也不修改口味档案。'),
              FilledButton(
                key: const ValueKey('text-edit-confirm'),
                onPressed: _canConfirm
                    ? () => _dispatch(context, {'operation': 'text_confirm'})
                    : null,
                child: Text(
                  _pendingConfirmation == null ? '确认并保存所选修改' : '重试保存与本机清理',
                ),
              ),
              TextButton(
                key: const ValueKey('text-edit-cancel'),
                onPressed: _busy || _pendingChoices > 0
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
}

String _displayValue(Object? value) => value == null ? '无' : _editValue(value);
String _editValue(Object? value) => value is String ? value : jsonEncode(value);

String _reason(String? reason) => switch (reason) {
  'daily_quota' => '今日修改额度已用完。手动编辑和保存不受影响。',
  'monthly_budget' => '平台月预算已达到上限，AI 暂停。手动编辑和保存不受影响。',
  'configuration' => '模型配置暂不可用。手动编辑和保存不受影响。',
  'invalid_output' => 'AI 修改校验未通过，已纠正一次仍失败。原话保留，可重试或手动编辑。',
  'unsupported_intent' => '这类修改暂未支持，不会应用。支持改文字、换厨具、调整时间或难度、调整做法；口味和缺料替代请手动编辑。',
  'uncertain_intent' => '没把握理解这次修改。请换个说法，或手动编辑，不会硬改。',
  _ => '模型暂不可用。原话保留，可重试或手动编辑。',
};
