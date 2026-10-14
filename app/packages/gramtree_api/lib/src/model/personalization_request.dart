//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/mold_spec.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'personalization_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PersonalizationRequest {
  /// Returns a new [PersonalizationRequest] instance.
  PersonalizationRequest({
    this.confirmAllergyRisk = false,

    this.dinerMemberIds,

    this.equipment,

    this.primaryDinerId,

    this.targetMold,

    this.targetServings,

    this.versionId,
  });

  @JsonKey(
    defaultValue: false,
    name: r'confirm_allergy_risk',
    required: false,
    includeIfNull: false,
  )
  final bool? confirmAllergyRisk;

  @JsonKey(name: r'diner_member_ids', required: false, includeIfNull: false)
  final List<String>? dinerMemberIds;

  @JsonKey(name: r'equipment', required: false, includeIfNull: false)
  final List<String>? equipment;

  @JsonKey(name: r'primary_diner_id', required: false, includeIfNull: false)
  final String? primaryDinerId;

  @JsonKey(name: r'target_mold', required: false, includeIfNull: false)
  final MoldSpec? targetMold;

  // minimum: 1
  // maximum: 1000
  @JsonKey(name: r'target_servings', required: false, includeIfNull: false)
  final int? targetServings;

  @JsonKey(name: r'version_id', required: false, includeIfNull: false)
  final String? versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalizationRequest &&
          other.confirmAllergyRisk == confirmAllergyRisk &&
          other.dinerMemberIds == dinerMemberIds &&
          other.equipment == equipment &&
          other.primaryDinerId == primaryDinerId &&
          other.targetMold == targetMold &&
          other.targetServings == targetServings &&
          other.versionId == versionId;

  @override
  int get hashCode =>
      confirmAllergyRisk.hashCode +
      dinerMemberIds.hashCode +
      (equipment == null ? 0 : equipment.hashCode) +
      (primaryDinerId == null ? 0 : primaryDinerId.hashCode) +
      (targetMold == null ? 0 : targetMold.hashCode) +
      (targetServings == null ? 0 : targetServings.hashCode) +
      (versionId == null ? 0 : versionId.hashCode);

  factory PersonalizationRequest.fromJson(Map<String, dynamic> json) =>
      _$PersonalizationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalizationRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
