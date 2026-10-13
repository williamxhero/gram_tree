//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_safety_result.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_safety_check_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeSafetyCheckOut {
  /// Returns a new [RecipeSafetyCheckOut] instance.
  RecipeSafetyCheckOut({required this.result});

  @JsonKey(name: r'result', required: true, includeIfNull: false)
  final RecipeSafetyResult result;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeSafetyCheckOut && other.result == result;

  @override
  int get hashCode => result.hashCode;

  factory RecipeSafetyCheckOut.fromJson(Map<String, dynamic> json) =>
      _$RecipeSafetyCheckOutFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeSafetyCheckOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
