// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_constraints_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CookingConstraintsOutCWProxy {
  CookingConstraintsOut constraints(CookingConstraints constraints);

  CookingConstraintsOut dishTypes(
    List<CookingConstraintsOutDishTypesEnum> dishTypes,
  );

  CookingConstraintsOut equipmentVocabulary(
    List<CookingEquipment> equipmentVocabulary,
  );

  CookingConstraintsOut profileVersion(int profileVersion);

  CookingConstraintsOut servingsMax(int servingsMax);

  CookingConstraintsOut servingsMin(int servingsMin);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingConstraintsOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingConstraintsOut(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingConstraintsOut call({
    CookingConstraints constraints,
    List<CookingConstraintsOutDishTypesEnum> dishTypes,
    List<CookingEquipment> equipmentVocabulary,
    int profileVersion,
    int servingsMax,
    int servingsMin,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCookingConstraintsOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCookingConstraintsOut.copyWith.fieldName(...)`
class _$CookingConstraintsOutCWProxyImpl
    implements _$CookingConstraintsOutCWProxy {
  const _$CookingConstraintsOutCWProxyImpl(this._value);

  final CookingConstraintsOut _value;

  @override
  CookingConstraintsOut constraints(CookingConstraints constraints) =>
      this(constraints: constraints);

  @override
  CookingConstraintsOut dishTypes(
    List<CookingConstraintsOutDishTypesEnum> dishTypes,
  ) => this(dishTypes: dishTypes);

  @override
  CookingConstraintsOut equipmentVocabulary(
    List<CookingEquipment> equipmentVocabulary,
  ) => this(equipmentVocabulary: equipmentVocabulary);

  @override
  CookingConstraintsOut profileVersion(int profileVersion) =>
      this(profileVersion: profileVersion);

  @override
  CookingConstraintsOut servingsMax(int servingsMax) =>
      this(servingsMax: servingsMax);

  @override
  CookingConstraintsOut servingsMin(int servingsMin) =>
      this(servingsMin: servingsMin);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingConstraintsOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingConstraintsOut(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingConstraintsOut call({
    Object? constraints = const $CopyWithPlaceholder(),
    Object? dishTypes = const $CopyWithPlaceholder(),
    Object? equipmentVocabulary = const $CopyWithPlaceholder(),
    Object? profileVersion = const $CopyWithPlaceholder(),
    Object? servingsMax = const $CopyWithPlaceholder(),
    Object? servingsMin = const $CopyWithPlaceholder(),
  }) {
    return CookingConstraintsOut(
      constraints: constraints == const $CopyWithPlaceholder()
          ? _value.constraints
          // ignore: cast_nullable_to_non_nullable
          : constraints as CookingConstraints,
      dishTypes: dishTypes == const $CopyWithPlaceholder()
          ? _value.dishTypes
          // ignore: cast_nullable_to_non_nullable
          : dishTypes as List<CookingConstraintsOutDishTypesEnum>,
      equipmentVocabulary: equipmentVocabulary == const $CopyWithPlaceholder()
          ? _value.equipmentVocabulary
          // ignore: cast_nullable_to_non_nullable
          : equipmentVocabulary as List<CookingEquipment>,
      profileVersion: profileVersion == const $CopyWithPlaceholder()
          ? _value.profileVersion
          // ignore: cast_nullable_to_non_nullable
          : profileVersion as int,
      servingsMax: servingsMax == const $CopyWithPlaceholder()
          ? _value.servingsMax
          // ignore: cast_nullable_to_non_nullable
          : servingsMax as int,
      servingsMin: servingsMin == const $CopyWithPlaceholder()
          ? _value.servingsMin
          // ignore: cast_nullable_to_non_nullable
          : servingsMin as int,
    );
  }
}

extension $CookingConstraintsOutCopyWith on CookingConstraintsOut {
  /// Returns a callable class that can be used as follows: `instanceOfCookingConstraintsOut.copyWith(...)` or like so:`instanceOfCookingConstraintsOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CookingConstraintsOutCWProxy get copyWith =>
      _$CookingConstraintsOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookingConstraintsOut _$CookingConstraintsOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CookingConstraintsOut',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'constraints',
        'dish_types',
        'equipment_vocabulary',
        'profile_version',
        'servings_max',
        'servings_min',
      ],
    );
    final val = CookingConstraintsOut(
      constraints: $checkedConvert(
        'constraints',
        (v) => CookingConstraints.fromJson(v as Map<String, dynamic>),
      ),
      dishTypes: $checkedConvert(
        'dish_types',
        (v) => (v as List<dynamic>)
            .map(
              (e) =>
                  $enumDecode(_$CookingConstraintsOutDishTypesEnumEnumMap, e),
            )
            .toList(),
      ),
      equipmentVocabulary: $checkedConvert(
        'equipment_vocabulary',
        (v) => (v as List<dynamic>)
            .map((e) => CookingEquipment.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      profileVersion: $checkedConvert(
        'profile_version',
        (v) => (v as num).toInt(),
      ),
      servingsMax: $checkedConvert('servings_max', (v) => (v as num).toInt()),
      servingsMin: $checkedConvert('servings_min', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'dishTypes': 'dish_types',
    'equipmentVocabulary': 'equipment_vocabulary',
    'profileVersion': 'profile_version',
    'servingsMax': 'servings_max',
    'servingsMin': 'servings_min',
  },
);

Map<String, dynamic> _$CookingConstraintsOutToJson(
  CookingConstraintsOut instance,
) => <String, dynamic>{
  'constraints': instance.constraints.toJson(),
  'dish_types': instance.dishTypes
      .map((e) => _$CookingConstraintsOutDishTypesEnumEnumMap[e]!)
      .toList(),
  'equipment_vocabulary': instance.equipmentVocabulary
      .map((e) => e.toJson())
      .toList(),
  'profile_version': instance.profileVersion,
  'servings_max': instance.servingsMax,
  'servings_min': instance.servingsMin,
};

const _$CookingConstraintsOutDishTypesEnumEnumMap = {
  CookingConstraintsOutDishTypesEnum.meat: 'meat',
  CookingConstraintsOutDishTypesEnum.vegetable: 'vegetable',
  CookingConstraintsOutDishTypesEnum.soup: 'soup',
  CookingConstraintsOutDishTypesEnum.staple: 'staple',
  CookingConstraintsOutDishTypesEnum.other: 'other',
};
