// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dish_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DishOutCWProxy {
  DishOut aliases(List<String> aliases);

  DishOut id(String id);

  DishOut name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DishOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DishOut(...).copyWith(id: 12, name: "My name")
  /// ````
  DishOut call({List<String> aliases, String id, String name});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDishOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDishOut.copyWith.fieldName(...)`
class _$DishOutCWProxyImpl implements _$DishOutCWProxy {
  const _$DishOutCWProxyImpl(this._value);

  final DishOut _value;

  @override
  DishOut aliases(List<String> aliases) => this(aliases: aliases);

  @override
  DishOut id(String id) => this(id: id);

  @override
  DishOut name(String name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DishOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DishOut(...).copyWith(id: 12, name: "My name")
  /// ````
  DishOut call({
    Object? aliases = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return DishOut(
      aliases: aliases == const $CopyWithPlaceholder()
          ? _value.aliases
          // ignore: cast_nullable_to_non_nullable
          : aliases as List<String>,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $DishOutCopyWith on DishOut {
  /// Returns a callable class that can be used as follows: `instanceOfDishOut.copyWith(...)` or like so:`instanceOfDishOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DishOutCWProxy get copyWith => _$DishOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DishOut _$DishOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DishOut', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['aliases', 'id', 'name']);
      final val = DishOut(
        aliases: $checkedConvert(
          'aliases',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DishOutToJson(DishOut instance) => <String, dynamic>{
  'aliases': instance.aliases,
  'id': instance.id,
  'name': instance.name,
};
