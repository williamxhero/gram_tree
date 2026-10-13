//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/family_member_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'family_members_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FamilyMembersOut {
  /// Returns a new [FamilyMembersOut] instance.
  FamilyMembersOut({
    required this.authorizationVersion,

    required this.availableAgeBands,

    required this.availableAllergenCategories,

    required this.consentId,

    required this.consentVersion,

    required this.items,

    this.nextCursor,

    required this.profileVersion,
  });

  @JsonKey(name: r'authorization_version', required: true, includeIfNull: false)
  final int authorizationVersion;

  @JsonKey(name: r'available_age_bands', required: true, includeIfNull: false)
  final List<FamilyMembersOutAvailableAgeBandsEnum> availableAgeBands;

  @JsonKey(
    name: r'available_allergen_categories',
    required: true,
    includeIfNull: false,
  )
  final List<String> availableAllergenCategories;

  @JsonKey(name: r'consent_id', required: true, includeIfNull: true)
  final String? consentId;

  @JsonKey(name: r'consent_version', required: true, includeIfNull: false)
  final String consentVersion;

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<FamilyMemberOut> items;

  @JsonKey(name: r'next_cursor', required: false, includeIfNull: false)
  final String? nextCursor;

  @JsonKey(name: r'profile_version', required: true, includeIfNull: false)
  final int profileVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyMembersOut &&
          other.authorizationVersion == authorizationVersion &&
          other.availableAgeBands == availableAgeBands &&
          other.availableAllergenCategories == availableAllergenCategories &&
          other.consentId == consentId &&
          other.consentVersion == consentVersion &&
          other.items == items &&
          other.nextCursor == nextCursor &&
          other.profileVersion == profileVersion;

  @override
  int get hashCode =>
      authorizationVersion.hashCode +
      availableAgeBands.hashCode +
      availableAllergenCategories.hashCode +
      (consentId == null ? 0 : consentId.hashCode) +
      consentVersion.hashCode +
      items.hashCode +
      (nextCursor == null ? 0 : nextCursor.hashCode) +
      profileVersion.hashCode;

  factory FamilyMembersOut.fromJson(Map<String, dynamic> json) =>
      _$FamilyMembersOutFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyMembersOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum FamilyMembersOutAvailableAgeBandsEnum {
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

  const FamilyMembersOutAvailableAgeBandsEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
