//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/ai_status.dart';
import 'package:gramtree_api/src/model/batch_advice.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_batch_advice_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeBatchAdviceOut {
  /// Returns a new [RecipeBatchAdviceOut] instance.
  RecipeBatchAdviceOut({
    this.advice,

    required this.eligible,

    this.error,

    required this.originalServings,

    required this.recipeId,

    required this.status,

    required this.targetServings,

    required this.versionId,
  });

  @JsonKey(name: r'advice', required: false, includeIfNull: false)
  final BatchAdvice? advice;

  @JsonKey(name: r'eligible', required: true, includeIfNull: false)
  final bool eligible;

  @JsonKey(name: r'error', required: false, includeIfNull: false)
  final String? error;

  @JsonKey(name: r'original_servings', required: true, includeIfNull: false)
  final int originalServings;

  @JsonKey(name: r'recipe_id', required: true, includeIfNull: false)
  final String recipeId;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final AIStatus status;

  @JsonKey(name: r'target_servings', required: true, includeIfNull: false)
  final int targetServings;

  @JsonKey(name: r'version_id', required: true, includeIfNull: false)
  final String versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeBatchAdviceOut &&
          other.advice == advice &&
          other.eligible == eligible &&
          other.error == error &&
          other.originalServings == originalServings &&
          other.recipeId == recipeId &&
          other.status == status &&
          other.targetServings == targetServings &&
          other.versionId == versionId;

  @override
  int get hashCode =>
      advice.hashCode +
      eligible.hashCode +
      (error == null ? 0 : error.hashCode) +
      originalServings.hashCode +
      recipeId.hashCode +
      status.hashCode +
      targetServings.hashCode +
      versionId.hashCode;

  factory RecipeBatchAdviceOut.fromJson(Map<String, dynamic> json) =>
      _$RecipeBatchAdviceOutFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeBatchAdviceOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
