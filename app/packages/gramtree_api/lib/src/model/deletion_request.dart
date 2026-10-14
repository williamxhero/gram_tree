//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'deletion_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeletionRequest {
  /// Returns a new [DeletionRequest] instance.
  DeletionRequest({this.publicRecipeAction});

  @JsonKey(name: r'public_recipe_action', required: false, includeIfNull: false)
  final DeletionRequestPublicRecipeActionEnum? publicRecipeAction;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeletionRequest &&
          other.publicRecipeAction == publicRecipeAction;

  @override
  int get hashCode =>
      (publicRecipeAction == null ? 0 : publicRecipeAction.hashCode);

  factory DeletionRequest.fromJson(Map<String, dynamic> json) =>
      _$DeletionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DeletionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum DeletionRequestPublicRecipeActionEnum {
  @JsonValue(r'keep_anonymous')
  keepAnonymous(r'keep_anonymous'),
  @JsonValue(r'withdraw')
  withdraw(r'withdraw');

  const DeletionRequestPublicRecipeActionEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
