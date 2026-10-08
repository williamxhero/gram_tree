import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../auth/auth_controller.dart';
import '../../events/event_recorder.dart';
import '../../l10n/app_localizations.dart';
import '../../recipes/recipe_repository.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';

/// A single question about a confirmed immutable version, not a chat or edit.
class RecipeAnswerSection extends ConsumerStatefulWidget {
  const RecipeAnswerSection({super.key, required this.detail});
  final RecipeDetail detail;

  @override
  ConsumerState<RecipeAnswerSection> createState() =>
      _RecipeAnswerSectionState();
}

class _RecipeAnswerSectionState extends ConsumerState<RecipeAnswerSection>
    with AutomaticKeepAliveClientMixin {
  // Scrolling to rules or steps must not discard the version's question/answer.
  @override
  bool get wantKeepAlive => true;

  final _question = TextEditingController();
  RecipeAnswer? _answer;
  bool _busy = false;
  bool _failed = false;
  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final question = _question.text.trim();
    if (_busy || question.isEmpty) return;
    final owner = ref.read(authProvider).value?.id;
    final detail = widget.detail;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _answer = null;
      _failed = false;
    });
    RecipeAnswer? answer;
    try {
      final operation = ref.read(
        recipeAnswerOperationProvider((detail.id, detail.version.id)),
      );
      await ref
          .read(intentDispatcherProvider)
          .dispatch(
            context,
            compositionId: CompositionIdScope.of(context),
            componentId: 'recipe-answer',
            action: ActionDescriptor(
              intent: 'call_operation',
              params: {
                'operation': 'answer_recipe_question',
                'recipe_id': detail.id,
                'recipe_version_id': detail.version.id,
                'question': question,
              },
            ),
          );
      answer = operation.result;
      if (answer == null ||
          answer.recipeId != detail.id ||
          answer.versionId != detail.version.id ||
          answer.question != question) {
        throw StateError('Answer does not belong to this question/version');
      }
    } catch (_) {
      // Do not expose transport logs or lose the user's question on failure.
      answer = null;
    }
    if (!mounted ||
        ref.read(authProvider).value?.id != owner ||
        widget.detail.version.id != detail.version.id) {
      return;
    }
    setState(() {
      _busy = false;
      _answer = answer;
      _failed = answer == null;
    });
    await _showWhy();
  }

  String get _stateLabel => switch (_answer?.state) {
    RecipeAnswerStateEnum.answered => _l10n.recipeAnswerAnswered,
    RecipeAnswerStateEnum.uncertain => _l10n.recipeAnswerUncertain,
    RecipeAnswerStateEnum.cannotAnswer => _l10n.recipeAnswerCannotAnswer,
    _ => _l10n.recipeAnswerUnavailable,
  };

  String get _unavailableReason =>
      switch (_answer?.error ?? _answer?.status.reason) {
        'monthly_budget' => _l10n.recipeAnswerBudget,
        'quota_exhausted' ||
        'daily_limit' ||
        'daily_quota' => _l10n.recipeAnswerQuota,
        'timeout' => _l10n.recipeAnswerTimeout,
        'disabled' || 'ai_disabled' => _l10n.recipeAnswerDisabled,
        'not_configured' || 'not_enabled' => _l10n.recipeAnswerNotConfigured,
        _ => _l10n.recipeAnswerNetwork,
      };

  bool get _unavailable =>
      _failed || _answer?.state == RecipeAnswerStateEnum.unavailable;
  String get _conclusion => _unavailable
      ? _l10n.recipeAnswerUnavailableConclusion(_unavailableReason)
      : _answer!.conclusion;

  Future<void> _showWhy() async {
    final answer = _answer;
    // An incomplete response must never erase immutable-version warnings.
    final safetySources = [
      if (answer != null) answer.safety,
      if (widget.detail.version.safety != null) widget.detail.version.safety!,
      if (widget.detail.version.safetyAtSave != null)
        widget.detail.version.safetyAtSave!,
    ];
    final findings = {
      for (final safety in safetySources)
        for (final finding in safety.findings ?? <RecipeSafetyFinding>[])
          finding.message,
    };
    final claims = {
      for (final safety in safetySources) ...?safety.prohibitedClaims,
    };
    final allergens = {
      for (final safety in safetySources) ...?safety.allergens,
    };
    final replacements = {
      for (final safety in safetySources)
        for (final item
            in safety.replacementAllergens ?? <RecipeReplacementAllergens>[])
          '${item.displayName}：${(item.allergens ?? <String>[]).join('、')}',
    };
    final compositionId = CompositionIdScope.of(context);
    await ref
        .read(eventRecorderProvider)
        .record(
          eventType: 'ui.why_panel_opened',
          typeVersion: 1,
          correlation: compositionId == null
              ? null
              : EventCorrelationIds(uiCompositionId: compositionId),
          content: {
            'component_id': 'recipe-answer',
            'source_type': sourceTypeAiEstimated,
          },
        );
    if (!mounted) return;
    final l10n = _l10n;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.recipeAnswerSource)),
                    TextButton(
                      key: const ValueKey('recipe-answer-close'),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(l10n.recipeAnswerClose),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: WhyPanel(
                    key: const ValueKey('recipe-answer-why'),
                    sourceType: sourceTypeAiEstimated,
                    titleOverride: _stateLabel,
                    value: _conclusion,
                    basisText: [
                      l10n.recipeAnswerBasis,
                      l10n.recipeAnswerQuestion(
                        answer?.question ?? _question.text.trim(),
                      ),
                      if (_unavailable) l10n.recipeAnswerContinue,
                      if (!_unavailable &&
                          answer?.explanation?.isNotEmpty == true)
                        answer!.explanation!,
                      if (!_unavailable && answer?.details?.isNotEmpty == true)
                        answer!.details!,
                      l10n.recipeAnswerVersion(
                        widget.detail.version.versionNumber,
                      ),
                      ...findings,
                      ...claims,
                      if (allergens.isNotEmpty)
                        l10n.recipeAnswerAllergens(allergens.join('、')),
                      if (replacements.isNotEmpty)
                        l10n.recipeAnswerReplacementAllergens(
                          replacements.join('、'),
                        ),
                      if (safetySources.any(
                        (safety) =>
                            safety.allergensIncomplete == true ||
                            (safety.replacementAllergens ??
                                    <RecipeReplacementAllergens>[])
                                .any((item) => item.incomplete == true),
                      ))
                        l10n.recipeAnswerIncompleteAllergens,
                      ...?answer?.numericWarnings,
                    ].join('\n\n'),
                    required: true,
                    feedbackEnabled: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.watch(
      recipeAnswerOperationProvider((
        widget.detail.id,
        widget.detail.version.id,
      )),
    );
    final l10n = _l10n;
    return ComponentCard(
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Text(
        l10n.recipeAnswerTitle,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      conclusionSemanticsText: l10n.recipeAnswerSemantics,
      basisText: l10n.recipeAnswerBasis,
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const ValueKey('recipe-answer-input'),
            controller: _question,
            enabled: !_busy,
            maxLength: 1000,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.recipeAnswerInput,
              hintText: l10n.recipeAnswerHint,
            ),
            onSubmitted: (_) => _submit(),
            onChanged: (_) => setState(() {}),
          ),
          FilledButton(
            key: const ValueKey('recipe-answer-submit'),
            onPressed: _busy || _question.text.trim().isEmpty ? null : _submit,
            child: Text(
              _busy
                  ? l10n.recipeAnswerBusy
                  : (_answer != null || _failed
                        ? l10n.recipeAnswerRetry
                        : l10n.recipeAnswerSubmit),
            ),
          ),
          if (_answer != null || _failed) ...[
            Text(_conclusion, maxLines: 3, overflow: TextOverflow.ellipsis),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SourceMark(
                  sourceType: sourceTypeAiEstimated,
                  componentId: 'recipe-answer',
                  value: l10n.recipeAnswerExperience,
                  basisText: l10n.recipeAnswerBasis,
                  required: false,
                  feedbackEnabled: false,
                  onAction: null,
                ),
                TextButton(
                  onPressed: _showWhy,
                  child: Text(l10n.recipeAnswerWhy),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
