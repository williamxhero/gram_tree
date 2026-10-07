//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_reproducibility_result.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_reproducibility_check_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeReproducibilityCheckOut {
  /// Returns a new [RecipeReproducibilityCheckOut] instance.
  RecipeReproducibilityCheckOut({required this.result});

  @JsonKey(name: r'result', required: true, includeIfNull: false)
  final RecipeReproducibilityResult result;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeReproducibilityCheckOut && other.result == result;

  @override
  int get hashCode => result.hashCode;

  factory RecipeReproducibilityCheckOut.fromJson(Map<String, dynamic> json) =>
      _$RecipeReproducibilityCheckOutFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeReproducibilityCheckOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
