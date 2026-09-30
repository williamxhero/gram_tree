//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'nutrition_estimate.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NutritionEstimate {
  /// Returns a new [NutritionEstimate] instance.
  NutritionEstimate({
    required this.carbohydrateG,

    required this.energyKcal,

    this.estimated = true,

    required this.fatG,

    this.incomplete = false,

    required this.proteinG,

    required this.sodiumMg,
  });

  @JsonKey(name: r'carbohydrate_g', required: true, includeIfNull: false)
  final num carbohydrateG;

  @JsonKey(name: r'energy_kcal', required: true, includeIfNull: false)
  final num energyKcal;

  @JsonKey(
    defaultValue: true,
    name: r'estimated',
    required: false,
    includeIfNull: false,
  )
  final bool? estimated;

  @JsonKey(name: r'fat_g', required: true, includeIfNull: false)
  final num fatG;

  @JsonKey(
    defaultValue: false,
    name: r'incomplete',
    required: false,
    includeIfNull: false,
  )
  final bool? incomplete;

  @JsonKey(name: r'protein_g', required: true, includeIfNull: false)
  final num proteinG;

  @JsonKey(name: r'sodium_mg', required: true, includeIfNull: false)
  final num sodiumMg;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionEstimate &&
          other.carbohydrateG == carbohydrateG &&
          other.energyKcal == energyKcal &&
          other.estimated == estimated &&
          other.fatG == fatG &&
          other.incomplete == incomplete &&
          other.proteinG == proteinG &&
          other.sodiumMg == sodiumMg;

  @override
  int get hashCode =>
      carbohydrateG.hashCode +
      energyKcal.hashCode +
      estimated.hashCode +
      fatG.hashCode +
      incomplete.hashCode +
      proteinG.hashCode +
      sodiumMg.hashCode;

  factory NutritionEstimate.fromJson(Map<String, dynamic> json) =>
      _$NutritionEstimateFromJson(json);

  Map<String, dynamic> toJson() => _$NutritionEstimateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
