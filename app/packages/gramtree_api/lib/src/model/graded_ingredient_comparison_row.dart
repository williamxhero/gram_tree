//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_ingredient.dart';
import 'package:gramtree_api/src/model/graded_comparison_change.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'graded_ingredient_comparison_row.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GradedIngredientComparisonRow {
  /// Returns a new [GradedIngredientComparisonRow] instance.
  GradedIngredientComparisonRow({
    this.after,

    this.before,

    this.changes,

    required this.pairing,
  });

  @JsonKey(name: r'after', required: false, includeIfNull: false)
  final RecipeIngredient? after;

  @JsonKey(name: r'before', required: false, includeIfNull: false)
  final RecipeIngredient? before;

  @JsonKey(name: r'changes', required: false, includeIfNull: false)
  final List<GradedComparisonChange>? changes;

  @JsonKey(name: r'pairing', required: true, includeIfNull: false)
  final GradedIngredientComparisonRowPairingEnum pairing;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradedIngredientComparisonRow &&
          other.after == after &&
          other.before == before &&
          other.changes == changes &&
          other.pairing == pairing;

  @override
  int get hashCode =>
      (after == null ? 0 : after.hashCode) +
      (before == null ? 0 : before.hashCode) +
      changes.hashCode +
      pairing.hashCode;

  factory GradedIngredientComparisonRow.fromJson(Map<String, dynamic> json) =>
      _$GradedIngredientComparisonRowFromJson(json);

  Map<String, dynamic> toJson() => _$GradedIngredientComparisonRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum GradedIngredientComparisonRowPairingEnum {
  @JsonValue(r'stable_id')
  stableId(r'stable_id'),
  @JsonValue(r'identity_group')
  identityGroup(r'identity_group'),
  @JsonValue(r'group_replacement')
  groupReplacement(r'group_replacement'),
  @JsonValue(r'unpaired')
  unpaired(r'unpaired');

  const GradedIngredientComparisonRowPairingEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
