import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';

/// A display-only interpretation, never a comparison grade or saved conclusion.
class ComparisonInterpretationCard extends StatelessWidget {
  const ComparisonInterpretationCard({
    super.key,
    required this.interpretation,
    required this.rulesVersion,
  });

  final SourcedValue? interpretation;
  final String rulesVersion;

  @override
  Widget build(BuildContext context) {
    final value = interpretation;
    if (value == null ||
        value.sourceType != SourcedValueSourceTypeEnum.aiEstimated ||
        value.basis.reasonCode != 'general_experience' ||
        value.value.trim().isEmpty) {
      return const Padding(
        key: ValueKey('comparison-interpretation-unavailable'),
        padding: EdgeInsets.all(16),
        child: Text('暂缺 AI 解读；确定性比较仍然可用。'),
      );
    }
    return ComponentCard(
      key: const ValueKey('comparison-interpretation'),
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Text(
        value.value,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      conclusionSemanticsText: value.value,
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI 一句话解读 · 不参与变化幅度判定'),
          SourceMark(
            key: const ValueKey('comparison-interpretation-why'),
            sourceType: sourceTypeAiEstimated,
            componentId: 'recipe-comparison-interpretation',
            value: value.value,
            valueChanged: false,
            basisText: value.basis.text,
            citation: [
              '一般经验 · ${value.basis.reasonCode}',
              '规则版本：$rulesVersion',
              if (value.basis.citation != null) value.basis.citation!,
            ].join('\n'),
            required: false,
            feedbackEnabled: false,
            labelOverride: 'AI · 一般经验',
            whyTitleOverride: 'AI 解读依据',
            onAction: null,
          ),
        ],
      ),
    );
  }
}
