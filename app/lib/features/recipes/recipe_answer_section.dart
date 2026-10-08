import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../auth/auth_controller.dart';
import '../../recipes/recipe_repository.dart';
import '../../ui_protocol/components/component_scaffold.dart';
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

class _RecipeAnswerSectionState extends ConsumerState<RecipeAnswerSection> {
  static const _basis = '这是一般经验，还没有足够记录验证';
  final _question = TextEditingController();
  RecipeAnswer? _answer;
  bool _busy = false;
  bool _failed = false;

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
      answer = await ref
          .read(recipeRepositoryProvider)
          .answerQuestion(detail.id, detail.version.id, question);
      if (answer.recipeId != detail.id ||
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
    RecipeAnswerStateEnum.answered => '已回答 · 一般经验',
    RecipeAnswerStateEnum.uncertain => '不确定 · 一般经验',
    RecipeAnswerStateEnum.cannotAnswer => '无法回答 · 一般经验',
    _ => '能力不可用 · 一般经验',
  };

  String get _unavailableReason =>
      switch (_answer?.error ?? _answer?.status.reason) {
        'monthly_budget' => '月预算已用完',
        'quota_exhausted' || 'daily_limit' || 'daily_quota' => '今日解释配额已用完',
        'timeout' => '模型响应超时',
        'disabled' || 'ai_disabled' => '模型已停用',
        'not_configured' || 'not_enabled' => '模型暂未配置',
        _ => '模型或网络暂时不可用',
      };

  bool get _unavailable =>
      _failed || _answer?.state == RecipeAnswerStateEnum.unavailable;

  String get _conclusion =>
      _unavailable ? '菜谱解释（explain）：$_unavailableReason。' : _answer!.conclusion;

  Future<void> _showWhy() async {
    final answer = _answer;
    final safety =
        answer?.safety ??
        widget.detail.version.safety ??
        widget.detail.version.safetyAtSave;
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
                    const Expanded(child: Text('AI 估算 · 菜谱解释')),
                    TextButton(
                      key: const ValueKey('recipe-answer-close'),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('关闭解释'),
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
                      _basis,
                      '问题：${answer?.question ?? _question.text.trim()}',
                      if (_unavailable) '查看、表单编辑和规则换算仍可使用；问题已保留，可以重试。',
                      if (!_unavailable &&
                          answer?.explanation?.isNotEmpty == true)
                        answer!.explanation!,
                      if (!_unavailable && answer?.details?.isNotEmpty == true)
                        answer!.details!,
                      '明细 · 第 ${widget.detail.version.versionNumber} 版；解释不会自动修改菜谱。',
                      for (final finding
                          in safety?.findings ?? <RecipeSafetyFinding>[])
                        finding.message,
                      for (final claim
                          in safety?.prohibitedClaims ?? <String>[])
                        claim,
                      if (safety?.allergens?.isNotEmpty == true)
                        '过敏原：${safety!.allergens!.join('、')}',
                      if (safety?.replacementAllergens?.isNotEmpty == true)
                        '替换食材过敏原：${safety!.replacementAllergens!.join('、')}',
                      if (safety?.allergensIncomplete == true)
                        '过敏信息可能不完整，请核对实际食材。',
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
  Widget build(BuildContext context) => ComponentCard(
    detail: ComponentDescriptorDetailEnum.standard,
    conclusion: Text('问这版的做法', style: Theme.of(context).textTheme.titleMedium),
    conclusionSemanticsText: '问这版的做法；只提供一般经验，不改动菜谱',
    basisText: _basis,
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
          decoration: const InputDecoration(
            labelText: '厨房问题',
            hintText: '例如：这一步为什么要炒熟？',
          ),
          onSubmitted: (_) => _submit(),
          onChanged: (_) => setState(() {}),
        ),
        FilledButton(
          key: const ValueKey('recipe-answer-submit'),
          onPressed: _busy || _question.text.trim().isEmpty ? null : _submit,
          child: Text(
            _busy ? '正在解释…' : (_answer != null || _failed ? '重试解释' : '查看解释'),
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
                value: '一般经验',
                basisText: _basis,
                required: false,
                feedbackEnabled: false,
                onAction: null,
              ),
              TextButton(onPressed: _showWhy, child: const Text('为什么 · 明细')),
            ],
          ),
        ],
      ],
    ),
  );
}
