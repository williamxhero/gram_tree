import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:gram_tree/recipes/personalization.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = jsonDecode(
    await rootBundle.loadString('assets/personalization_cases.json'),
  ) as Map<String, dynamic>;

  for (final testCase in fixture['cases'] as List<dynamic>) {
    final data = Map<String, dynamic>.from(testCase as Map);
    test('shared personalization case: ${data['name']}', () {
      final ingredients = <RecipeIngredient>[
        for (final raw in data['ingredients'] as List<dynamic>)
          _ingredient(Map<String, dynamic>.from(raw as Map)),
      ];
      final result = personalizeIngredients(
        ingredients: ingredients,
        originalServings: data['original_servings'] as int,
        targetServings: data['target_servings'] as int,
        flavors: {
          for (final entry in (data['flavors'] as Map).entries)
            entry.key as String: (entry.value as num).toDouble(),
        },
      );

      for (final raw in data['ingredients'] as List<dynamic>) {
        final item = Map<String, dynamic>.from(raw as Map);
        expect(
          result.quantities[item['id']],
          closeTo((item['expected'] as num).toDouble(), 0.001),
          reason: item['id'] as String,
        );
        if (item['functional'] == true) {
          expect(result.rules[item['id']], 'functional_protected');
        }
      }
      expect(ingredients.first.quantity, data['ingredients'][0]['quantity']);
    });
  }
}

RecipeIngredient _ingredient(Map<String, dynamic> value) => RecipeIngredient(
  id: value['id'] as String,
  displayName: value['display_name'] as String,
  quantity: value['quantity'] as num,
  unit: value['unit'] as String,
  scalingMode: RecipeIngredientScalingModeEnum.values.firstWhere(
    (mode) => mode.value == value['scaling_mode'],
  ),
  functional: value['functional'] as bool,
  flavorContribution: value['contribution'] == null
      ? null
      : RecipeFlavorContribution.fromJson(
          Map<String, dynamic>.from(value['contribution'] as Map),
        ),
);
