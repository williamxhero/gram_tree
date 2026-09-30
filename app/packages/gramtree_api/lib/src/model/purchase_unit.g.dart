// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_unit.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PurchaseUnitCWProxy {
  PurchaseUnit grams(num grams);

  PurchaseUnit name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PurchaseUnit(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PurchaseUnit(...).copyWith(id: 12, name: "My name")
  /// ````
  PurchaseUnit call({num grams, String name});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPurchaseUnit.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPurchaseUnit.copyWith.fieldName(...)`
class _$PurchaseUnitCWProxyImpl implements _$PurchaseUnitCWProxy {
  const _$PurchaseUnitCWProxyImpl(this._value);

  final PurchaseUnit _value;

  @override
  PurchaseUnit grams(num grams) => this(grams: grams);

  @override
  PurchaseUnit name(String name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PurchaseUnit(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PurchaseUnit(...).copyWith(id: 12, name: "My name")
  /// ````
  PurchaseUnit call({
    Object? grams = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return PurchaseUnit(
      grams: grams == const $CopyWithPlaceholder()
          ? _value.grams
          // ignore: cast_nullable_to_non_nullable
          : grams as num,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $PurchaseUnitCopyWith on PurchaseUnit {
  /// Returns a callable class that can be used as follows: `instanceOfPurchaseUnit.copyWith(...)` or like so:`instanceOfPurchaseUnit.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PurchaseUnitCWProxy get copyWith => _$PurchaseUnitCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseUnit _$PurchaseUnitFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PurchaseUnit', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['grams', 'name']);
      final val = PurchaseUnit(
        grams: $checkedConvert('grams', (v) => v as num),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PurchaseUnitToJson(PurchaseUnit instance) =>
    <String, dynamic>{'grams': instance.grams, 'name': instance.name};
