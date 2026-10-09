import 'package:gramtree_api/gramtree_api.dart'
    show MoldSpec, RecipeIngredientDisplayOut;

import 'decimal_rounding.dart';
import 'measure_display.dart';
import 'mold_conversion.dart';
import 'serving_conversion.dart';

/// Actual render results, not inputs for rerunning today's conversion kernel.
/// Source marks, warnings and step advisories remain frozen with the quantities.
class RecipeSnapshotRender {
  const RecipeSnapshotRender({
    required this.serving,
    required this.mold,
    required this.amounts,
    required this.contract,
    this.moldError,
  });
  final ServingConversionResult serving;
  final MoldConversionResult? mold;
  final String? moldError;
  final Map<String, DisplayedAmount?> amounts;
  final RecipeIngredientDisplayOut? contract;

  Map<String, dynamic> toJson() => {
    'serving': serving.toJson(),
    'mold': mold == null
        ? null
        : {
            'original_mold': mold!.originalMold.toJson(),
            'target_mold': mold!.targetMold.toJson(),
            'area_ratio': mold!.areaRatio,
            'scale': mold!.scale,
            'ingredients': [
              for (final i in mold!.ingredients)
                {
                  'id': i.id,
                  'display_name': i.displayName,
                  'original_quantity': i.originalQuantity,
                  'display_quantity': i.displayQuantity,
                  'unit': i.unit,
                  'rule': i.rule,
                  'deviation_ratio': i.deviationRatio,
                  'deviation_warning': i.deviationWarning,
                },
            ],
            'steps': [
              for (final s in mold!.steps)
                {
                  'id': s.id,
                  'instruction': s.instruction,
                  'duration_seconds': s.durationSeconds,
                  'temperature_celsius': s.temperatureCelsius,
                  'heat': s.heat,
                  'time_advisory': s.timeAdvisory,
                  'doneness_warning': s.donenessWarning,
                  'doneness_warning_text': s.donenessWarningText,
                },
            ],
            'warnings': [
              for (final w in mold!.warnings)
                {
                  'code': w.code,
                  'ingredient_id': w.ingredientId,
                  'message': w.message,
                },
            ],
          },
    'mold_error': moldError,
    'amounts': {
      for (final e in amounts.entries)
        e.key: e.value == null
            ? null
            : {
                ...e.value!.toJson(),
                'base_quantity': e.value!.baseQuantity,
                'base_unit': e.value!.baseUnit,
              },
    },
    'contract': contract?.toJson(),
  };

  static RecipeSnapshotRender? fromJson(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    try {
      final s = raw['serving'] as Map;
      final m = raw['mold'] as Map?;
      return RecipeSnapshotRender(
        serving: ServingConversionResult(
          originalServings: s['original_servings'] as int,
          targetServings: s['target_servings'] as int,
          minServings: s['min_servings'] as int,
          maxServings: s['max_servings'] as int,
          totalTimeSeconds: s['total_time_seconds'] as int,
          activeTimeSeconds: s['active_time_seconds'] as int,
          ingredients: [
            for (final i in s['ingredients'] as List)
              ConvertedServingIngredient(
                id: i['id'],
                displayName: i['display_name'],
                originalQuantity: (i['original_quantity'] as num).toDouble(),
                displayQuantity: (i['display_quantity'] as num).toDouble(),
                unit: i['unit'],
                rule: i['rule'],
                deviationRatio: (i['deviation_ratio'] as num?)?.toDouble(),
                deviationWarning: i['deviation_warning'],
              ),
          ],
          steps: [
            for (final i in s['steps'] as List)
              ConvertedServingStep(
                id: i['id'],
                instruction: i['instruction'],
                durationSeconds: i['duration_seconds'],
                temperatureCelsius: (i['temperature_celsius'] as num?)
                    ?.toDouble(),
                heat: i['heat'],
                batchWarning: i['batch_warning'],
                batchWarningText: i['batch_warning_text'],
              ),
          ],
          warnings: [
            for (final w in s['warnings'] as List)
              ServingConversionWarning(
                code: w['code'],
                ingredientId: w['ingredient_id'],
                message: w['message'],
              ),
          ],
        ),
        mold: m == null
            ? null
            : MoldConversionResult(
                originalMold: MoldSpec.fromJson(m['original_mold']),
                targetMold: MoldSpec.fromJson(m['target_mold']),
                areaRatio: (m['area_ratio'] as num).toDouble(),
                scale: (m['scale'] as num).toDouble(),
                // Offline render never calls scaleQuantity: all amounts are captured.
                decimalScale: DecimalValue.fromNum(m['scale'] as num),
                ingredients: [
                  for (final i in m['ingredients'] as List)
                    ConvertedMoldIngredient(
                      id: i['id'],
                      displayName: i['display_name'],
                      originalQuantity: (i['original_quantity'] as num)
                          .toDouble(),
                      displayQuantity: (i['display_quantity'] as num)
                          .toDouble(),
                      unit: i['unit'],
                      rule: i['rule'],
                      deviationRatio: (i['deviation_ratio'] as num?)
                          ?.toDouble(),
                      deviationWarning: i['deviation_warning'],
                    ),
                ],
                steps: [
                  for (final i in m['steps'] as List)
                    ConvertedMoldStep(
                      id: i['id'],
                      instruction: i['instruction'],
                      durationSeconds: i['duration_seconds'],
                      temperatureCelsius: (i['temperature_celsius'] as num?)
                          ?.toDouble(),
                      heat: i['heat'],
                      timeAdvisory: i['time_advisory'],
                      donenessWarning: i['doneness_warning'],
                      donenessWarningText: i['doneness_warning_text'],
                    ),
                ],
                warnings: [
                  for (final w in m['warnings'] as List)
                    MoldConversionWarning(
                      code: w['code'],
                      ingredientId: w['ingredient_id'],
                      message: w['message'],
                    ),
                ],
              ),
        moldError: raw['mold_error'] as String?,
        amounts: {
          for (final e in (raw['amounts'] as Map).entries)
            e.key as String: e.value == null
                ? null
                : DisplayedAmount(
                    text: e.value['text'],
                    displayQuantity: (e.value['display_quantity'] as num)
                        .toDouble(),
                    displayUnit: e.value['display_unit'],
                    grams: (e.value['grams'] as num?)?.toDouble(),
                    rule: e.value['rule'],
                    baseQuantity: (e.value['base_quantity'] as num?)
                        ?.toDouble(),
                    baseUnit: e.value['base_unit'],
                  ),
        },
        contract: raw['contract'] == null
            ? null
            : RecipeIngredientDisplayOut.fromJson(raw['contract']),
      );
    } catch (_) {
      return null;
    }
  }
}
