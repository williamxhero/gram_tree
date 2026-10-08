import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../recipes/recipe_repository.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/source_mark.dart';

/// Ingredient-only comparison. No client-side pairing, arithmetic or severity.
class IngredientComparisonPage extends ConsumerStatefulWidget {
  const IngredientComparisonPage({
    super.key,
    required this.recipeId,
    required this.fromVersionId,
    required this.toVersionId,
  });
  final String recipeId;
  final String fromVersionId;
  final String toVersionId;

  @override
  ConsumerState<IngredientComparisonPage> createState() =>
      _IngredientComparisonPageState();
}

class _IngredientComparisonPageState
    extends ConsumerState<IngredientComparisonPage> {
  late Future<RecipeIngredientComparison> _result;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _result = ref
        .read(recipeRepositoryProvider)
        .compareIngredients(
          widget.recipeId,
          widget.fromVersionId,
          widget.toVersionId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recipeComparisonTitle)),
      body: FutureBuilder<RecipeIngredientComparison>(
        future: _result,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.recipeComparisonError),
                  TextButton(
                    onPressed: () => setState(_load),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data!;
          final media = MediaQuery.sizeOf(context);
          final sideBySide = media.width >= 600 || media.width > media.height;
          final headers = [
            _version(result.fromVersion, l10n.recipeComparisonFrom, 'a'),
            _version(result.toVersion, l10n.recipeComparisonTo, 'b'),
          ];
          return ListView(
            key: const ValueKey('ingredient-comparison-content'),
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.recipeComparisonScope),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: sideBySide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: headers[0]),
                          const SizedBox(width: 12),
                          Expanded(child: headers[1]),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          headers[0],
                          const SizedBox(height: 12),
                          headers[1],
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.recipeComparisonServings(result.normalizedServings),
                ),
              ),
              if (result.fromVersion.servings != result.toVersion.servings)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SourceMark(
                    sourceType: 'scenario_adjusted',
                    componentId: 'ingredient-comparison-servings',
                    value: l10n.recipeComparisonServingValue(
                      result.normalizedServings,
                    ),
                    originalValue: l10n.recipeComparisonServingValue(
                      result.toVersion.servings,
                    ),
                    basisText: l10n.recipeComparisonServingBasis,
                    required: true,
                    feedbackEnabled: false,
                    onAction: null,
                  ),
                ),
              SwitchListTile(
                key: const ValueKey('compare-show-all'),
                title: Text(l10n.recipeComparisonShowAll),
                value: _showAll,
                onChanged: (value) => setState(() => _showAll = value),
              ),
              if (result.ingredients.every(
                (row) => row.changes?.isEmpty ?? true,
              ))
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.recipeComparisonEmpty),
                ),
              for (final kind in ComparisonChangeKindEnum.values) ...[
                if (result.ingredients.any(
                  (row) => row.changes?.any((c) => c.kind == kind) ?? false,
                ))
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _kindLabel(l10n, kind),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                for (final row in result.ingredients)
                  for (final change in row.changes ?? <ComparisonChange>[])
                    if (change.kind == kind)
                      _DiffCard(
                        row: row,
                        change: change,
                        sideBySide: sideBySide,
                      ),
              ],
              if (_showAll)
                for (final row in result.ingredients)
                  if (row.changes?.isEmpty ?? true)
                    _DiffCard(row: row, sideBySide: sideBySide),
              if (result.snapshotFields?.isNotEmpty ?? false) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.recipeComparisonSnapshotFields,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final change in result.snapshotFields!)
                  _DiffCard(change: change, sideBySide: sideBySide),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _version(ComparisonVersion version, String label, String key) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: ValueKey('compare-version-$key'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label · ${version.dishName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.recipeComparisonVersion(
                version.author,
                version.versionNumber,
                version.servings,
              ),
            ),
            TextButton(
              key: ValueKey('compare-detail-$key'),
              onPressed: () => ref
                  .read(intentDispatcherProvider)
                  .dispatch(
                    context,
                    compositionId: CompositionIdScope.of(context),
                    componentId: 'compare-detail-$key',
                    action: ActionDescriptor(
                      intent: 'open_page',
                      params: {
                        'page': 'recipe_version',
                        'recipe_id': version.recipeId,
                        'version_id': version.versionId,
                      },
                    ),
                  ),
              child: Text(l10n.recipeComparisonDetails),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiffCard extends StatelessWidget {
  const _DiffCard({this.row, this.change, required this.sideBySide});
  final IngredientComparisonRow? row;
  final ComparisonChange? change;
  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = row?.after ?? row?.before;
    final title = item?.displayName ?? _fieldLabel(l10n, change!.field);
    final basis = change?.basis ?? l10n.recipeComparisonUnchangedBasis;
    final before = _value(l10n, false);
    final after = _value(l10n, true);
    final values = [
      Text(l10n.recipeComparisonBefore(before)),
      Text(l10n.recipeComparisonAfter(after)),
    ];
    final relative = change?.relativeChange;
    final percent = relative == null
        ? null
        : '${relative < 0 ? '−' : '+'}${(relative.abs() * 100).toStringAsFixed(1)}%';
    final numbers = GramTreeColors.of(context)
        .numberStyle(Theme.of(context).textTheme.bodyMedium!);
    return ComponentCard(
      detail: ComponentDescriptorDetailEnum.detailed,
      conclusion: Text(title, style: Theme.of(context).textTheme.titleMedium),
      conclusionSemanticsText: title,
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (change == null) Text(l10n.recipeComparisonUnchanged),
          if (change != null) Text(_fieldLabel(l10n, change!.field)),
          DefaultTextStyle(
            style: numbers,
            child: sideBySide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: values[0]),
                      const SizedBox(width: 12),
                      Expanded(child: values[1]),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: values,
                  ),
          ),
          if (percent != null) Text(percent, style: numbers),
          SourceMark(
            sourceType: 'author_filled',
            componentId:
                'ingredient-diff-${row?.before?.id ?? row?.after?.id ?? 'snapshot'}-${change?.field ?? 'unchanged'}',
            value: after,
            originalValue: before,
            basisText: basis,
            required: true,
            feedbackEnabled: false,
            neutral: true,
            showWhenAuthorFilled: true,
            labelOverride: l10n.whyTitle,
            onAction: null,
          ),
        ],
      ),
      basisText: basis,
      detailedExtra: row == null
          ? null
          : Material(
              color: GramTreeColors.of(context).card,
              child: ExpansionTile(
                title: Text(l10n.recipeComparisonIngredientDetails),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${l10n.recipeComparisonBefore(_ingredientDetails(l10n, row!.before))}\n${l10n.recipeComparisonAfter(_ingredientDetails(l10n, row!.after))}',
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _value(AppLocalizations l10n, bool after) {
    final ingredient = after ? row?.after : row?.before;
    if (change == null ||
        change!.kind == ComparisonChangeKindEnum.added ||
        change!.kind == ComparisonChangeKindEnum.removed) {
      return ingredient == null
          ? l10n.recipeComparisonNone
          : '${ingredient.displayName} ${_render(l10n, ingredient.baseQuantity)} ${ingredient.baseUnit?.value ?? ingredient.unit}';
    }
    final value = after ? change!.after : change!.before;
    return '${_render(l10n, value)}${change!.unit == null ? '' : ' ${change!.unit}'}';
  }
}

String _ingredientDetails(AppLocalizations l10n, RecipeIngredient? value) =>
    value == null
    ? l10n.recipeComparisonNone
    : [
        '${value.displayName} ${_render(l10n, value.baseQuantity)} ${value.baseUnit?.value ?? value.unit}',
        for (final entry in {
          l10n.recipeComparisonPreparation: value.preparation,
          l10n.recipeIngredientGroup: value.group,
          l10n.recipeComparisonOptional: value.optional == true,
          l10n.recipeFunctionalToggle: value.functional == true,
          l10n.recipeScalingMode: value.scalingMode?.value ?? 'proportional',
          l10n.recipeReplacement: value.replacement,
        }.entries)
          l10n.recipeComparisonDetailField(
            entry.key,
            _render(l10n, entry.value),
          ),
      ].join('；');

String _render(AppLocalizations l10n, Object? value) => switch (value) {
  null => l10n.recipeComparisonNone,
  bool b => b ? l10n.recipeComparisonYes : l10n.recipeComparisonNo,
  num n => n == n.roundToDouble() ? n.toInt().toString() : n.toString(),
  Map() || List() => jsonEncode(value),
  _ => value.toString(),
};

String _kindLabel(AppLocalizations l10n, ComparisonChangeKindEnum kind) =>
    switch (kind) {
      ComparisonChangeKindEnum.added => l10n.recipeComparisonAdded,
      ComparisonChangeKindEnum.removed => l10n.recipeComparisonRemoved,
      ComparisonChangeKindEnum.replacement => l10n.recipeComparisonReplacement,
      ComparisonChangeKindEnum.quantity => l10n.recipeComparisonQuantity,
      ComparisonChangeKindEnum.unit => l10n.recipeComparisonUnit,
      ComparisonChangeKindEnum.field => l10n.recipeComparisonField,
      ComparisonChangeKindEnum.text => l10n.recipeComparisonText,
    };

String _fieldLabel(AppLocalizations l10n, String field) =>
    {
      'base_quantity': l10n.recipeComparisonBaseQuantity,
      'base_unit': l10n.recipeComparisonBaseUnit,
      'ingredient_id': l10n.recipeIngredients,
      'display_name': l10n.recipeComparisonDisplayName,
      'preparation': l10n.recipeComparisonPreparation,
      'group': l10n.recipeIngredientGroup,
      'optional': l10n.recipeComparisonOptional,
      'scaling_mode': l10n.recipeScalingMode,
      'replacement': l10n.recipeReplacement,
      'functional': l10n.recipeFunctionalToggle,
      'flavor_contribution': l10n.recipeComparisonFlavor,
      'description': l10n.recipeDescription,
      'difficulty': l10n.recipeDifficulty,
      'dish_type': l10n.recipeDishType,
      'tags': l10n.recipeComparisonTags,
      'base_mold': l10n.recipeBaseMold,
      'cuisine': l10n.recipeCuisine,
      'design_rationale': l10n.recipeDesignRationale,
      'total_time_seconds': l10n.recipeComparisonTotalTime,
      'active_time_seconds': l10n.recipeComparisonActiveTime,
    }[field] ??
    field;
