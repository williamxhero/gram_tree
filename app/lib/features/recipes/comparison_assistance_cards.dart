import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';
import 'comparison_cards.dart';
import 'comparison_snapshot_details.dart';

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

/// An already accepted AI pair. Original steps and deterministic cards coexist.
class ComparisonAssistedStepCard extends StatelessWidget {
  const ComparisonAssistedStepCard({
    super.key,
    required this.id,
    required this.pair,
    required this.before,
    required this.after,
    required this.beforeIndex,
    required this.afterIndex,
    required this.rulesVersion,
    required this.sideBySide,
    this.expandDetails = false,
    this.beforeIngredientNames = const {},
    this.afterIngredientNames = const {},
    this.beforeStepNumbers = const {},
    this.afterStepNumbers = const {},
  });

  final String id;
  final AssistedStepPair pair;
  final RecipeStep before;
  final RecipeStep after;
  final int beforeIndex;
  final int afterIndex;
  final String rulesVersion;
  final bool sideBySide;
  final bool expandDetails;
  final Map<String, String> beforeIngredientNames;
  final Map<String, String> afterIngredientNames;
  final Map<String, int> beforeStepNumbers;
  final Map<String, int> afterStepNumbers;

  @override
  Widget build(BuildContext context) {
    final confidence = '把握程度：${(pair.confidence * 100).toStringAsFixed(0)}%';
    final title = 'AI 辅助展示 · A 第 $beforeIndex 步 → B 第 $afterIndex 步';
    return ComponentCard(
      key: ValueKey('comparison-assistance-pair-$id'),
      detail: ComponentDescriptorDetailEnum.detailed,
      conclusion: Text(title, style: Theme.of(context).textTheme.titleLarge),
      conclusionSemanticsText: title,
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('仅辅助阅读；确定规则仍按原来的新增/删除计算。'),
          Text(
            confidence,
            style: GramTreeColors.of(context)
                .numberStyle(Theme.of(context).textTheme.bodyMedium!),
          ),
          ComparisonPair(
            before: Text('A · ${before.instruction}'),
            after: Text('B · ${after.instruction}'),
            sideBySide: sideBySide,
          ),
          SourceMark(
            key: ValueKey('comparison-assistance-why-$id'),
            sourceType: pair.sourceType.value,
            componentId: 'recipe-comparison-assistance-$id',
            value: 'A 第 $beforeIndex 步 → B 第 $afterIndex 步',
            valueChanged: false,
            basisText:
                '${pair.basis.text}\n$confidence\n服务端把握程度原值：${pair.confidence}',
            citation: [
              '依据代码：${pair.basis.reasonCode}',
              '规则版本：$rulesVersion',
              if (pair.basis.citation != null) pair.basis.citation!,
            ].join('\n'),
            required: false,
            feedbackEnabled: false,
            labelOverride: 'AI 辅助对齐',
            whyTitleOverride: 'AI 辅助对齐依据',
            onAction: null,
          ),
        ],
      ),
      detailedExtra: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          key: ValueKey('comparison-assistance-details-$id-$expandDetails'),
          initiallyExpanded: expandDetails,
          tilePadding: EdgeInsets.zero,
          title: const Text('辅助展示 · 双方完整原文'),
          children: [
            ComparisonPair(
              before: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('A · 原始快照'),
                  ComparisonStepDetails(
                    value: before,
                    ingredientNames: beforeIngredientNames,
                    stepNumbers: beforeStepNumbers,
                  ),
                ],
              ),
              after: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('B · 原始快照'),
                  ComparisonStepDetails(
                    value: after,
                    ingredientNames: afterIngredientNames,
                    stepNumbers: afterStepNumbers,
                  ),
                ],
              ),
              sideBySide: sideBySide,
            ),
          ],
        ),
      ),
    );
  }
}
