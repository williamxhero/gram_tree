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
    this.carbohydrateG,

    this.energyKcal,

    this.estimated = true,

    this.fatG,

    this.incomplete = false,

    this.proteinG,

    this.sodiumMg,
  });

  @JsonKey(name: r'carbohydrate_g', required: false, includeIfNull: false)
  final num? carbohydrateG;

  @JsonKey(name: r'energy_kcal', required: false, includeIfNull: false)
  final num? energyKcal;

  @JsonKey(
    defaultValue: true,
    name: r'estimated',
    required: false,
    includeIfNull: false,
  )
  final bool? estimated;

  @JsonKey(name: r'fat_g', required: false, includeIfNull: false)
  final num? fatG;

  @JsonKey(
    defaultValue: false,
    name: r'incomplete',
    required: false,
    includeIfNull: false,
  )
  final bool? incomplete;

  @JsonKey(name: r'protein_g', required: false, includeIfNull: false)
  final num? proteinG;

  @JsonKey(name: r'sodium_mg', required: false, includeIfNull: false)
  final num? sodiumMg;

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
      (carbohydrateG == null ? 0 : carbohydrateG.hashCode) +
      (energyKcal == null ? 0 : energyKcal.hashCode) +
      estimated.hashCode +
      (fatG == null ? 0 : fatG.hashCode) +
      incomplete.hashCode +
      (proteinG == null ? 0 : proteinG.hashCode) +
      (sodiumMg == null ? 0 : sodiumMg.hashCode);

  factory NutritionEstimate.fromJson(Map<String, dynamic> json) =>
      _$NutritionEstimateFromJson(json);

  Map<String, dynamic> toJson() => _$NutritionEstimateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
