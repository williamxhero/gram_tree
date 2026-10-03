import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:gram_tree/recipes/mold_conversion.dart';
import 'package:gram_tree/recipes/serving_conversion.dart';

import 'package:gram_tree/recipes/decimal_rounding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('roundHalfUp follows decimal half-up boundaries', () {
    expect(roundHalfUp(1.005), 1.01);
    expect(roundHalfUp(2.675), 2.68);
    expect(roundHalfUp(-1.005), -1.01);
    expect(roundHalfUp(2.5, fractionDigits: 0), 3);
  });

  test('conversion kernels match shared half-up boundary fixture', () async {
    final raw = jsonDecode(
      await rootBundle.loadString('assets/rounding_boundary_cases.json'),
    ) as List;
    for (final value in raw) {
      final caseData = Map<String, dynamic>.from(value as Map);
      final input = Map<String, dynamic>.from(caseData['input'] as Map);
      final expected = Map<String, dynamic>.from(caseData['expected'] as Map);
      if (caseData['kind'] == 'serving') {
        final result = convertServings(
          originalServings: input['original_servings'] as int,
          targetServings: input['target_servings'] as int,
          ingredients: [
            for (final rawIngredient in input['ingredients'] as List)
              ServingIngredientInput.fromJson(
                Map<String, dynamic>.from(rawIngredient as Map),
              ),
          ],
          steps: [
            for (final rawStep in input['steps'] as List)
              ServingStepInput.fromJson(
                Map<String, dynamic>.from(rawStep as Map),
              ),
          ],
        );
        expect(
          result.ingredients.single.displayQuantity,
          expected['display_quantity'],
          reason: caseData['name'] as String,
        );
      } else {
        final result = convertMold(
          originalMold: MoldSpec.fromJson(
            Map<String, dynamic>.from(input['original_mold'] as Map),
          ),
          targetMold: MoldSpec.fromJson(
            Map<String, dynamic>.from(input['target_mold'] as Map),
          ),
          ingredients: [
            for (final rawIngredient in input['ingredients'] as List)
              () {
                final ingredient = Map<String, dynamic>.from(
                  rawIngredient as Map,
                );
                return MoldIngredientInput(
                  id: ingredient['id'] as String,
                  displayName: ingredient['display_name'] as String,
                  quantity: (ingredient['quantity'] as num).toDouble(),
                  unit: ingredient['unit'] as String,
                  scalingMode:
                      ingredient['scaling_mode'] as String? ?? 'proportional',
                );
              }(),
          ],
          steps: [
            for (final rawStep in input['steps'] as List)
              () {
                final step = Map<String, dynamic>.from(rawStep as Map);
                return MoldStepInput(
                  id: step['id'] as String,
                  instruction: step['instruction'] as String,
                  durationSeconds: (step['duration_seconds'] as num? ?? 0)
                      .toInt(),
                  temperatureCelsius: (step['temperature_celsius'] as num?)
                      ?.toDouble(),
                  heat: step['heat'] as String?,
                  action: step['action'] as String?,
                  cookware: step['cookware'] as String?,
                );
              }(),
          ],
        );
        expect(result.areaRatio, expected['area_ratio']);
        expect(
          result.ingredients.single.displayQuantity,
          expected['display_quantity'],
          reason: caseData['name'] as String,
        );
      }
    }
  });
}
