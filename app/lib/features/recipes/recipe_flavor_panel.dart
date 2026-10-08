import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../recipes/recipe_repository.dart';
import '../../ui_protocol/source_mark.dart';

const _flavors = {
  'salty': '咸',
  'sweet': '甜',
  'sour': '酸',
  'spicy': '辣',
  'umami': '鲜',
  'numbing': '麻',
  'oily': '油',
};

String _summary(RecipeFlavorContribution? contribution) {
  if (contribution == null) return '味型贡献未填写';
  final values = contribution.toJson();
  final known = [
    for (final axis in _flavors.entries)
      if (values[axis.key] != null) '${axis.value} ${values[axis.key]}',
  ];
  return known.isEmpty ? '味型贡献未填写' : known.join(' · ');
}

/// Both mutable and immutable surfaces explain the recipe's frozen values, not
/// the current ingredient library. Library proofreading is not cooking proof.
class RecipeFlavorSummary extends StatelessWidget {
  const RecipeFlavorSummary({
    super.key,
    required this.id,
    required this.contribution,
    required this.flavorSource,
    required this.functional,
    required this.functionalSource,
  });

  final String id;
  final RecipeFlavorContribution? contribution;
  final ValueSource? flavorSource;
  final bool functional;
  final ValueSource? functionalSource;

  Widget _source(String field, String value, ValueSource? source) {
    if (source == null) return const SizedBox.shrink();
    return SourceMark(
      key: ValueKey('recipe-$field-source-$id'),
      sourceType: source.source_.value,
      componentId: 'recipe-$field-$id',
      value: value,
      basisText: source.basis ?? '作者按这道菜的实际作用填写',
      originalValue: source.original,
      showWhenAuthorFilled: true,
      required: false,
      valueChanged: false,
      feedbackEnabled: false,
      onAction: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary(contribution);
    final functionalText = functional ? '功能性用料' : '不作功能性用料';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [Text(summary), _source('flavor', summary, flavorSource)],
        ),
        if (functional || functionalSource != null)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(functionalText),
              _source('functional', functionalText, functionalSource),
            ],
          ),
      ],
    );
  }
}

class RecipeFlavorEditor extends StatelessWidget {
  const RecipeFlavorEditor({
    super.key,
    required this.item,
    required this.onChanged,
  });

  final RecipeIngredientDraft item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final values =
        item.flavorContribution?.toJson() ?? const <String, dynamic>{};
    return Column(
      key: ValueKey('recipe-flavor-editor-${item.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RecipeFlavorSummary(
          id: item.id,
          contribution: item.flavorContribution,
          flavorSource: item.flavorSource,
          functional: item.functional,
          functionalSource: item.functionalSource,
        ),
        ExpansionTile(
          key: ValueKey('recipe-flavor-expand-${item.id}'),
          title: const Text('这道菜的味型贡献'),
          subtitle: const Text('强度 0–3；未填写不代表零贡献'),
          children: [
            for (final axis in _flavors.entries)
              Padding(
                key: ValueKey('recipe-flavor-${axis.key}-${item.id}'),
                padding: const EdgeInsets.only(bottom: 8),
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  key: ValueKey(
                    'recipe-flavor-${axis.key}-${item.id}-${values[axis.key]}',
                  ),
                  initialValue: values[axis.key] as int? ?? -1,
                  decoration: InputDecoration(labelText: '${axis.value}味贡献'),
                  items: [
                    DropdownMenuItem(
                      value: -1,
                      child: Text('${axis.value} 未填写'),
                    ),
                    for (var strength = 0; strength <= 3; strength++)
                      DropdownMenuItem(
                        value: strength,
                        child: Text('${axis.value} $strength'),
                      ),
                  ],
                  onChanged: (value) {
                    item.setFlavor(axis.key, value == -1 ? null : value);
                    onChanged();
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}
