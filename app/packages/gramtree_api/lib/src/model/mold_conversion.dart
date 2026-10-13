//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/mold_conversion_step.dart';
import 'package:gramtree_api/src/model/mold_spec.dart';
import 'package:gramtree_api/src/model/mold_conversion_ingredient.dart';
import 'package:gramtree_api/src/model/mold_conversion_warning.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mold_conversion.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MoldConversion {
  /// Returns a new [MoldConversion] instance.
  MoldConversion({
    required this.areaRatio,

    required this.ingredients,

    required this.originalMold,

    required this.steps,

    required this.targetMold,

    required this.warnings,
  });

  @JsonKey(name: r'area_ratio', required: true, includeIfNull: false)
  final num areaRatio;

  @JsonKey(name: r'ingredients', required: true, includeIfNull: false)
  final List<MoldConversionIngredient> ingredients;

  @JsonKey(name: r'original_mold', required: true, includeIfNull: false)
  final MoldSpec originalMold;

  @JsonKey(name: r'steps', required: true, includeIfNull: false)
  final List<MoldConversionStep> steps;

  @JsonKey(name: r'target_mold', required: true, includeIfNull: false)
  final MoldSpec targetMold;

  @JsonKey(name: r'warnings', required: true, includeIfNull: false)
  final List<MoldConversionWarning> warnings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoldConversion &&
          other.areaRatio == areaRatio &&
          other.ingredients == ingredients &&
          other.originalMold == originalMold &&
          other.steps == steps &&
          other.targetMold == targetMold &&
          other.warnings == warnings;

  @override
  int get hashCode =>
      areaRatio.hashCode +
      ingredients.hashCode +
      originalMold.hashCode +
      steps.hashCode +
      targetMold.hashCode +
      warnings.hashCode;

  factory MoldConversion.fromJson(Map<String, dynamic> json) =>
      _$MoldConversionFromJson(json);

  Map<String, dynamic> toJson() => _$MoldConversionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
