import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:gram_tree/recipes/mold_conversion.dart';

Future<List<dynamic>> _cases() async =>
    jsonDecode(await rootBundle.loadString('assets/mold_conversion_cases.json'))
        as List<dynamic>;

MoldSpec _mold(Map<String, dynamic> json) => MoldSpec(
  shape: switch (json['shape'] as String) {
    'round' => MoldSpecShapeEnum.round,
    'square' => MoldSpecShapeEnum.square,
    'rectangular' => MoldSpecShapeEnum.rectangular,
    _ => MoldSpecShapeEnum.custom,
  },
  unit: switch (json['unit'] as String? ?? 'cm') {
    'in' => MoldSpecUnitEnum.in_,
    'inch' => MoldSpecUnitEnum.inch,
    _ => MoldSpecUnitEnum.cm,
  },
  diameter: (json['diameter'] as num?)?.toDouble(),
  side: (json['side'] as num?)?.toDouble(),
  width: (json['width'] as num?)?.toDouble(),
  length: (json['length'] as num?)?.toDouble(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('App mold conversion kernel matches shared table', () async {
    for (final raw in await _cases()) {
      final item = Map<String, dynamic>.from(raw as Map);
      final input = Map<String, dynamic>.from(item['input'] as Map);
      final expected = Map<String, dynamic>.from(item['expected'] as Map);
      final result = convertMold(
        originalMold: _mold(
          Map<String, dynamic>.from(input['original_mold'] as Map),
        ),
        targetMold: _mold(
          Map<String, dynamic>.from(input['target_mold'] as Map),
        ),
        ingredients: [
          for (final rawIngredient in input['ingredients'] as List)
            MoldIngredientInput(
              id: rawIngredient['id'] as String,
              displayName: rawIngredient['display_name'] as String,
              quantity: (rawIngredient['quantity'] as num).toDouble(),
              unit: rawIngredient['unit'] as String,
              scalingMode:
                  rawIngredient['scaling_mode'] as String? ?? 'proportional',
            ),
        ],
        steps: [
          for (final rawStep in input['steps'] as List)
            MoldStepInput(
              id: rawStep['id'] as String,
              instruction: rawStep['instruction'] as String,
              durationSeconds: (rawStep['duration_seconds'] as num? ?? 0)
                  .toInt(),
              temperatureCelsius: (rawStep['temperature_celsius'] as num?)
                  ?.toDouble(),
              heat: rawStep['heat'] as String?,
            ),
        ],
      );
      expect(
        result.areaRatio,
        expected['area_ratio'],
        reason: item['name'] as String,
      );
      final expectedIngredients = (expected['ingredients'] as List)
          .map((value) => Map<String, dynamic>.from(value as Map))
          .toList();
      expect(
        [
          for (final ingredient in result.ingredients)
            {
              'id': ingredient.id,
              'original_quantity': ingredient.originalQuantity,
              'display_quantity': ingredient.displayQuantity,
              'unit': ingredient.unit,
              'rule': ingredient.rule,
            },
        ],
        expectedIngredients,
        reason: item['name'] as String,
      );
      final expectedStep = expected['step'];
      if (expectedStep == null) {
        expect(result.steps, isEmpty);
      } else {
        final step = result.steps.single;
        final expectedStepMap = Map<String, dynamic>.from(expectedStep as Map);
        expect(step.durationSeconds, expectedStepMap['duration_seconds']);
        expect(step.temperatureCelsius, expectedStepMap['temperature_celsius']);
        expect(step.timeAdvisory != null, expectedStepMap['has_time_advisory']);
        expect(step.donenessWarning, expectedStepMap['doneness_warning']);
      }
    }
  });
}
