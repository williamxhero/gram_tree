import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../ui_protocol/source_mark.dart';
import 'recipe_flavor_panel.dart';
import 'recipe_source_badge.dart';

/// Both saved quantities and recipe-owned flavor/function evidence stay visible.
class ComparisonIngredientDetails extends StatelessWidget {
  const ComparisonIngredientDetails({super.key, required this.value});

  final RecipeIngredient? value;

  @override
  Widget build(BuildContext context) {
    final item = value;
    final l10n = AppLocalizations.of(context);
    if (item == null) return Text(l10n.recipeComparisonNone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(context, '条目 ID', item.id),
        _field(context, l10n.recipeComparisonDisplayName, item.displayName),
        _field(context, l10n.recipeStandardIngredient, item.ingredientId),
        _field(context, l10n.recipeQuantity, '${item.quantity} ${item.unit}'),
        _field(
          context,
          l10n.recipeBaseQuantity,
          '${comparisonValue(l10n, item.baseQuantity)} ${item.baseUnit?.value ?? item.unit}',
        ),
        _field(context, l10n.recipeComparisonPreparation, item.preparation),
        _field(context, l10n.recipeIngredientGroup, item.group),
        _field(context, l10n.recipeComparisonOptional, item.optional),
        _field(context, l10n.recipeScalingMode, item.scalingMode?.value),
        _field(context, l10n.recipeReplacement, item.replacement),
        _field(context, l10n.recipeFunctionalToggle, item.functional),
        _field(context, '味型原值', item.flavorContribution?.toJson()),
        RecipeFlavorSummary(
          id: item.id,
          contribution: item.flavorContribution,
          flavorSource: item.flavorSource,
          functional: item.functional == true,
          functionalSource: item.functionalSource,
        ),
        if (item.measureInputToken != null && item.quantitySource != null)
          SourceMark(
            sourceType: item.quantitySource!.source_.value,
            componentId: 'comparison-measure-${item.id}',
            value: '${item.quantity} ${item.unit}',
            originalValue: item.quantitySource!.original,
            basisText: recipeSourceBasis(item.quantitySource),
            neutral: true,
            valueChanged: false,
            showWhenAuthorFilled: true,
            required: false,
            feedbackEnabled: false,
            labelOverride: l10n.measureInputEvidence,
            onAction: null,
          )
        else
          _source(
            context,
            item.quantitySource,
            '${item.quantity} ${item.unit}',
            'comparison-ingredient-${item.id}-quantity',
            '用量来源',
          ),
        _source(
          context,
          item.preparationSource,
          item.preparation,
          'comparison-ingredient-${item.id}-preparation',
          '处理方式来源',
        ),
        _source(
          context,
          item.flavorSource,
          item.flavorContribution?.toJson(),
          'comparison-ingredient-${item.id}-flavor',
          '味型来源',
        ),
        _source(
          context,
          item.functionalSource,
          item.functional,
          'comparison-ingredient-${item.id}-functional',
          '功能性来源',
        ),
      ],
    );
  }
}

/// Original execution fields, not a client reconstruction of aligned steps.
class ComparisonStepDetails extends StatelessWidget {
  const ComparisonStepDetails({
    super.key,
    required this.value,
    this.ingredientNames = const {},
    this.stepNumbers = const {},
  });

  final RecipeStep? value;
  final Map<String, String> ingredientNames;
  final Map<String, int> stepNumbers;

  @override
  Widget build(BuildContext context) {
    final step = value;
    final l10n = AppLocalizations.of(context);
    if (step == null) return Text(l10n.recipeComparisonNone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(context, '步骤 ID', step.id),
        _field(context, '动作', step.action),
        _field(context, '说明', step.instruction),
        _field(
          context,
          l10n.recipeStepIngredientRefs,
          [
            for (final id in step.ingredientIds ?? <String>[])
              ingredientNames[id] ?? id,
          ].join('、'),
        ),
        _field(context, '引用食材 ID', step.ingredientIds),
        _field(context, '时长（秒）', step.durationSeconds),
        _field(context, '是否需要守着', step.unattended == true ? '可以走开' : '需要守着'),
        _field(context, l10n.recipeStepHeat, step.heat),
        _field(context, '温度（°C）', step.temperatureCelsius),
        _field(context, l10n.recipeStepCookware, step.cookware),
        _field(context, l10n.recipeStepDoneness, step.doneness),
        _field(
          context,
          l10n.recipeStepDepends,
          [
            for (final id in step.dependsOn ?? <String>[])
              stepNumbers[id] == null ? id : '第 ${stepNumbers[id]} 步',
          ].join('、'),
        ),
        _field(context, '前置依赖 ID', step.dependsOn),
        _field(context, l10n.recipeStepNotes, step.notes),
        _field(context, l10n.recipeStepWhy, step.why),
        Wrap(
          spacing: 8,
          children: [
            for (final field in <(String, Object?, ValueSource?)>[
              ('instruction', step.instruction, step.instructionSource),
              ('duration', step.durationSeconds, step.durationSource),
              ('heat', step.heat, step.heatSource),
              ('temperature', step.temperatureCelsius, step.temperatureSource),
              ('doneness', step.doneness, step.donenessSource),
            ])
              _source(
                context,
                field.$3,
                field.$2,
                'comparison-step-${step.id}-${field.$1}',
                '${field.$1} 来源',
              ),
          ],
        ),
      ],
    );
  }
}

Widget _source(
  BuildContext context,
  ValueSource? source,
  Object? value,
  String id,
  String label,
) {
  if (source == null) return const SizedBox.shrink();
  return SourceMark(
    key: ValueKey(id),
    sourceType: source.source_.value,
    componentId: id,
    value: comparisonValue(AppLocalizations.of(context), value),
    originalValue: source.original,
    basisText: recipeSourceBasis(source),
    required: false,
    neutral: true,
    valueChanged: false,
    showWhenAuthorFilled: true,
    feedbackEnabled: false,
    labelOverride: label,
    onAction: null,
  );
}

Widget _field(BuildContext context, String label, Object? value) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(
    '$label：${comparisonValue(AppLocalizations.of(context), value)}',
    style: GramTreeColors.of(context)
        .numberStyle(Theme.of(context).textTheme.bodyMedium!),
  ),
);

String comparisonValue(AppLocalizations l10n, Object? value) => switch (value) {
  null || '' => l10n.recipeComparisonNone,
  bool b => b ? l10n.recipeComparisonYes : l10n.recipeComparisonNo,
  num n => n == n.roundToDouble() ? n.toInt().toString() : n.toString(),
  Map() || List() => jsonEncode(value),
  _ => value.toString(),
};
