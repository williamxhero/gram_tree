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
    this.adjustmentPercent,

    this.baseVersionId,

    this.generationRequestId,

    this.improvementDraftId,

    this.recipeId,

    this.requestId,

    this.retryFailed = false,

    required this.text,
  });

  @JsonKey(name: r'adjustment_percent', required: false, includeIfNull: false)
  final ModificationInputAdjustmentPercentEnum? adjustmentPercent;

  @JsonKey(name: r'base_version_id', required: false, includeIfNull: false)
  final String? baseVersionId;

  @JsonKey(
    name: r'generation_request_id',
    required: false,
    includeIfNull: false,
  )
  final String? generationRequestId;

  @JsonKey(name: r'improvement_draft_id', required: false, includeIfNull: false)
  final String? improvementDraftId;

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
          other.adjustmentPercent == adjustmentPercent &&
          other.baseVersionId == baseVersionId &&
          other.generationRequestId == generationRequestId &&
          other.improvementDraftId == improvementDraftId &&
          other.recipeId == recipeId &&
          other.requestId == requestId &&
          other.retryFailed == retryFailed &&
          other.text == text;

  @override
  int get hashCode =>
      (adjustmentPercent == null ? 0 : adjustmentPercent.hashCode) +
      (baseVersionId == null ? 0 : baseVersionId.hashCode) +
      (generationRequestId == null ? 0 : generationRequestId.hashCode) +
      (improvementDraftId == null ? 0 : improvementDraftId.hashCode) +
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

enum ModificationInputAdjustmentPercentEnum {
  @JsonValue(20)
  number20('20'),
  @JsonValue(25)
  number25('25'),
  @JsonValue(30)
  number30('30');

  const ModificationInputAdjustmentPercentEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
