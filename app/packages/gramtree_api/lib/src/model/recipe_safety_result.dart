//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/recipe_safety_finding.dart';
import 'package:gramtree_api/src/model/recipe_replacement_allergens.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_safety_result.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeSafetyResult {
  /// Returns a new [RecipeSafetyResult] instance.
  RecipeSafetyResult({
    this.allergens,

    this.allergensIncomplete = false,

    this.canSave = true,

    required this.checkedAt,

    this.claimBasis,

    this.findings,

    this.highRisk = false,

    this.prohibitedClaims,

    this.replacementAllergens,

    required this.rulesVersion,

    this.stale = false,
  });

  @JsonKey(name: r'allergens', required: false, includeIfNull: false)
  final List<String>? allergens;

  @JsonKey(
    defaultValue: false,
    name: r'allergens_incomplete',
    required: false,
    includeIfNull: false,
  )
  final bool? allergensIncomplete;

  @JsonKey(
    defaultValue: true,
    name: r'can_save',
    required: false,
    includeIfNull: false,
  )
  final bool? canSave;

  @JsonKey(name: r'checked_at', required: true, includeIfNull: false)
  final String checkedAt;

  @JsonKey(name: r'claim_basis', required: false, includeIfNull: false)
  final String? claimBasis;

  @JsonKey(name: r'findings', required: false, includeIfNull: false)
  final List<RecipeSafetyFinding>? findings;

  @JsonKey(
    defaultValue: false,
    name: r'high_risk',
    required: false,
    includeIfNull: false,
  )
  final bool? highRisk;

  @JsonKey(name: r'prohibited_claims', required: false, includeIfNull: false)
  final List<String>? prohibitedClaims;

  @JsonKey(
    name: r'replacement_allergens',
    required: false,
    includeIfNull: false,
  )
  final List<RecipeReplacementAllergens>? replacementAllergens;

  @JsonKey(name: r'rules_version', required: true, includeIfNull: false)
  final String rulesVersion;

  /// 当前检查早于已部署规则，正在等待后台复检
  @JsonKey(
    defaultValue: false,
    name: r'stale',
    required: false,
    includeIfNull: false,
  )
  final bool? stale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeSafetyResult &&
          other.allergens == allergens &&
          other.allergensIncomplete == allergensIncomplete &&
          other.canSave == canSave &&
          other.checkedAt == checkedAt &&
          other.claimBasis == claimBasis &&
          other.findings == findings &&
          other.highRisk == highRisk &&
          other.prohibitedClaims == prohibitedClaims &&
          other.replacementAllergens == replacementAllergens &&
          other.rulesVersion == rulesVersion &&
          other.stale == stale;

  @override
  int get hashCode =>
      allergens.hashCode +
      allergensIncomplete.hashCode +
      canSave.hashCode +
      checkedAt.hashCode +
      (claimBasis == null ? 0 : claimBasis.hashCode) +
      findings.hashCode +
      highRisk.hashCode +
      prohibitedClaims.hashCode +
      replacementAllergens.hashCode +
      rulesVersion.hashCode +
      stale.hashCode;

  factory RecipeSafetyResult.fromJson(Map<String, dynamic> json) =>
      _$RecipeSafetyResultFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeSafetyResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
