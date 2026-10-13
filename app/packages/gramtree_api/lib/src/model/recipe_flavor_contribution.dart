//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_flavor_contribution.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeFlavorContribution {
  /// Returns a new [RecipeFlavorContribution] instance.
  RecipeFlavorContribution({
    this.numbing,

    this.oily,

    this.salty,

    this.sour,

    this.spicy,

    this.sweet,

    this.umami,
  });

  /// 麻
  // minimum: 0
  // maximum: 3
  @JsonKey(name: r'numbing', required: false, includeIfNull: false)
  final int? numbing;

  /// 油
  // minimum: 0
  // maximum: 3
  @JsonKey(name: r'oily', required: false, includeIfNull: false)
  final int? oily;

  /// 咸
  // minimum: 0
  // maximum: 3
  @JsonKey(name: r'salty', required: false, includeIfNull: false)
  final int? salty;

  /// 酸
  // minimum: 0
  // maximum: 3
  @JsonKey(name: r'sour', required: false, includeIfNull: false)
  final int? sour;

  /// 辣
  // minimum: 0
  // maximum: 3
  @JsonKey(name: r'spicy', required: false, includeIfNull: false)
  final int? spicy;

  /// 甜
  // minimum: 0
  // maximum: 3
  @JsonKey(name: r'sweet', required: false, includeIfNull: false)
  final int? sweet;

  /// 鲜
  // minimum: 0
  // maximum: 3
  @JsonKey(name: r'umami', required: false, includeIfNull: false)
  final int? umami;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeFlavorContribution &&
          other.numbing == numbing &&
          other.oily == oily &&
          other.salty == salty &&
          other.sour == sour &&
          other.spicy == spicy &&
          other.sweet == sweet &&
          other.umami == umami;

  @override
  int get hashCode =>
      (numbing == null ? 0 : numbing.hashCode) +
      (oily == null ? 0 : oily.hashCode) +
      (salty == null ? 0 : salty.hashCode) +
      (sour == null ? 0 : sour.hashCode) +
      (spicy == null ? 0 : spicy.hashCode) +
      (sweet == null ? 0 : sweet.hashCode) +
      (umami == null ? 0 : umami.hashCode);

  factory RecipeFlavorContribution.fromJson(Map<String, dynamic> json) =>
      _$RecipeFlavorContributionFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeFlavorContributionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
