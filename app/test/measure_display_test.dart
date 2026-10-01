import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:gram_tree/recipes/measure_display.dart';

Future<List<dynamic>> _cases() async => jsonDecode(
  await rootBundle.loadString('assets/measure_display_cases.json'),
) as List<dynamic>;

PersonalMeasureOut _measure(Map<String, dynamic> value) => PersonalMeasureOut(
  capacityMl: value['capacity_ml'] as num,
  createdAt: '2026-10-02T00:00:00Z',
  id: '00000000-0000-4000-8000-000000000001',
  kind: switch (value['kind'] as String) {
    'bowl' => PersonalMeasureOutKindEnum.bowl,
    'cup' => PersonalMeasureOutKindEnum.cup,
    _ => PersonalMeasureOutKindEnum.spoon,
  },
  name: value['name'] as String,
  updatedAt: '2026-10-02T00:00:00Z',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('App display kernel matches the shared input-to-output table', () async {
    for (final raw in await _cases()) {
      final item = Map<String, dynamic>.from(raw as Map);
      final input = Map<String, dynamic>.from(item['input'] as Map);
      final rawMeasure = input['measure'];
      final mode = switch (input['mode'] as String) {
        'standard' => MeasureDisplayMode.standard,
        'home' => MeasureDisplayMode.home,
        _ => MeasureDisplayMode.base,
      };
      final result = displayAmount(
        DisplayMeasureInput(
          baseQuantity: (input['base_quantity'] as num).toDouble(),
          baseUnit: input['base_unit'] as String,
          density: (input['density'] as num?)?.toDouble(),
          mode: mode,
          measure: rawMeasure is Map
              ? _measure(Map<String, dynamic>.from(rawMeasure))
              : null,
        ),
      );
      expect(result.toJson(), Map<String, dynamic>.from(item['expected'] as Map), reason: item['name'] as String);
    }
  });

  test('display conversion never changes the source quantity', () {
    const input = DisplayMeasureInput(
      baseQuantity: 6,
      baseUnit: 'g',
      density: 0.8,
      mode: MeasureDisplayMode.home,
    );
    final measure = PersonalMeasureOut(
      capacityMl: 15,
      createdAt: '2026-10-02T00:00:00Z',
      id: '00000000-0000-4000-8000-000000000001',
      kind: PersonalMeasureOutKindEnum.spoon,
      name: '白瓷勺',
      updatedAt: '2026-10-02T00:00:00Z',
    );
    displayAmount(DisplayMeasureInput(
      baseQuantity: input.baseQuantity,
      baseUnit: input.baseUnit,
      density: input.density,
      mode: input.mode,
      measure: measure,
    ));
    expect(input.baseQuantity, 6);
  });
}
