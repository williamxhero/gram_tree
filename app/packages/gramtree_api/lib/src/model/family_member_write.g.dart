// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_member_write.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FamilyMemberWriteCWProxy {
  FamilyMemberWrite ageBand(FamilyMemberWriteAgeBandEnum ageBand);

  FamilyMemberWrite allergies(FamilyAllergiesWrite? allergies);

  FamilyMemberWrite authorizationVersion(int authorizationVersion);

  FamilyMemberWrite avoidances(List<FamilyAvoidance>? avoidances);

  FamilyMemberWrite consentId(String consentId);

  FamilyMemberWrite flavors(Map<String, num>? flavors);

  FamilyMemberWrite nickname(String nickname);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FamilyMemberWrite(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FamilyMemberWrite(...).copyWith(id: 12, name: "My name")
  /// ````
  FamilyMemberWrite call({
    FamilyMemberWriteAgeBandEnum ageBand,
    FamilyAllergiesWrite? allergies,
    int authorizationVersion,
    List<FamilyAvoidance>? avoidances,
    String consentId,
    Map<String, num>? flavors,
    String nickname,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFamilyMemberWrite.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFamilyMemberWrite.copyWith.fieldName(...)`
class _$FamilyMemberWriteCWProxyImpl implements _$FamilyMemberWriteCWProxy {
  const _$FamilyMemberWriteCWProxyImpl(this._value);

  final FamilyMemberWrite _value;

  @override
  FamilyMemberWrite ageBand(FamilyMemberWriteAgeBandEnum ageBand) =>
      this(ageBand: ageBand);

  @override
  FamilyMemberWrite allergies(FamilyAllergiesWrite? allergies) =>
      this(allergies: allergies);

  @override
  FamilyMemberWrite authorizationVersion(int authorizationVersion) =>
      this(authorizationVersion: authorizationVersion);

  @override
  FamilyMemberWrite avoidances(List<FamilyAvoidance>? avoidances) =>
      this(avoidances: avoidances);

  @override
  FamilyMemberWrite consentId(String consentId) => this(consentId: consentId);

  @override
  FamilyMemberWrite flavors(Map<String, num>? flavors) =>
      this(flavors: flavors);

  @override
  FamilyMemberWrite nickname(String nickname) => this(nickname: nickname);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FamilyMemberWrite(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FamilyMemberWrite(...).copyWith(id: 12, name: "My name")
  /// ````
  FamilyMemberWrite call({
    Object? ageBand = const $CopyWithPlaceholder(),
    Object? allergies = const $CopyWithPlaceholder(),
    Object? authorizationVersion = const $CopyWithPlaceholder(),
    Object? avoidances = const $CopyWithPlaceholder(),
    Object? consentId = const $CopyWithPlaceholder(),
    Object? flavors = const $CopyWithPlaceholder(),
    Object? nickname = const $CopyWithPlaceholder(),
  }) {
    return FamilyMemberWrite(
      ageBand: ageBand == const $CopyWithPlaceholder()
          ? _value.ageBand
          // ignore: cast_nullable_to_non_nullable
          : ageBand as FamilyMemberWriteAgeBandEnum,
      allergies: allergies == const $CopyWithPlaceholder()
          ? _value.allergies
          // ignore: cast_nullable_to_non_nullable
          : allergies as FamilyAllergiesWrite?,
      authorizationVersion: authorizationVersion == const $CopyWithPlaceholder()
          ? _value.authorizationVersion
          // ignore: cast_nullable_to_non_nullable
          : authorizationVersion as int,
      avoidances: avoidances == const $CopyWithPlaceholder()
          ? _value.avoidances
          // ignore: cast_nullable_to_non_nullable
          : avoidances as List<FamilyAvoidance>?,
      consentId: consentId == const $CopyWithPlaceholder()
          ? _value.consentId
          // ignore: cast_nullable_to_non_nullable
          : consentId as String,
      flavors: flavors == const $CopyWithPlaceholder()
          ? _value.flavors
          // ignore: cast_nullable_to_non_nullable
          : flavors as Map<String, num>?,
      nickname: nickname == const $CopyWithPlaceholder()
          ? _value.nickname
          // ignore: cast_nullable_to_non_nullable
          : nickname as String,
    );
  }
}

extension $FamilyMemberWriteCopyWith on FamilyMemberWrite {
  /// Returns a callable class that can be used as follows: `instanceOfFamilyMemberWrite.copyWith(...)` or like so:`instanceOfFamilyMemberWrite.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FamilyMemberWriteCWProxy get copyWith =>
      _$FamilyMemberWriteCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyMemberWrite _$FamilyMemberWriteFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'FamilyMemberWrite',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'age_band',
        'authorization_version',
        'consent_id',
        'nickname',
      ],
    );
    final val = FamilyMemberWrite(
      ageBand: $checkedConvert(
        'age_band',
        (v) => $enumDecode(_$FamilyMemberWriteAgeBandEnumEnumMap, v),
      ),
      allergies: $checkedConvert(
        'allergies',
        (v) => v == null
            ? null
            : FamilyAllergiesWrite.fromJson(v as Map<String, dynamic>),
      ),
      authorizationVersion: $checkedConvert(
        'authorization_version',
        (v) => (v as num).toInt(),
      ),
      avoidances: $checkedConvert(
        'avoidances',
        (v) => (v as List<dynamic>?)
            ?.map((e) => FamilyAvoidance.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      consentId: $checkedConvert('consent_id', (v) => v as String),
      flavors: $checkedConvert(
        'flavors',
        (v) =>
            (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as num)),
      ),
      nickname: $checkedConvert('nickname', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'ageBand': 'age_band',
    'authorizationVersion': 'authorization_version',
    'consentId': 'consent_id',
  },
);

Map<String, dynamic> _$FamilyMemberWriteToJson(FamilyMemberWrite instance) =>
    <String, dynamic>{
      'age_band': _$FamilyMemberWriteAgeBandEnumEnumMap[instance.ageBand]!,
      'allergies': ?instance.allergies?.toJson(),
      'authorization_version': instance.authorizationVersion,
      'avoidances': ?instance.avoidances?.map((e) => e.toJson()).toList(),
      'consent_id': instance.consentId,
      'flavors': ?instance.flavors,
      'nickname': instance.nickname,
    };

const _$FamilyMemberWriteAgeBandEnumEnumMap = {
  FamilyMemberWriteAgeBandEnum.under1: 'under_1',
  FamilyMemberWriteAgeBandEnum.n1to3: '1_to_3',
  FamilyMemberWriteAgeBandEnum.n3to6: '3_to_6',
  FamilyMemberWriteAgeBandEnum.n6to12: '6_to_12',
  FamilyMemberWriteAgeBandEnum.n12to18: '12_to_18',
  FamilyMemberWriteAgeBandEnum.adult: 'adult',
  FamilyMemberWriteAgeBandEnum.elder: 'elder',
};
