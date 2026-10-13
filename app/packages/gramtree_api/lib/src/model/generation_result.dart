//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/ai_status.dart';
import 'package:gramtree_api/src/model/generated_draft.dart';
import 'package:gramtree_api/src/model/recipe_safety_result.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generation_result.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GenerationResult {
  /// Returns a new [GenerationResult] instance.
  GenerationResult({
    this.draft,

    this.error,

    this.ingredientConfirmations,

    this.numericWarnings,

    required this.requestId,

    this.safety,

    required this.status,
  });

  @JsonKey(name: r'draft', required: false, includeIfNull: false)
  final GeneratedDraft? draft;

  @JsonKey(name: r'error', required: false, includeIfNull: false)
  final String? error;

  @JsonKey(
    name: r'ingredient_confirmations',
    required: false,
    includeIfNull: false,
  )
  final List<String>? ingredientConfirmations;

  @JsonKey(name: r'numeric_warnings', required: false, includeIfNull: false)
  final List<String>? numericWarnings;

  @JsonKey(name: r'request_id', required: true, includeIfNull: false)
  final String requestId;

  @JsonKey(name: r'safety', required: false, includeIfNull: false)
  final RecipeSafetyResult? safety;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AIStatus status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerationResult &&
          other.draft == draft &&
          other.error == error &&
          other.ingredientConfirmations == ingredientConfirmations &&
          other.numericWarnings == numericWarnings &&
          other.requestId == requestId &&
          other.safety == safety &&
          other.status == status;

  @override
  int get hashCode =>
      (draft == null ? 0 : draft.hashCode) +
      (error == null ? 0 : error.hashCode) +
      ingredientConfirmations.hashCode +
      numericWarnings.hashCode +
      requestId.hashCode +
      (safety == null ? 0 : safety.hashCode) +
      status.hashCode;

  factory GenerationResult.fromJson(Map<String, dynamic> json) =>
      _$GenerationResultFromJson(json);

  Map<String, dynamic> toJson() => _$GenerationResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
