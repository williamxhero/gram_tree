//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/mold_spec.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_mold_conversion_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeMoldConversionRequest {
  /// Returns a new [RecipeMoldConversionRequest] instance.
  RecipeMoldConversionRequest({required this.targetMold});

  @JsonKey(name: r'target_mold', required: true, includeIfNull: false)
  final MoldSpec targetMold;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeMoldConversionRequest && other.targetMold == targetMold;

  @override
  int get hashCode => targetMold.hashCode;

  factory RecipeMoldConversionRequest.fromJson(Map<String, dynamic> json) =>
      _$RecipeMoldConversionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeMoldConversionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
