//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'nutrition.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Nutrition {
  /// Returns a new [Nutrition] instance.
  Nutrition({

     this.carbohydrateG,

     this.energyKcal,

     this.fatG,

     this.proteinG,

     this.sodiumMg,
  });

          // minimum: 0.0
  @JsonKey(
    
    name: r'carbohydrate_g',
    required: false,
    includeIfNull: false,
  )


  final num? carbohydrateG;



          // minimum: 0.0
  @JsonKey(
    
    name: r'energy_kcal',
    required: false,
    includeIfNull: false,
  )


  final num? energyKcal;



          // minimum: 0.0
  @JsonKey(
    
    name: r'fat_g',
    required: false,
    includeIfNull: false,
  )


  final num? fatG;



          // minimum: 0.0
  @JsonKey(
    
    name: r'protein_g',
    required: false,
    includeIfNull: false,
  )


  final num? proteinG;



          // minimum: 0.0
  @JsonKey(
    
    name: r'sodium_mg',
    required: false,
    includeIfNull: false,
  )


  final num? sodiumMg;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Nutrition &&
      other.carbohydrateG == carbohydrateG &&
      other.energyKcal == energyKcal &&
      other.fatG == fatG &&
      other.proteinG == proteinG &&
      other.sodiumMg == sodiumMg;

    @override
    int get hashCode =>
        (carbohydrateG == null ? 0 : carbohydrateG.hashCode) +
        (energyKcal == null ? 0 : energyKcal.hashCode) +
        (fatG == null ? 0 : fatG.hashCode) +
        (proteinG == null ? 0 : proteinG.hashCode) +
        (sodiumMg == null ? 0 : sodiumMg.hashCode);

  factory Nutrition.fromJson(Map<String, dynamic> json) => _$NutritionFromJson(json);

  Map<String, dynamic> toJson() => _$NutritionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

