// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_member_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FamilyMemberOutCWProxy {
  FamilyMemberOut ageBand(FamilyMemberOutAgeBandEnum ageBand);

  FamilyMemberOut allergies(FamilyAllergiesOut allergies);

  FamilyMemberOut avoidances(List<FamilyAvoidanceOut> avoidances);

  FamilyMemberOut flavors(Map<String, num> flavors);

  FamilyMemberOut id(String id);

  FamilyMemberOut nickname(String nickname);

  FamilyMemberOut source_(FamilyMemberOutSource_Enum source_);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FamilyMemberOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FamilyMemberOut(...).copyWith(id: 12, name: "My name")
  /// ````
  FamilyMemberOut call({
    FamilyMemberOutAgeBandEnum ageBand,
    FamilyAllergiesOut allergies,
    List<FamilyAvoidanceOut> avoidances,
    Map<String, num> flavors,
    String id,
    String nickname,
    FamilyMemberOutSource_Enum source_,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFamilyMemberOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFamilyMemberOut.copyWith.fieldName(...)`
class _$FamilyMemberOutCWProxyImpl implements _$FamilyMemberOutCWProxy {
  const _$FamilyMemberOutCWProxyImpl(this._value);

  final FamilyMemberOut _value;

  @override
  FamilyMemberOut ageBand(FamilyMemberOutAgeBandEnum ageBand) =>
      this(ageBand: ageBand);

  @override
  FamilyMemberOut allergies(FamilyAllergiesOut allergies) =>
      this(allergies: allergies);

  @override
  FamilyMemberOut avoidances(List<FamilyAvoidanceOut> avoidances) =>
      this(avoidances: avoidances);

  @override
  FamilyMemberOut flavors(Map<String, num> flavors) => this(flavors: flavors);

  @override
  FamilyMemberOut id(String id) => this(id: id);

  @override
  FamilyMemberOut nickname(String nickname) => this(nickname: nickname);

  @override
  FamilyMemberOut source_(FamilyMemberOutSource_Enum source_) =>
      this(source_: source_);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FamilyMemberOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FamilyMemberOut(...).copyWith(id: 12, name: "My name")
  /// ````
  FamilyMemberOut call({
    Object? ageBand = const $CopyWithPlaceholder(),
    Object? allergies = const $CopyWithPlaceholder(),
    Object? avoidances = const $CopyWithPlaceholder(),
    Object? flavors = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? nickname = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
  }) {
    return FamilyMemberOut(
      ageBand: ageBand == const $CopyWithPlaceholder()
          ? _value.ageBand
          // ignore: cast_nullable_to_non_nullable
          : ageBand as FamilyMemberOutAgeBandEnum,
      allergies: allergies == const $CopyWithPlaceholder()
          ? _value.allergies
          // ignore: cast_nullable_to_non_nullable
          : allergies as FamilyAllergiesOut,
      avoidances: avoidances == const $CopyWithPlaceholder()
          ? _value.avoidances
          // ignore: cast_nullable_to_non_nullable
          : avoidances as List<FamilyAvoidanceOut>,
      flavors: flavors == const $CopyWithPlaceholder()
          ? _value.flavors
          // ignore: cast_nullable_to_non_nullable
          : flavors as Map<String, num>,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      nickname: nickname == const $CopyWithPlaceholder()
          ? _value.nickname
          // ignore: cast_nullable_to_non_nullable
          : nickname as String,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as FamilyMemberOutSource_Enum,
    );
  }
}

extension $FamilyMemberOutCopyWith on FamilyMemberOut {
  /// Returns a callable class that can be used as follows: `instanceOfFamilyMemberOut.copyWith(...)` or like so:`instanceOfFamilyMemberOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FamilyMemberOutCWProxy get copyWith => _$FamilyMemberOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FamilyMemberOut _$FamilyMemberOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('FamilyMemberOut', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'age_band',
      'allergies',
      'avoidances',
      'flavors',
      'id',
      'nickname',
      'source',
    ],
  );
  final val = FamilyMemberOut(
    ageBand: $checkedConvert(
      'age_band',
      (v) => $enumDecode(_$FamilyMemberOutAgeBandEnumEnumMap, v),
    ),
    allergies: $checkedConvert(
      'allergies',
      (v) => FamilyAllergiesOut.fromJson(v as Map<String, dynamic>),
    ),
    avoidances: $checkedConvert(
      'avoidances',
      (v) => (v as List<dynamic>)
          .map((e) => FamilyAvoidanceOut.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    flavors: $checkedConvert('flavors', (v) => Map<String, num>.from(v as Map)),
    id: $checkedConvert('id', (v) => v as String),
    nickname: $checkedConvert('nickname', (v) => v as String),
    source_: $checkedConvert(
      'source',
      (v) => $enumDecode(_$FamilyMemberOutSource_EnumEnumMap, v),
    ),
  );
  return val;
}, fieldKeyMap: const {'ageBand': 'age_band', 'source_': 'source'});

Map<String, dynamic> _$FamilyMemberOutToJson(FamilyMemberOut instance) =>
    <String, dynamic>{
      'age_band': _$FamilyMemberOutAgeBandEnumEnumMap[instance.ageBand]!,
      'allergies': instance.allergies.toJson(),
      'avoidances': instance.avoidances.map((e) => e.toJson()).toList(),
      'flavors': instance.flavors,
      'id': instance.id,
      'nickname': instance.nickname,
      'source': _$FamilyMemberOutSource_EnumEnumMap[instance.source_]!,
    };

const _$FamilyMemberOutAgeBandEnumEnumMap = {
  FamilyMemberOutAgeBandEnum.under1: 'under_1',
  FamilyMemberOutAgeBandEnum.n1to3: '1_to_3',
  FamilyMemberOutAgeBandEnum.n3to6: '3_to_6',
  FamilyMemberOutAgeBandEnum.n6to12: '6_to_12',
  FamilyMemberOutAgeBandEnum.n12to18: '12_to_18',
  FamilyMemberOutAgeBandEnum.adult: 'adult',
  FamilyMemberOutAgeBandEnum.elder: 'elder',
};

const _$FamilyMemberOutSource_EnumEnumMap = {
  FamilyMemberOutSource_Enum.manual: 'manual',
};
