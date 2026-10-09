//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/cooking_constraints.dart';
import 'package:gramtree_api/src/model/cooking_equipment.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cooking_constraints_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CookingConstraintsOut {
  /// Returns a new [CookingConstraintsOut] instance.
  CookingConstraintsOut({
    required this.constraints,

    required this.dishTypes,

    required this.equipmentVocabulary,

    required this.profileVersion,

    required this.servingsMax,

    required this.servingsMin,
  });

  @JsonKey(name: r'constraints', required: true, includeIfNull: false)
  final CookingConstraints constraints;

  @JsonKey(name: r'dish_types', required: true, includeIfNull: false)
  final List<CookingConstraintsOutDishTypesEnum> dishTypes;

  @JsonKey(name: r'equipment_vocabulary', required: true, includeIfNull: false)
  final List<CookingEquipment> equipmentVocabulary;

  @JsonKey(name: r'profile_version', required: true, includeIfNull: false)
  final int profileVersion;

  @JsonKey(name: r'servings_max', required: true, includeIfNull: false)
  final int servingsMax;

  @JsonKey(name: r'servings_min', required: true, includeIfNull: false)
  final int servingsMin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CookingConstraintsOut &&
          other.constraints == constraints &&
          other.dishTypes == dishTypes &&
          other.equipmentVocabulary == equipmentVocabulary &&
          other.profileVersion == profileVersion &&
          other.servingsMax == servingsMax &&
          other.servingsMin == servingsMin;

  @override
  int get hashCode =>
      constraints.hashCode +
      dishTypes.hashCode +
      equipmentVocabulary.hashCode +
      profileVersion.hashCode +
      servingsMax.hashCode +
      servingsMin.hashCode;

  factory CookingConstraintsOut.fromJson(Map<String, dynamic> json) =>
      _$CookingConstraintsOutFromJson(json);

  Map<String, dynamic> toJson() => _$CookingConstraintsOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CookingConstraintsOutDishTypesEnum {
  @JsonValue(r'meat')
  meat(r'meat'),
  @JsonValue(r'vegetable')
  vegetable(r'vegetable'),
  @JsonValue(r'soup')
  soup(r'soup'),
  @JsonValue(r'staple')
  staple(r'staple'),
  @JsonValue(r'other')
  other(r'other');

  const CookingConstraintsOutDishTypesEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
