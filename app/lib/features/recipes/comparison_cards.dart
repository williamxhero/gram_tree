import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart'
    show ComponentDescriptorDetailEnum;

import '../../app/theme.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';

/// Display the server's grade without calculating comparison thresholds.
String comparisonGradeLabel(String grade) => switch (grade) {
  'excluded' => '不计配方幅度',
  'minor' => '微调',
  'general' => '一般',
  'significant' => '显著',
  _ => grade,
};

String comparisonConclusionLabel(String conclusion) => switch (conclusion) {
  'no_change' => '没有变化',
  'minor_only' => '只有微调',
  'general' => '一般改动',
  'significant' => '显著改动',
  _ => conclusion,
};

/// The caller chooses the layout; both values remain independently wrappable.
class ComparisonPair extends StatelessWidget {
  // The presentation API deliberately accepts only values and layout.
  // ignore: use_key_in_widget_constructors
  const ComparisonPair({
    required this.before,
    required this.after,
    required this.sideBySide,
  });

  final Widget before;
  final Widget after;
  final bool sideBySide;

  @override
  Widget build(BuildContext context) => sideBySide
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: before),
            const SizedBox(width: 16),
            Expanded(child: after),
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [before, const SizedBox(height: 12), after],
        );
}

/// A schema-independent, read-only view of a server-supplied comparison rule.
class ComparisonRuleCard extends StatelessWidget {
  const ComparisonRuleCard({
    super.key,
    required this.id,
    required this.title,
    required this.kindLabel,
    required this.before,
    required this.after,
    this.grade,
    this.basis,
    this.ruleId,
    this.rulesVersion,
    this.relativeChange,
    required this.sideBySide,
    this.expandDetails = false,
    this.details,
  });

  final String id;
  final String title;
  final String kindLabel;
  final String before;
  final String after;
  final String? grade;
  final String? basis;
  final String? ruleId;
  final String? rulesVersion;
  final String? relativeChange;
  final bool sideBySide;
  final bool expandDetails;
  final Widget? details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberStyle = GramTreeColors.of(context)
        .numberStyle(theme.textTheme.bodyMedium!);
    final ruleInfo = [
      if (ruleId != null) '规则：$ruleId',
      if (rulesVersion != null) '规则版本：$rulesVersion',
    ].join('\n');

    Widget value(String label, String text) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(text, style: numberStyle),
      ],
    );

    return ComponentCard(
      detail: ComponentDescriptorDetailEnum.detailed,
      conclusion: Text(title, style: theme.textTheme.titleLarge),
      conclusionSemanticsText: title,
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(kindLabel),
          const SizedBox(height: 8),
          ComparisonPair(
            before: value('之前', before),
            after: value('之后', after),
            sideBySide: sideBySide,
          ),
          if (relativeChange != null || grade != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (relativeChange != null)
                  Text('相对变化：$relativeChange', style: numberStyle),
                if (grade != null) Text('幅度：${comparisonGradeLabel(grade!)}'),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: SourceMark(
              key: ValueKey('comparison-why-$id'),
              sourceType: sourceTypeAuthorFilled,
              componentId: 'recipe-comparison',
              value: after,
              originalValue: before,
              valueChanged: false,
              basisText: basis ?? '',
              citation: ruleInfo.isEmpty ? null : ruleInfo,
              required: false,
              feedbackEnabled: false,
              neutral: true,
              showWhenAuthorFilled: true,
              labelOverride: '依据',
              whyTitleOverride: '比较依据',
              onAction: null,
            ),
          ),
        ],
      ),
      detailedExtra: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          // A change of detail preference must reset the initial expansion state.
          key: ValueKey('comparison-details-$id-$expandDetails'),
          initiallyExpanded: expandDetails,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: const Text('原始明细'),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('字段：$id'),
                  Text('变更类型：$kindLabel'),
                  Text('之前原值：$before', style: numberStyle),
                  Text('之后原值：$after', style: numberStyle),
                  if (relativeChange != null)
                    Text('相对变化原值：$relativeChange', style: numberStyle),
                  if (grade != null) Text('幅度原值：$grade'),
                  if (basis != null) Text('依据：$basis'),
                  if (ruleInfo.isNotEmpty) Text(ruleInfo),
                  if (details != null) ...[const SizedBox(height: 8), details!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
