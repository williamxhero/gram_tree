import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../l10n/app_localizations.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';

/// The parent keeps these values in its existing save form, never in an API call
/// made by this widget. A null fingerprint means hand-written fallback.
class ChangeExplanationDraft {
  const ChangeExplanationDraft({
    required this.changeNote,
    required this.tags,
    this.changesFingerprint,
    this.noteAuthored = true,
    this.tagsAuthored = true,
    this.tagsTouched = false,
  });

  final String changeNote;
  final List<String> tags;
  final String? changesFingerprint;
  final bool noteAuthored;
  final bool tagsAuthored;
  final bool tagsTouched;
}

/// Adapter seam for the generated change-explanation endpoint. The parent owns
/// the final operations/snapshot and maps the generated result to this value.
class ChangeExplanationSuggestion {
  const ChangeExplanationSuggestion({
    required this.available,
    this.changeNote,
    this.tags = const [],
    this.source,
    this.changesFingerprint,
    this.reason,
    this.error,
  });

  factory ChangeExplanationSuggestion.fromResult(
    ChangeExplanationResult result,
  ) => ChangeExplanationSuggestion(
    available:
        result.error == null &&
        result.changeNote?.trim().isNotEmpty == true &&
        result.changesFingerprint.isNotEmpty,
    changeNote: result.changeNote,
    tags: result.tags ?? const [],
    source: result.source_?.value,
    changesFingerprint: result.error == null ? result.changesFingerprint : null,
    reason: result.status.reason,
    error: result.error,
  );

  final bool available;
  final String? changeNote;
  final List<String> tags;
  final String? source;
  final String? changesFingerprint;
  final String? reason;
  final String? error;
}

/// Editable explanation shared by confirmed AI operations and manual forms.
///
/// [bindingKey] must change with the target/base version, confirmed revision or
/// real snapshot changes, but not when explanation-output tags/note change.
class ChangeExplanationPanel extends StatefulWidget {
  const ChangeExplanationPanel({
    super.key,
    required this.bindingKey,
    required this.changeNote,
    required this.tags,
    required this.onChanged,
    this.explain,
    this.unavailableReason,
    this.noteAuthored,
    this.tagsAuthored,
    this.changesFingerprint,
    this.tagsTouched = false,
  });

  final Object bindingKey;
  final String changeNote;
  final List<String> tags;
  final ValueChanged<ChangeExplanationDraft> onChanged;
  final Future<ChangeExplanationSuggestion> Function()? explain;
  final String? unavailableReason;
  // Null preserves compatibility with pre-ownership form drafts.
  final bool? noteAuthored;
  final bool? tagsAuthored;
  final String? changesFingerprint;
  final bool tagsTouched;

  @override
  State<ChangeExplanationPanel> createState() => _ChangeExplanationPanelState();
}

