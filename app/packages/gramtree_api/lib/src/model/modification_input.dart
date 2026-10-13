//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'modification_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ModificationInput {
  /// Returns a new [ModificationInput] instance.
  ModificationInput({
    this.baseVersionId,

    this.generationRequestId,

    this.recipeId,

    this.requestId,

    this.retryFailed = false,

    required this.text,
  });

  @JsonKey(name: r'base_version_id', required: false, includeIfNull: false)
  final String? baseVersionId;

  @JsonKey(
    name: r'generation_request_id',
    required: false,
    includeIfNull: false,
  )
  final String? generationRequestId;

  @JsonKey(name: r'recipe_id', required: false, includeIfNull: false)
  final String? recipeId;

  @JsonKey(name: r'request_id', required: false, includeIfNull: false)
  final String? requestId;

  @JsonKey(
    defaultValue: false,
    name: r'retry_failed',
    required: false,
    includeIfNull: false,
  )
  final bool? retryFailed;

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModificationInput &&
          other.baseVersionId == baseVersionId &&
          other.generationRequestId == generationRequestId &&
          other.recipeId == recipeId &&
          other.requestId == requestId &&
          other.retryFailed == retryFailed &&
          other.text == text;

  @override
  int get hashCode =>
      (baseVersionId == null ? 0 : baseVersionId.hashCode) +
      (generationRequestId == null ? 0 : generationRequestId.hashCode) +
      (recipeId == null ? 0 : recipeId.hashCode) +
      (requestId == null ? 0 : requestId.hashCode) +
      retryFailed.hashCode +
      text.hashCode;

  factory ModificationInput.fromJson(Map<String, dynamic> json) =>
      _$ModificationInputFromJson(json);

  Map<String, dynamic> toJson() => _$ModificationInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
