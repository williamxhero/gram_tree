import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/recipes/serving_conversion.dart';

Future<List<dynamic>> _cases() async => jsonDecode(
  await rootBundle.loadString('assets/serving_conversion_cases.json'),
) as List<dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'App conversion kernel matches the shared input-to-output table',
    () async {
      for (final raw in await _cases()) {
        final item = Map<String, dynamic>.from(raw as Map);
        final input = Map<String, dynamic>.from(item['input'] as Map);
        final expected = Map<String, dynamic>.from(item['expected'] as Map);
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
        expect(result.toJson(), expected, reason: item['name'] as String);
      }
    },
  );

  test('conversion bounds produce a structured client error', () {
    expect(
      () => convertServings(
        originalServings: 2,
        targetServings: 21,
        ingredients: const [],
        steps: const [],
      ),
      throwsA(
        isA<ServingConversionError>().having(
          (error) => error.code,
          'code',
          'invalid_servings',
        ),
      ),
    );
  });
}
