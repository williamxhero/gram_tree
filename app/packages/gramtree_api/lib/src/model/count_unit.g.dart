// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'count_unit.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CountUnitCWProxy {
  CountUnit grams(num grams);

  CountUnit unit(String unit);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CountUnit(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CountUnit(...).copyWith(id: 12, name: "My name")
  /// ````
  CountUnit call({num grams, String unit});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCountUnit.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCountUnit.copyWith.fieldName(...)`
class _$CountUnitCWProxyImpl implements _$CountUnitCWProxy {
  const _$CountUnitCWProxyImpl(this._value);

  final CountUnit _value;

  @override
  CountUnit grams(num grams) => this(grams: grams);

  @override
  CountUnit unit(String unit) => this(unit: unit);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CountUnit(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CountUnit(...).copyWith(id: 12, name: "My name")
  /// ````
  CountUnit call({
    Object? grams = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
  }) {
    return CountUnit(
      grams: grams == const $CopyWithPlaceholder()
          ? _value.grams
          // ignore: cast_nullable_to_non_nullable
          : grams as num,
      unit: unit == const $CopyWithPlaceholder()
          ? _value.unit
          // ignore: cast_nullable_to_non_nullable
          : unit as String,
    );
  }
}

extension $CountUnitCopyWith on CountUnit {
  /// Returns a callable class that can be used as follows: `instanceOfCountUnit.copyWith(...)` or like so:`instanceOfCountUnit.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CountUnitCWProxy get copyWith => _$CountUnitCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CountUnit _$CountUnitFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CountUnit', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['grams', 'unit']);
      final val = CountUnit(
        grams: $checkedConvert('grams', (v) => v as num),
        unit: $checkedConvert('unit', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$CountUnitToJson(CountUnit instance) => <String, dynamic>{
  'grams': instance.grams,
  'unit': instance.unit,
};
