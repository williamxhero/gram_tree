// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taste_level.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TasteLevelCWProxy {
  TasteLevel coefficient(num coefficient);

  TasteLevel label(String label);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TasteLevel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TasteLevel(...).copyWith(id: 12, name: "My name")
  /// ````
  TasteLevel call({num coefficient, String label});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTasteLevel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTasteLevel.copyWith.fieldName(...)`
class _$TasteLevelCWProxyImpl implements _$TasteLevelCWProxy {
  const _$TasteLevelCWProxyImpl(this._value);

  final TasteLevel _value;

  @override
  TasteLevel coefficient(num coefficient) => this(coefficient: coefficient);

  @override
  TasteLevel label(String label) => this(label: label);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TasteLevel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TasteLevel(...).copyWith(id: 12, name: "My name")
  /// ````
  TasteLevel call({
    Object? coefficient = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
  }) {
    return TasteLevel(
      coefficient: coefficient == const $CopyWithPlaceholder()
          ? _value.coefficient
          // ignore: cast_nullable_to_non_nullable
          : coefficient as num,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
    );
  }
}

extension $TasteLevelCopyWith on TasteLevel {
  /// Returns a callable class that can be used as follows: `instanceOfTasteLevel.copyWith(...)` or like so:`instanceOfTasteLevel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TasteLevelCWProxy get copyWith => _$TasteLevelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TasteLevel _$TasteLevelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TasteLevel', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['coefficient', 'label']);
      final val = TasteLevel(
        coefficient: $checkedConvert('coefficient', (v) => v as num),
        label: $checkedConvert('label', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$TasteLevelToJson(TasteLevel instance) =>
    <String, dynamic>{
      'coefficient': instance.coefficient,
      'label': instance.label,
    };
