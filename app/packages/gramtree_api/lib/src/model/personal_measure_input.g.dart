// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_measure_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PersonalMeasureInputCWProxy {
  PersonalMeasureInput capacityMl(num capacityMl);

  PersonalMeasureInput kind(PersonalMeasureInputKindEnum kind);

  PersonalMeasureInput name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PersonalMeasureInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PersonalMeasureInput(...).copyWith(id: 12, name: "My name")
  /// ````
  PersonalMeasureInput call({
    num capacityMl,
    PersonalMeasureInputKindEnum kind,
    String name,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPersonalMeasureInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPersonalMeasureInput.copyWith.fieldName(...)`
class _$PersonalMeasureInputCWProxyImpl
    implements _$PersonalMeasureInputCWProxy {
  const _$PersonalMeasureInputCWProxyImpl(this._value);

  final PersonalMeasureInput _value;

  @override
  PersonalMeasureInput capacityMl(num capacityMl) =>
      this(capacityMl: capacityMl);

  @override
  PersonalMeasureInput kind(PersonalMeasureInputKindEnum kind) =>
      this(kind: kind);

  @override
  PersonalMeasureInput name(String name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PersonalMeasureInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PersonalMeasureInput(...).copyWith(id: 12, name: "My name")
  /// ````
  PersonalMeasureInput call({
    Object? capacityMl = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return PersonalMeasureInput(
      capacityMl: capacityMl == const $CopyWithPlaceholder()
          ? _value.capacityMl
          // ignore: cast_nullable_to_non_nullable
          : capacityMl as num,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as PersonalMeasureInputKindEnum,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $PersonalMeasureInputCopyWith on PersonalMeasureInput {
  /// Returns a callable class that can be used as follows: `instanceOfPersonalMeasureInput.copyWith(...)` or like so:`instanceOfPersonalMeasureInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PersonalMeasureInputCWProxy get copyWith =>
      _$PersonalMeasureInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalMeasureInput _$PersonalMeasureInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PersonalMeasureInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['capacity_ml', 'kind', 'name']);
  final val = PersonalMeasureInput(
    capacityMl: $checkedConvert('capacity_ml', (v) => v as num),
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$PersonalMeasureInputKindEnumEnumMap, v),
    ),
    name: $checkedConvert('name', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'capacityMl': 'capacity_ml'});

Map<String, dynamic> _$PersonalMeasureInputToJson(
  PersonalMeasureInput instance,
) => <String, dynamic>{
  'capacity_ml': instance.capacityMl,
  'kind': _$PersonalMeasureInputKindEnumEnumMap[instance.kind]!,
  'name': instance.name,
};

const _$PersonalMeasureInputKindEnumEnumMap = {
  PersonalMeasureInputKindEnum.spoon: 'spoon',
  PersonalMeasureInputKindEnum.bowl: 'bowl',
  PersonalMeasureInputKindEnum.cup: 'cup',
};
