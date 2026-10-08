// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_equipment.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CookingEquipmentCWProxy {
  CookingEquipment aliases(List<String>? aliases);

  CookingEquipment id(String id);

  CookingEquipment label(String label);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingEquipment(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingEquipment(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingEquipment call({List<String>? aliases, String id, String label});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCookingEquipment.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCookingEquipment.copyWith.fieldName(...)`
class _$CookingEquipmentCWProxyImpl implements _$CookingEquipmentCWProxy {
  const _$CookingEquipmentCWProxyImpl(this._value);

  final CookingEquipment _value;

  @override
  CookingEquipment aliases(List<String>? aliases) => this(aliases: aliases);

  @override
  CookingEquipment id(String id) => this(id: id);

  @override
  CookingEquipment label(String label) => this(label: label);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingEquipment(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingEquipment(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingEquipment call({
    Object? aliases = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
  }) {
    return CookingEquipment(
      aliases: aliases == const $CopyWithPlaceholder()
          ? _value.aliases
          // ignore: cast_nullable_to_non_nullable
          : aliases as List<String>?,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
    );
  }
}

extension $CookingEquipmentCopyWith on CookingEquipment {
  /// Returns a callable class that can be used as follows: `instanceOfCookingEquipment.copyWith(...)` or like so:`instanceOfCookingEquipment.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CookingEquipmentCWProxy get copyWith => _$CookingEquipmentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookingEquipment _$CookingEquipmentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CookingEquipment', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'label']);
      final val = CookingEquipment(
        aliases: $checkedConvert(
          'aliases',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        id: $checkedConvert('id', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$CookingEquipmentToJson(CookingEquipment instance) =>
    <String, dynamic>{
      'aliases': ?instance.aliases,
      'id': instance.id,
      'label': instance.label,
    };
