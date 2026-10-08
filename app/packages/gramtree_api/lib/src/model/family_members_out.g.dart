// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_members_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FamilyMembersOutCWProxy {
  FamilyMembersOut authorizationVersion(int authorizationVersion);

  FamilyMembersOut availableAgeBands(
    List<FamilyMembersOutAvailableAgeBandsEnum> availableAgeBands,
  );

  FamilyMembersOut availableAllergenCategories(
    List<String> availableAllergenCategories,
  );

  FamilyMembersOut consentId(String? consentId);

  FamilyMembersOut consentVersion(String consentVersion);

  FamilyMembersOut members(List<FamilyMemberOut> members);

  FamilyMembersOut nextCursor(String? nextCursor);

  FamilyMembersOut profileVersion(int profileVersion);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FamilyMembersOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FamilyMembersOut(...).copyWith(id: 12, name: "My name")
  /// ````
  FamilyMembersOut call({
    int authorizationVersion,
    List<FamilyMembersOutAvailableAgeBandsEnum> availableAgeBands,
    List<String> availableAllergenCategories,
    String? consentId,
    String consentVersion,
    List<FamilyMemberOut> members,
    String? nextCursor,
    int profileVersion,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFamilyMembersOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFamilyMembersOut.copyWith.fieldName(...)`
class _$FamilyMembersOutCWProxyImpl implements _$FamilyMembersOutCWProxy {
  const _$FamilyMembersOutCWProxyImpl(this._value);

  final FamilyMembersOut _value;

  @override
  FamilyMembersOut authorizationVersion(int authorizationVersion) =>
      this(authorizationVersion: authorizationVersion);

  @override
  FamilyMembersOut availableAgeBands(
    List<FamilyMembersOutAvailableAgeBandsEnum> availableAgeBands,
  ) => this(availableAgeBands: availableAgeBands);

  @override
  FamilyMembersOut availableAllergenCategories(
    List<String> availableAllergenCategories,
  ) => this(availableAllergenCategories: availableAllergenCategories);

  @override
  FamilyMembersOut consentId(String? consentId) => this(consentId: consentId);

  @override
  FamilyMembersOut consentVersion(String consentVersion) =>
      this(consentVersion: consentVersion);

  @override
  FamilyMembersOut members(List<FamilyMemberOut> members) =>
      this(members: members);

  @override
  FamilyMembersOut nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  FamilyMembersOut profileVersion(int profileVersion) =>
      this(profileVersion: profileVersion);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FamilyMembersOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FamilyMembersOut(...).copyWith(id: 12, name: "My name")
  /// ````
  FamilyMembersOut call({
    Object? authorizationVersion = const $CopyWithPlaceholder(),
    Object? availableAgeBands = const $CopyWithPlaceholder(),
    Object? availableAllergenCategories = const $CopyWithPlaceholder(),
    Object? consentId = const $CopyWithPlaceholder(),
    Object? consentVersion = const $CopyWithPlaceholder(),
    Object? members = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
    Object? profileVersion = const $CopyWithPlaceholder(),
  }) {
    return FamilyMembersOut(
      authorizationVersion: authorizationVersion == const $CopyWithPlaceholder()
          ? _value.authorizationVersion
          // ignore: cast_nullable_to_non_nullable
          : authorizationVersion as int,
      availableAgeBands: availableAgeBands == const $CopyWithPlaceholder()
          ? _value.availableAgeBands
          // ignore: cast_nullable_to_non_nullable
          : availableAgeBands as List<FamilyMembersOutAvailableAgeBandsEnum>,
      availableAllergenCategories:
          availableAllergenCategories == const $CopyWithPlaceholder()
          ? _value.availableAllergenCategories
          // ignore: cast_nullable_to_non_nullable
          : availableAllergenCategories as List<String>,
      consentId: consentId == const $CopyWithPlaceholder()
          ? _value.consentId
          // ignore: cast_nullable_to_non_nullable
          : consentId as String?,
      consentVersion: consentVersion == const $CopyWithPlaceholder()
          ? _value.consentVersion
          // ignore: cast_nullable_to_non_nullable
          : consentVersion as String,
      members: members == const $CopyWithPlaceholder()
          ? _value.members
          // ignore: cast_nullable_to_non_nullable
          : members as List<FamilyMemberOut>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
      profileVersion: profileVersion == const $CopyWithPlaceholder()
          ? _value.profileVersion
          // ignore: cast_nullable_to_non_nullable
          : profileVersion as int,
    );
  }
}

extension $FamilyMembersOutCopyWith on FamilyMembersOut {
  /// Returns a callable class that can be used as follows: `instanceOfFamilyMembersOut.copyWith(...)` or like so:`instanceOfFamilyMembersOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FamilyMembersOutCWProxy get copyWith => _$FamilyMembersOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyMembersOut _$FamilyMembersOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'FamilyMembersOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'authorization_version',
            'available_age_bands',
            'available_allergen_categories',
            'consent_id',
            'consent_version',
            'members',
            'profile_version',
          ],
        );
        final val = FamilyMembersOut(
          authorizationVersion: $checkedConvert(
            'authorization_version',
            (v) => (v as num).toInt(),
          ),
          availableAgeBands: $checkedConvert(
            'available_age_bands',
            (v) => (v as List<dynamic>)
                .map(
                  (e) => $enumDecode(
                    _$FamilyMembersOutAvailableAgeBandsEnumEnumMap,
                    e,
                  ),
                )
                .toList(),
          ),
          availableAllergenCategories: $checkedConvert(
            'available_allergen_categories',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          consentId: $checkedConvert('consent_id', (v) => v as String?),
          consentVersion: $checkedConvert(
            'consent_version',
            (v) => v as String,
          ),
          members: $checkedConvert(
            'members',
            (v) => (v as List<dynamic>)
                .map((e) => FamilyMemberOut.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
          profileVersion: $checkedConvert(
            'profile_version',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'authorizationVersion': 'authorization_version',
        'availableAgeBands': 'available_age_bands',
        'availableAllergenCategories': 'available_allergen_categories',
        'consentId': 'consent_id',
        'consentVersion': 'consent_version',
        'nextCursor': 'next_cursor',
        'profileVersion': 'profile_version',
      },
    );

Map<String, dynamic> _$FamilyMembersOutToJson(FamilyMembersOut instance) =>
    <String, dynamic>{
      'authorization_version': instance.authorizationVersion,
      'available_age_bands': instance.availableAgeBands
          .map((e) => _$FamilyMembersOutAvailableAgeBandsEnumEnumMap[e]!)
          .toList(),
      'available_allergen_categories': instance.availableAllergenCategories,
      'consent_id': instance.consentId,
      'consent_version': instance.consentVersion,
      'members': instance.members.map((e) => e.toJson()).toList(),
      'next_cursor': ?instance.nextCursor,
      'profile_version': instance.profileVersion,
    };

const _$FamilyMembersOutAvailableAgeBandsEnumEnumMap = {
  FamilyMembersOutAvailableAgeBandsEnum.under1: 'under_1',
  FamilyMembersOutAvailableAgeBandsEnum.n1to3: '1_to_3',
  FamilyMembersOutAvailableAgeBandsEnum.n3to6: '3_to_6',
  FamilyMembersOutAvailableAgeBandsEnum.n6to12: '6_to_12',
  FamilyMembersOutAvailableAgeBandsEnum.n12to18: '12_to_18',
  FamilyMembersOutAvailableAgeBandsEnum.adult: 'adult',
  FamilyMembersOutAvailableAgeBandsEnum.elder: 'elder',
};
