import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';

String confidenceLabel(String level) => switch (level) {
  'high' => '高',
  'medium' => '中',
  _ => '低',
};

/// The server owns proposal values and patching; this panel only collects choices.
class QuantificationPanel extends StatefulWidget {
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
  State<QuantificationPanel> createState() => _QuantificationPanelState();
}

class _QuantificationPanelState extends State<QuantificationPanel> {
  final _decisions = <String, QuantificationDecision>{};
  final _values = <String, String>{};
  final _units = <String, String>{};

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

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('逐条确定 · 不会自动替换', style: Theme.of(context).textTheme.titleMedium),
          const Text('接受后标为 AI 估算；修改后标为作者填写；忽略仍需确定。'),
          for (final s in widget.proposal.suggestions) ...[
            const Divider(),
            Text(
              widget.proposal.problems
                  .firstWhere((p) => p.id == s.problemId)
                  .message,
            ),
            Text(
              '${s.value}${s.unit == null ? '' : ' ${s.unit}'}',
              style: GramTreeColors.of(context)
                  .numberStyle(Theme.of(context).textTheme.titleMedium!),
            ),
            Text(s.basis),
            Text('把握程度：${confidenceLabel(s.confidence.value)}'),
            if (s.baseline != null) Text('基准：${s.baseline}'),
            if (s.adjustment != null) Text('调整方法：${s.adjustment}'),
            SourceMark(
              key: ValueKey('quantification-why-${s.problemId}'),
              sourceType: sourceTypeAiEstimated,
              componentId: 'quantification-${s.problemId}',
              value: '${s.value} ${s.unit ?? ''}',
              originalValue: widget.proposal.problems
                  .firstWhere((p) => p.id == s.problemId)
                  .original,
              basisText:
                  '${s.basis}\n把握程度：${confidenceLabel(s.confidence.value)}${s.baseline == null ? '' : '\n基准：${s.baseline}\n调整方法：${s.adjustment}'}',
              required: false,
              feedbackEnabled: false,
              onAction: null,
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  key: ValueKey('quantification-accept-${s.problemId}'),
                  onPressed: () =>
                      _choose(s, QuantificationDecisionDecisionEnum.accept),
                  child: const Text('接受'),
                ),
                OutlinedButton(
                  key: ValueKey('quantification-modify-${s.problemId}'),
                  onPressed: () =>
                      _choose(s, QuantificationDecisionDecisionEnum.modify),
                  child: const Text('修改'),
                ),
                TextButton(
                  key: ValueKey('quantification-ignore-${s.problemId}'),
                  onPressed: () =>
                      _choose(s, QuantificationDecisionDecisionEnum.ignore),
                  child: const Text('忽略'),
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
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                key: const ValueKey('quantification-save-decisions'),
                onPressed: _decisions.isEmpty
                    ? null
                    : () => widget.onDecide(_decisions.values.toList(), false),
                child: const Text('保存处理结果'),
              ),
              OutlinedButton(
                key: const ValueKey('quantification-accept-all'),
                onPressed: () => widget.onDecide(const [], true),
                child: const Text('全部接受'),
              ),
              TextButton(onPressed: widget.onCancel, child: const Text('暂不处理')),
            ],
          ),
        ],
      ),
    ),
  );
}
