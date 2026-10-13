//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/taste_profile_change_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'learning_run_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LearningRunOut {
  /// Returns a new [LearningRunOut] instance.
  LearningRunOut({
    required this.appliedChanges,

    required this.pendingSuggestions,

    required this.signalsConsidered,
  });

  @JsonKey(name: r'applied_changes', required: true, includeIfNull: false)
  final List<TasteProfileChangeOut> appliedChanges;

  @JsonKey(name: r'pending_suggestions', required: true, includeIfNull: false)
  final List<TasteProfileChangeOut> pendingSuggestions;

  @JsonKey(name: r'signals_considered', required: true, includeIfNull: false)
  final int signalsConsidered;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningRunOut &&
          other.appliedChanges == appliedChanges &&
          other.pendingSuggestions == pendingSuggestions &&
          other.signalsConsidered == signalsConsidered;

  @override
  int get hashCode =>
      appliedChanges.hashCode +
      pendingSuggestions.hashCode +
      signalsConsidered.hashCode;

  factory LearningRunOut.fromJson(Map<String, dynamic> json) =>
      _$LearningRunOutFromJson(json);

  Map<String, dynamic> toJson() => _$LearningRunOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
