import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../ui_protocol/source_mark.dart';
import 'quantification_panel.dart';

String recipeSourceBasis(ValueSource? source) => [
  if (source?.basis?.isNotEmpty == true) source!.basis!,
  if (source?.confidenceLevel != null)
    '把握程度：${confidenceLabel(source!.confidenceLevel!.value)}'
  else if (source?.confidence != null)
    '把握程度：${confidenceLabel(source!.confidence! >= 0.85
        ? 'high'
        : source.confidence! >= 0.6
        ? 'medium'
        : 'low')}',
  if (source?.baseline?.isNotEmpty == true) '基准：${source!.baseline}',
  if (source?.adjustment?.isNotEmpty == true) '调整方法：${source!.adjustment}',
].join('\n');

/// Recipe fields reuse the unified source badge and read-only why panel.
class RecipeSourceBadge extends StatelessWidget {
  const RecipeSourceBadge({
    super.key,
    required this.source,
    required this.value,
    required this.fieldId,
  });
  final ValueSource? source;
  final String value;
  final String fieldId;

  @override
  Widget build(BuildContext context) => source == null
      ? const SizedBox.shrink()
      : SourceMark(
          sourceType: source!.source_.value,
          componentId: fieldId,
          value: value,
          originalValue: source!.original,
          basisText: recipeSourceBasis(source),
          required: false,
          feedbackEnabled: false,
          onAction: null,
        );
}
