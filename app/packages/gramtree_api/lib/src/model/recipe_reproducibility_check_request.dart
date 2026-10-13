//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_snapshot.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_reproducibility_check_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeReproducibilityCheckRequest {
  /// Returns a new [RecipeReproducibilityCheckRequest] instance.
  RecipeReproducibilityCheckRequest({required this.snapshot});

  @JsonKey(name: r'snapshot', required: true, includeIfNull: false)
  final RecipeSnapshot snapshot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeReproducibilityCheckRequest && other.snapshot == snapshot;

  @override
  int get hashCode => snapshot.hashCode;

  factory RecipeReproducibilityCheckRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$RecipeReproducibilityCheckRequestFromJson(json);

  Map<String, dynamic> toJson() =>
      _$RecipeReproducibilityCheckRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
