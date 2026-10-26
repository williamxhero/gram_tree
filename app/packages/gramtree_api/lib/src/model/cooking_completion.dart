//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cooking_completion.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CookingCompletion {
  /// Returns a new [CookingCompletion] instance.
  CookingCompletion({
    required this.completedSteps,

    required this.executionToken,

    required this.finishedAt,

    required this.reachedSteps,

    required this.sessionId,

    this.skippedSteps,

    required this.startedAt,

    required this.status,
  });

  @JsonKey(name: r'completed_steps', required: true, includeIfNull: false)
  final List<String> completedSteps;

  @JsonKey(name: r'execution_token', required: true, includeIfNull: false)
  final String executionToken;

  @JsonKey(name: r'finished_at', required: true, includeIfNull: false)
  final DateTime finishedAt;

  @JsonKey(name: r'reached_steps', required: true, includeIfNull: false)
  final List<String> reachedSteps;

  @JsonKey(name: r'session_id', required: true, includeIfNull: false)
  final String sessionId;

  @JsonKey(name: r'skipped_steps', required: false, includeIfNull: false)
  final List<String>? skippedSteps;

  @JsonKey(name: r'started_at', required: true, includeIfNull: false)
  final DateTime startedAt;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final CookingCompletionStatusEnum status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CookingCompletion &&
          other.completedSteps == completedSteps &&
          other.executionToken == executionToken &&
          other.finishedAt == finishedAt &&
          other.reachedSteps == reachedSteps &&
          other.sessionId == sessionId &&
          other.skippedSteps == skippedSteps &&
          other.startedAt == startedAt &&
          other.status == status;

  @override
  int get hashCode =>
      completedSteps.hashCode +
      executionToken.hashCode +
      finishedAt.hashCode +
      reachedSteps.hashCode +
      sessionId.hashCode +
      skippedSteps.hashCode +
      startedAt.hashCode +
      status.hashCode;

  factory CookingCompletion.fromJson(Map<String, dynamic> json) =>
      _$CookingCompletionFromJson(json);

  Map<String, dynamic> toJson() => _$CookingCompletionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CookingCompletionStatusEnum {
  @JsonValue(r'completed')
  completed(r'completed');

  const CookingCompletionStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