class _ChangeExplanationPanelState extends State<ChangeExplanationPanel> {
  late final TextEditingController _note;
  late final TextEditingController _tags;
  String? _fingerprint;
  String? _source;
  bool _busy = false;
  late bool _noteAuthored;
  late bool _tagsAuthored;
  late bool _tagsTouched;
  String? _message;
  int _requestEpoch = 0;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.changeNote);
    _tags = TextEditingController(text: widget.tags.join('，'));
    _noteAuthored = widget.noteAuthored ?? widget.changeNote.trim().isNotEmpty;
    _tagsAuthored = widget.tagsAuthored ?? widget.tags.isNotEmpty;
    _tagsTouched = widget.tagsTouched;
    _fingerprint = widget.changesFingerprint;
    if ((!_noteAuthored && widget.changeNote.isNotEmpty) ||
        (!_tagsAuthored && widget.tags.isNotEmpty)) {
      _source = sourceTypeAiEstimated;
    }
  }

  @override
  void didUpdateWidget(ChangeExplanationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Echoes of our callback are not author edits. Independent parent updates
    // are: they must appear immediately and outrank a pending model response.
    if (widget.changeNote != oldWidget.changeNote &&
        widget.changeNote.trim() != _note.text.trim()) {
      _note.text = widget.changeNote;
      _noteAuthored = true;
    }
    if (!listEquals(widget.tags, oldWidget.tags) &&
        !listEquals(widget.tags, _tagValues)) {
      _tags.text = widget.tags.join('，');
      _tagsAuthored = true;
    }
    if (widget.noteAuthored != null &&
        widget.noteAuthored != oldWidget.noteAuthored) {
      _noteAuthored = widget.noteAuthored!;
    }
    if (widget.tagsAuthored != null &&
        widget.tagsAuthored != oldWidget.tagsAuthored) {
      _tagsAuthored = widget.tagsAuthored!;
    }
    if (widget.changesFingerprint != oldWidget.changesFingerprint) {
      _fingerprint = widget.changesFingerprint;
    }
    if (widget.tagsTouched != oldWidget.tagsTouched) {
      _tagsTouched = widget.tagsTouched;
    }
    if (_busy && (widget.unavailableReason != null || widget.explain == null)) {
      _requestEpoch++;
      _busy = false;
    }
    if (widget.bindingKey != oldWidget.bindingKey) {
      _requestEpoch++;
      _busy = false;
      _fingerprint = null;
      _source = null;
      _message = '改动已变化，请重新生成说明或手写。';
      if (!_noteAuthored) _note.clear();
      if (!_tagsAuthored) {
        _tags.clear();
        _tagsTouched = false;
      }
      final binding = widget.bindingKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.bindingKey == binding) _notify();
      });
    }
  }

  @override
  void dispose() {
    _note.dispose();
    _tags.dispose();
    super.dispose();
  }

  List<String> get _tagValues => _tags.text
      .split(RegExp('[,，]'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  void _notify() => widget.onChanged(
    ChangeExplanationDraft(
      changeNote: _note.text.trim(),
      tags: _tagValues,
      changesFingerprint: _fingerprint,
      noteAuthored: _noteAuthored,
      tagsAuthored: _tagsAuthored,
      tagsTouched: _tagsTouched,
    ),
  );

  Future<void> _generate() async {
    final explain = widget.explain;
    if (_busy || explain == null) return;
    final epoch = ++_requestEpoch;
    setState(() {
      _busy = true;
      _message = null;
    });
    late final ChangeExplanationSuggestion suggestion;
    try {
      suggestion = await explain();
    } catch (_) {
      if (mounted && epoch == _requestEpoch) {
        setState(() {
          _busy = false;
          _message = _failureMessage(null);
        });
      }
      return;
    }
    if (!mounted || epoch != _requestEpoch) return;
    if (!suggestion.available ||
        suggestion.error != null ||
        suggestion.changeNote?.trim().isNotEmpty != true ||
        suggestion.source != sourceTypeAiEstimated ||
        suggestion.changesFingerprint?.isNotEmpty != true) {
      setState(() {
        _busy = false;
        _message = _failureMessage(suggestion.error ?? suggestion.reason);
      });
      return;
    }
    setState(() {
      _busy = false;
      if (!_noteAuthored) _note.text = suggestion.changeNote ?? '';
      if (!_tagsAuthored) {
        _tags.text = suggestion.tags.join('，');
        _tagsTouched = true;
      }
      _fingerprint = suggestion.changesFingerprint;
      _source = suggestion.source;
    });
    _notify();
  }

  String _failureMessage(String? reason) => switch (reason) {
    'model_unavailable' => '模型暂不可用，可手写说明和标签。',
    'daily_quota' => '今日 AI 额度已用完，可手写说明和标签。',
    'monthly_budget' => 'AI 预算暂不可用，可手写说明和标签。',
    'no_changes' => '本次没有可说明的实际改动，可手写说明和标签。',
    _ => '说明生成失败，请重试或手写说明和标签。',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ComponentCard(
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Text('改动说明', style: Theme.of(context).textTheme.titleMedium),
      conclusionSemanticsText: '改动说明',
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_source == sourceTypeAiEstimated &&
              ((!_noteAuthored && _note.text.isNotEmpty) ||
                  (!_tagsAuthored && _tagValues.isNotEmpty)))
            Align(
              alignment: Alignment.centerLeft,
              child: SourceMark(
                sourceType: sourceTypeAiEstimated,
                componentId: 'change-explanation',
                value: [
                  if (!_noteAuthored) _note.text,
                  if (!_tagsAuthored) ..._tagValues,
                ].join('；'),
                basisText: '仅依据本次最终改动生成，不代表已做过验证。作者可以修改说明和标签。',
                required: false,
                valueChanged: false,
                feedbackEnabled: false,
                onAction: null,
              ),
            ),
          TextFormField(
            key: const ValueKey('change-explanation-note'),
            controller: _note,
            decoration: InputDecoration(labelText: l10n.recipeChangeNote),
            minLines: 1,
            maxLines: 4,
            onChanged: (_) {
              setState(() => _noteAuthored = true);
              _notify();
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('change-explanation-tags'),
            controller: _tags,
            decoration: InputDecoration(labelText: l10n.recipeTags),
            onChanged: (_) {
              setState(() {
                _tagsAuthored = true;
                _tagsTouched = true;
              });
              _notify();
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              key: const ValueKey('change-explanation-generate'),
              onPressed:
                  _busy ||
                      widget.explain == null ||
                      widget.unavailableReason != null
                  ? null
                  : _generate,
              child: Text(_busy ? '正在生成说明…' : '生成改动说明'),
            ),
          ),
          Text(
            '${widget.unavailableReason ?? _message ?? '可手写说明和标签'} 手动保存不受影响。',
          ),
        ],
      ),
    );
  }
}
