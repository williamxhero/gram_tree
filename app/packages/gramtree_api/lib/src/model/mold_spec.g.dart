// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mold_spec.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MoldSpecCWProxy {
  MoldSpec diameter(num? diameter);

  MoldSpec length(num? length);

  MoldSpec shape(MoldSpecShapeEnum shape);

  MoldSpec side(num? side);

  MoldSpec unit(MoldSpecUnitEnum? unit);

  MoldSpec width(num? width);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MoldSpec(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MoldSpec(...).copyWith(id: 12, name: "My name")
  /// ````
  MoldSpec call({
    num? diameter,
    num? length,
    MoldSpecShapeEnum shape,
    num? side,
    MoldSpecUnitEnum? unit,
    num? width,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMoldSpec.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMoldSpec.copyWith.fieldName(...)`
class _$MoldSpecCWProxyImpl implements _$MoldSpecCWProxy {
  const _$MoldSpecCWProxyImpl(this._value);

  final MoldSpec _value;

  @override
  MoldSpec diameter(num? diameter) => this(diameter: diameter);

  @override
  MoldSpec length(num? length) => this(length: length);

  @override
  MoldSpec shape(MoldSpecShapeEnum shape) => this(shape: shape);

  @override
  MoldSpec side(num? side) => this(side: side);

  @override
  MoldSpec unit(MoldSpecUnitEnum? unit) => this(unit: unit);

  @override
  MoldSpec width(num? width) => this(width: width);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MoldSpec(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MoldSpec(...).copyWith(id: 12, name: "My name")
  /// ````
  MoldSpec call({
    Object? diameter = const $CopyWithPlaceholder(),
    Object? length = const $CopyWithPlaceholder(),
    Object? shape = const $CopyWithPlaceholder(),
    Object? side = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
    Object? width = const $CopyWithPlaceholder(),
  }) {
    return MoldSpec(
      diameter: diameter == const $CopyWithPlaceholder()
          ? _value.diameter
          // ignore: cast_nullable_to_non_nullable
          : diameter as num?,
      length: length == const $CopyWithPlaceholder()
          ? _value.length
          // ignore: cast_nullable_to_non_nullable
          : length as num?,
      shape: shape == const $CopyWithPlaceholder()
          ? _value.shape
          // ignore: cast_nullable_to_non_nullable
          : shape as MoldSpecShapeEnum,
      side: side == const $CopyWithPlaceholder()
          ? _value.side
          // ignore: cast_nullable_to_non_nullable
          : side as num?,
      unit: unit == const $CopyWithPlaceholder()
          ? _value.unit
          // ignore: cast_nullable_to_non_nullable
          : unit as MoldSpecUnitEnum?,
      width: width == const $CopyWithPlaceholder()
          ? _value.width
          // ignore: cast_nullable_to_non_nullable
          : width as num?,
    );
  }
}

extension $MoldSpecCopyWith on MoldSpec {
  /// Returns a callable class that can be used as follows: `instanceOfMoldSpec.copyWith(...)` or like so:`instanceOfMoldSpec.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MoldSpecCWProxy get copyWith => _$MoldSpecCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoldSpec _$MoldSpecFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MoldSpec', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['shape']);
      final val = MoldSpec(
        diameter: $checkedConvert('diameter', (v) => v as num?),
        length: $checkedConvert('length', (v) => v as num?),
        shape: $checkedConvert(
          'shape',
          (v) => $enumDecode(_$MoldSpecShapeEnumEnumMap, v),
        ),
        side: $checkedConvert('side', (v) => v as num?),
        unit: $checkedConvert(
          'unit',
          (v) => $enumDecodeNullable(_$MoldSpecUnitEnumEnumMap, v),
        ),
        width: $checkedConvert('width', (v) => v as num?),
      );
      return val;
    });

Map<String, dynamic> _$MoldSpecToJson(MoldSpec instance) => <String, dynamic>{
  'diameter': ?instance.diameter,
  'length': ?instance.length,
  'shape': _$MoldSpecShapeEnumEnumMap[instance.shape]!,
  'side': ?instance.side,
  'unit': ?_$MoldSpecUnitEnumEnumMap[instance.unit],
  'width': ?instance.width,
};

const _$MoldSpecShapeEnumEnumMap = {
  MoldSpecShapeEnum.round: 'round',
  MoldSpecShapeEnum.square: 'square',
  MoldSpecShapeEnum.rectangular: 'rectangular',
  MoldSpecShapeEnum.custom: 'custom',
};

const _$MoldSpecUnitEnumEnumMap = {
  MoldSpecUnitEnum.cm: 'cm',
  MoldSpecUnitEnum.in_: 'in',
  MoldSpecUnitEnum.inch: 'inch',
};
