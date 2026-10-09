//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/family_avoidance.dart';
import 'package:gramtree_api/src/model/family_allergies_write.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'family_member_write.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FamilyMemberWrite {
  /// Returns a new [FamilyMemberWrite] instance.
  FamilyMemberWrite({
    required this.ageBand,

    this.allergies,

    required this.authorizationVersion,

    this.avoidances,

    required this.consentId,

    this.flavors,

    required this.nickname,
  });

  @JsonKey(name: r'age_band', required: true, includeIfNull: false)
  final FamilyMemberWriteAgeBandEnum ageBand;

  @JsonKey(name: r'allergies', required: false, includeIfNull: false)
  final FamilyAllergiesWrite? allergies;

  // minimum: 0
  @JsonKey(name: r'authorization_version', required: true, includeIfNull: false)
  final int authorizationVersion;

  @JsonKey(name: r'avoidances', required: false, includeIfNull: false)
  final List<FamilyAvoidance>? avoidances;

  @JsonKey(name: r'consent_id', required: true, includeIfNull: false)
  final String consentId;

  @JsonKey(name: r'flavors', required: false, includeIfNull: false)
  final Map<String, num>? flavors;

  @JsonKey(name: r'nickname', required: true, includeIfNull: false)
  final String nickname;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyMemberWrite &&
          other.ageBand == ageBand &&
          other.allergies == allergies &&
          other.authorizationVersion == authorizationVersion &&
          other.avoidances == avoidances &&
          other.consentId == consentId &&
          other.flavors == flavors &&
          other.nickname == nickname;

  @override
  int get hashCode =>
      ageBand.hashCode +
      allergies.hashCode +
      authorizationVersion.hashCode +
      avoidances.hashCode +
      consentId.hashCode +
      flavors.hashCode +
      nickname.hashCode;

  factory FamilyMemberWrite.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberWriteFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyMemberWriteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum FamilyMemberWriteAgeBandEnum {
  @JsonValue(r'under_1')
  under1(r'under_1'),
  @JsonValue(r'1_to_3')
  n1to3(r'1_to_3'),
  @JsonValue(r'3_to_6')
  n3to6(r'3_to_6'),
  @JsonValue(r'6_to_12')
  n6to12(r'6_to_12'),
  @JsonValue(r'12_to_18')
  n12to18(r'12_to_18'),
  @JsonValue(r'adult')
  adult(r'adult'),
  @JsonValue(r'elder')
  elder(r'elder');

  const FamilyMemberWriteAgeBandEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
