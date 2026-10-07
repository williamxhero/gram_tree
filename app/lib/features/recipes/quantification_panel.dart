import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/recipe_operations.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';
import '../../util/ids.dart';

String confidenceLabel(String level) => switch (level) {
  'high' => '高',
  'medium' => '中',
  _ => '低',
};

/// The server owns proposal values and patching; this panel only collects choices.
class QuantificationPanel extends ConsumerStatefulWidget {
  const QuantificationPanel({
    super.key,
    required this.proposal,
    required this.onDecide,
    required this.onCancel,
  });
  final RecipeQuantificationOut proposal;
  final Future<void> Function(List<QuantificationDecision>, bool) onDecide;
  final VoidCallback onCancel;

  @override
  ConsumerState<QuantificationPanel> createState() =>
      _QuantificationPanelState();
}

class _QuantificationPanelState extends ConsumerState<QuantificationPanel> {
  final _decisions = <String, QuantificationDecision>{};
  final _operationCompositionId = newUuidV4();
  final _values = <String, String>{};
  final _units = <String, String>{};

  ComponentDescriptorDetailEnum get _detail => ComponentDescriptorDetailEnum
      .values
      .firstWhere((detail) => detail.value == widget.proposal.detail.value);

  void _choose(
    QuantificationSuggestion s,
    QuantificationDecisionDecisionEnum decision,
  ) {
    setState(
      () => _decisions[s.problemId] = QuantificationDecision(
        problemId: s.problemId,
        decision: decision,
        value: decision == QuantificationDecisionDecisionEnum.modify
            ? (_values[s.problemId] ?? s.value)
            : null,
        unit: decision == QuantificationDecisionDecisionEnum.modify
            ? (_units[s.problemId] ?? s.unit)
            : null,
      ),
    );
  }

  Future<void> _dispatch(BuildContext context, Map<String, dynamic> params) =>
      ref
          .read(intentDispatcherProvider)
          .dispatch(
            context,
            compositionId:
                CompositionIdScope.of(context) ?? _operationCompositionId,
            componentId: 'quantification-${widget.proposal.id}',
            action: ActionDescriptor(
              intent: 'recipe_operation',
              params: params,
            ),
          );

  Widget _suggestion(BuildContext context, QuantificationSuggestion s) {
    final problem = widget.proposal.problems.firstWhere(
      (p) => p.id == s.problemId,
    );
    final value = '${s.value}${s.unit == null ? '' : ' ${s.unit}'}';
    final evidence =
        '${s.basis}\n把握程度：${confidenceLabel(s.confidence.value)}${s.baseline == null ? '' : '\n基准：${s.baseline}\n调整方法：${s.adjustment}'}';
    return ComponentCard(
      detail: _detail,
      conclusionSemanticsText: '${problem.message}，建议 $value',
      conclusion: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(problem.message),
          Text(
            value,
            style: GramTreeColors.of(context)
                .numberStyle(Theme.of(context).textTheme.titleMedium!),
          ),
        ],
      ),
      basisText: s.basis,
      detailedExtra: Text(
        '把握程度：${confidenceLabel(s.confidence.value)}${s.baseline == null ? '' : '\n基准：${s.baseline}\n调整方法：${s.adjustment}'}',
      ),
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SourceMark(
            key: ValueKey('quantification-why-${s.problemId}'),
            sourceType: sourceTypeAiEstimated,
            componentId: 'quantification-${s.problemId}',
            value: value,
            originalValue: problem.original,
            basisText: evidence,
            required: false,
            feedbackEnabled: false,
            onAction: null,
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final choice in QuantificationDecisionDecisionEnum.values)
                OutlinedButton(
                  key: ValueKey(
                    'quantification-${choice.value}-${s.problemId}',
                  ),
                  onPressed: () => _dispatch(context, {
                    'operation': 'choose',
                    'problem_id': s.problemId,
                    'decision': choice.value,
                  }),
                  child: Text(switch (choice) {
                    QuantificationDecisionDecisionEnum.accept => '接受',
                    QuantificationDecisionDecisionEnum.modify => '修改',
                    _ => '忽略',
                  }),
                ),
            ],
          ),
          if (_decisions[s.problemId] != null)
            Text(
              '本条处理：${switch (_decisions[s.problemId]!.decision) {
                QuantificationDecisionDecisionEnum.accept => '接受',
                QuantificationDecisionDecisionEnum.modify => '修改',
                _ => '忽略',
              }}',
            ),
          if (_decisions[s.problemId]?.decision ==
              QuantificationDecisionDecisionEnum.modify) ...[
            TextFormField(
              key: ValueKey('quantification-value-${s.problemId}'),
              initialValue: _values[s.problemId] ?? s.value,
              decoration: const InputDecoration(labelText: '具体值或说明'),
              onChanged: (value) {
                _values[s.problemId] = value;
                _choose(s, QuantificationDecisionDecisionEnum.modify);
              },
            ),
            if (s.unit != null)
              TextFormField(
                key: ValueKey('quantification-unit-${s.problemId}'),
                initialValue: _units[s.problemId] ?? s.unit,
                decoration: const InputDecoration(labelText: '标准单位'),
                onChanged: (value) {
                  _units[s.problemId] = value;
                  _choose(s, QuantificationDecisionDecisionEnum.modify);
                },
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => RecipeOperationScope(
    handlers: {
      'choose': (params) {
        final s = widget.proposal.suggestions
            .where((s) => s.problemId == params['problem_id'])
            .firstOrNull;
        if (s != null) {
          _choose(
            s,
            QuantificationDecisionDecisionEnum.values.firstWhere(
              (d) => d.value == params['decision'],
            ),
          );
        }
      },
      'decide': (params) => widget.onDecide(
        recipeDecisions(params),
        params['accept_all'] == true,
      ),
      'cancel': (_) => widget.onCancel(),
    },
    child: Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ComponentCard(
            detail: _detail,
            conclusion: const Text('逐条确定 · 不会自动替换'),
            conclusionSemanticsText: '逐条确定 · 不会自动替换',
            basisText: '接受后标为 AI 估算；修改后标为作者填写；忽略仍需确定。',
            primaryActionLabel: _detail == ComponentDescriptorDetailEnum.brief
                ? '全部接受'
                : null,
            onPrimaryAction: () =>
                _dispatch(context, recipeDecisionParams(const [], true)),
            standardExtra: Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  key: const ValueKey('quantification-save-decisions'),
                  onPressed:
                      validateRecipeOperation(
                        recipeDecisionParams(_decisions.values.toList(), false),
                      )
                      ? () => _dispatch(
                          context,
                          recipeDecisionParams(
                            _decisions.values.toList(),
                            false,
                          ),
                        )
                      : null,
                  child: const Text('保存处理结果'),
                ),
                OutlinedButton(
                  key: const ValueKey('quantification-accept-all'),
                  onPressed: () =>
                      _dispatch(context, recipeDecisionParams(const [], true)),
                  child: const Text('全部接受'),
                ),
                TextButton(
                  onPressed: () => _dispatch(context, {'operation': 'cancel'}),
                  child: const Text('暂不处理'),
                ),
              ],
            ),
          ),
          for (final s in widget.proposal.suggestions) _suggestion(context, s),
        ],
      ),
    ),
  );
}
