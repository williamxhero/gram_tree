import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../recipes/recipe_repository.dart';
import '../../ui_protocol/source_mark.dart';

Map<String, String> _flavors(AppLocalizations l10n) => {
  'salty': l10n.recipeFlavorSalty,
  'sweet': l10n.recipeFlavorSweet,
  'sour': l10n.recipeFlavorSour,
  'spicy': l10n.recipeFlavorSpicy,
  'umami': l10n.recipeFlavorUmami,
  'numbing': l10n.recipeFlavorNumbing,
  'oily': l10n.recipeFlavorOily,
};

String _summary(AppLocalizations l10n, RecipeFlavorContribution? contribution) {
  final values = contribution?.toJson() ?? const <String, dynamic>{};
  final known = [
    for (final axis in _flavors(l10n).entries)
      if (values[axis.key] != null)
        l10n.recipeFlavorStrength(axis.value, values[axis.key] as int),
  ];
  return known.isEmpty ? l10n.recipeFlavorUnknown : known.join(' · ');
}

/// Frozen recipe values, never a fresh read of the mutable ingredient library.
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

  Widget _source(
    BuildContext context,
    String field,
    String value,
    ValueSource? source,
  ) {
    if (source == null) return const SizedBox.shrink();
    return SourceMark(
      key: ValueKey('recipe-$field-source-$id'),
      sourceType: source.source_.value,
      componentId: 'recipe-$field-$id',
      value: value,
      basisText:
          source.basis ?? AppLocalizations.of(context).recipeFlavorAuthorBasis,
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
    final l10n = AppLocalizations.of(context);
    final summary = _summary(l10n, contribution);
    final known =
        contribution?.toJson().values.any((value) => value != null) ?? false;
    final functionalText = functional
        ? l10n.recipeFunctionalToggle
        : l10n.recipeFlavorFunctionalOff;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              summary,
              style: GramTreeColors.of(context)
                  .numberStyle(Theme.of(context).textTheme.bodyMedium!),
            ),
            if (known) _source(context, 'flavor', summary, flavorSource),
          ],
        ),
        if (functional || functionalSource != null)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(functionalText),
              _source(context, 'functional', functionalText, functionalSource),
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
    final l10n = AppLocalizations.of(context);
    final values =
        item.flavorContribution?.toJson() ?? const <String, dynamic>{};
    final numbers = GramTreeColors.of(context)
        .numberStyle(Theme.of(context).textTheme.bodyMedium!);
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
          title: Text(l10n.recipeFlavorEditorTitle),
          subtitle: Text(l10n.recipeFlavorEditorHint),
          children: [
            for (final axis in _flavors(l10n).entries)
              Padding(
                key: ValueKey('recipe-flavor-${axis.key}-${item.id}'),
                padding: const EdgeInsets.only(bottom: 8),
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  key: ValueKey(
                    'recipe-flavor-${axis.key}-${item.id}-${values[axis.key]}',
                  ),
                  initialValue: values[axis.key] as int? ?? -1,
                  decoration: InputDecoration(
                    labelText: l10n.recipeFlavorAxisLabel(axis.value),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: -1,
                      child: Text(l10n.recipeFlavorAxisUnknown(axis.value)),
                    ),
                    for (var strength = 0; strength <= 3; strength++)
                      DropdownMenuItem(
                        value: strength,
                        child: Text(
                          l10n.recipeFlavorStrength(axis.value, strength),
                          style: numbers,
                        ),
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
