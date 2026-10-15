//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_detail.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'improvement_save_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImprovementSaveOut {
  /// Returns a new [ImprovementSaveOut] instance.
  ImprovementSaveOut({required this.outcome, this.profileVersion, this.recipe});

  @JsonKey(name: r'outcome', required: true, includeIfNull: false)
  final ImprovementSaveOutOutcomeEnum outcome;

  @JsonKey(name: r'profile_version', required: false, includeIfNull: false)
  final int? profileVersion;

  @JsonKey(name: r'recipe', required: false, includeIfNull: false)
  final RecipeDetail? recipe;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImprovementSaveOut &&
          other.outcome == outcome &&
          other.profileVersion == profileVersion &&
          other.recipe == recipe;

  @override
  int get hashCode =>
      outcome.hashCode +
      (profileVersion == null ? 0 : profileVersion.hashCode) +
      recipe.hashCode;

  factory ImprovementSaveOut.fromJson(Map<String, dynamic> json) =>
      _$ImprovementSaveOutFromJson(json);

  Map<String, dynamic> toJson() => _$ImprovementSaveOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ImprovementSaveOutOutcomeEnum {
  @JsonValue(r'branch')
  branch(r'branch'),
  @JsonValue(r'taste')
  taste(r'taste');

  const ImprovementSaveOutOutcomeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
