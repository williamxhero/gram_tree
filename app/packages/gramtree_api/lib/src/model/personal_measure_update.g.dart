// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_measure_update.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PersonalMeasureUpdateCWProxy {
  PersonalMeasureUpdate capacityMl(num? capacityMl);

  PersonalMeasureUpdate kind(PersonalMeasureUpdateKindEnum? kind);

  PersonalMeasureUpdate name(String? name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PersonalMeasureUpdate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PersonalMeasureUpdate(...).copyWith(id: 12, name: "My name")
  /// ````
  PersonalMeasureUpdate call({
    num? capacityMl,
    PersonalMeasureUpdateKindEnum? kind,
    String? name,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPersonalMeasureUpdate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPersonalMeasureUpdate.copyWith.fieldName(...)`
class _$PersonalMeasureUpdateCWProxyImpl
    implements _$PersonalMeasureUpdateCWProxy {
  const _$PersonalMeasureUpdateCWProxyImpl(this._value);

  final PersonalMeasureUpdate _value;

  @override
  PersonalMeasureUpdate capacityMl(num? capacityMl) =>
      this(capacityMl: capacityMl);

  @override
  PersonalMeasureUpdate kind(PersonalMeasureUpdateKindEnum? kind) =>
      this(kind: kind);

  @override
  PersonalMeasureUpdate name(String? name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PersonalMeasureUpdate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PersonalMeasureUpdate(...).copyWith(id: 12, name: "My name")
  /// ````
  PersonalMeasureUpdate call({
    Object? capacityMl = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return PersonalMeasureUpdate(
      capacityMl: capacityMl == const $CopyWithPlaceholder()
          ? _value.capacityMl
          // ignore: cast_nullable_to_non_nullable
          : capacityMl as num?,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as PersonalMeasureUpdateKindEnum?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
    );
  }
}

extension $PersonalMeasureUpdateCopyWith on PersonalMeasureUpdate {
  /// Returns a callable class that can be used as follows: `instanceOfPersonalMeasureUpdate.copyWith(...)` or like so:`instanceOfPersonalMeasureUpdate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PersonalMeasureUpdateCWProxy get copyWith =>
      _$PersonalMeasureUpdateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalMeasureUpdate _$PersonalMeasureUpdateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PersonalMeasureUpdate', json, ($checkedConvert) {
  final val = PersonalMeasureUpdate(
    capacityMl: $checkedConvert('capacity_ml', (v) => v as num?),
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecodeNullable(_$PersonalMeasureUpdateKindEnumEnumMap, v),
    ),
    name: $checkedConvert('name', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'capacityMl': 'capacity_ml'});

Map<String, dynamic> _$PersonalMeasureUpdateToJson(
  PersonalMeasureUpdate instance,
) => <String, dynamic>{
  'capacity_ml': ?instance.capacityMl,
  'kind': ?_$PersonalMeasureUpdateKindEnumEnumMap[instance.kind],
  'name': ?instance.name,
};

const _$PersonalMeasureUpdateKindEnumEnumMap = {
  PersonalMeasureUpdateKindEnum.spoon: 'spoon',
  PersonalMeasureUpdateKindEnum.bowl: 'bowl',
  PersonalMeasureUpdateKindEnum.cup: 'cup',
};
