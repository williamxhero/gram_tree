//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_snapshot.dart';
import 'package:gramtree_api/src/model/improvement_taste_proposal.dart';
import 'package:gramtree_api/src/model/recipe_full_comparison.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'improvement_preview_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImprovementPreviewOut {
  /// Returns a new [ImprovementPreviewOut] instance.
  ImprovementPreviewOut({
    required this.comparison,

    this.microadjustPrompt,

    required this.snapshot,

    required this.tasteProposal,
  });

  @JsonKey(name: r'comparison', required: true, includeIfNull: false)
  final RecipeFullComparison comparison;

  @JsonKey(name: r'microadjust_prompt', required: false, includeIfNull: false)
  final String? microadjustPrompt;

  @JsonKey(name: r'snapshot', required: true, includeIfNull: false)
  final RecipeSnapshot snapshot;

  @JsonKey(name: r'taste_proposal', required: true, includeIfNull: false)
  final ImprovementTasteProposal tasteProposal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImprovementPreviewOut &&
          other.comparison == comparison &&
          other.microadjustPrompt == microadjustPrompt &&
          other.snapshot == snapshot &&
          other.tasteProposal == tasteProposal;

  @override
  int get hashCode =>
      comparison.hashCode +
      (microadjustPrompt == null ? 0 : microadjustPrompt.hashCode) +
      snapshot.hashCode +
      tasteProposal.hashCode;

  factory ImprovementPreviewOut.fromJson(Map<String, dynamic> json) =>
      _$ImprovementPreviewOutFromJson(json);

  Map<String, dynamic> toJson() => _$ImprovementPreviewOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
