// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_measure_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PersonalMeasureOutCWProxy {
  PersonalMeasureOut capacityMl(num capacityMl);

  PersonalMeasureOut createdAt(String createdAt);

  PersonalMeasureOut id(String id);

  PersonalMeasureOut kind(PersonalMeasureOutKindEnum kind);

  PersonalMeasureOut name(String name);

  PersonalMeasureOut updatedAt(String updatedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PersonalMeasureOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PersonalMeasureOut(...).copyWith(id: 12, name: "My name")
  /// ````
  PersonalMeasureOut call({
    num capacityMl,
    String createdAt,
    String id,
    PersonalMeasureOutKindEnum kind,
    String name,
    String updatedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPersonalMeasureOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPersonalMeasureOut.copyWith.fieldName(...)`
class _$PersonalMeasureOutCWProxyImpl implements _$PersonalMeasureOutCWProxy {
  const _$PersonalMeasureOutCWProxyImpl(this._value);

  final PersonalMeasureOut _value;

  @override
  PersonalMeasureOut capacityMl(num capacityMl) => this(capacityMl: capacityMl);

  @override
  PersonalMeasureOut createdAt(String createdAt) => this(createdAt: createdAt);

  @override
  PersonalMeasureOut id(String id) => this(id: id);

  @override
  PersonalMeasureOut kind(PersonalMeasureOutKindEnum kind) => this(kind: kind);

  @override
  PersonalMeasureOut name(String name) => this(name: name);

  @override
  PersonalMeasureOut updatedAt(String updatedAt) => this(updatedAt: updatedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PersonalMeasureOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PersonalMeasureOut(...).copyWith(id: 12, name: "My name")
  /// ````
  PersonalMeasureOut call({
    Object? capacityMl = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return PersonalMeasureOut(
      capacityMl: capacityMl == const $CopyWithPlaceholder()
          ? _value.capacityMl
          // ignore: cast_nullable_to_non_nullable
          : capacityMl as num,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as String,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as PersonalMeasureOutKindEnum,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as String,
    );
  }
}

extension $PersonalMeasureOutCopyWith on PersonalMeasureOut {
  /// Returns a callable class that can be used as follows: `instanceOfPersonalMeasureOut.copyWith(...)` or like so:`instanceOfPersonalMeasureOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PersonalMeasureOutCWProxy get copyWith =>
      _$PersonalMeasureOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalMeasureOut _$PersonalMeasureOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PersonalMeasureOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'capacity_ml',
            'created_at',
            'id',
            'kind',
            'name',
            'updated_at',
          ],
        );
        final val = PersonalMeasureOut(
          capacityMl: $checkedConvert('capacity_ml', (v) => v as num),
          createdAt: $checkedConvert('created_at', (v) => v as String),
          id: $checkedConvert('id', (v) => v as String),
          kind: $checkedConvert(
            'kind',
            (v) => $enumDecode(_$PersonalMeasureOutKindEnumEnumMap, v),
          ),
          name: $checkedConvert('name', (v) => v as String),
          updatedAt: $checkedConvert('updated_at', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'capacityMl': 'capacity_ml',
        'createdAt': 'created_at',
        'updatedAt': 'updated_at',
      },
    );

Map<String, dynamic> _$PersonalMeasureOutToJson(PersonalMeasureOut instance) =>
    <String, dynamic>{
      'capacity_ml': instance.capacityMl,
      'created_at': instance.createdAt,
      'id': instance.id,
      'kind': _$PersonalMeasureOutKindEnumEnumMap[instance.kind]!,
      'name': instance.name,
      'updated_at': instance.updatedAt,
    };

const _$PersonalMeasureOutKindEnumEnumMap = {
  PersonalMeasureOutKindEnum.spoon: 'spoon',
  PersonalMeasureOutKindEnum.bowl: 'bowl',
  PersonalMeasureOutKindEnum.cup: 'cup',
};
