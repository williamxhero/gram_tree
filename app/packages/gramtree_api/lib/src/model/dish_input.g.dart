// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dish_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DishInputCWProxy {
  DishInput aliases(List<String>? aliases);

  DishInput name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DishInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DishInput(...).copyWith(id: 12, name: "My name")
  /// ````
  DishInput call({List<String>? aliases, String name});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDishInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDishInput.copyWith.fieldName(...)`
class _$DishInputCWProxyImpl implements _$DishInputCWProxy {
  const _$DishInputCWProxyImpl(this._value);

  final DishInput _value;

  @override
  DishInput aliases(List<String>? aliases) => this(aliases: aliases);

  @override
  DishInput name(String name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DishInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DishInput(...).copyWith(id: 12, name: "My name")
  /// ````
  DishInput call({
    Object? aliases = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return DishInput(
      aliases: aliases == const $CopyWithPlaceholder()
          ? _value.aliases
          // ignore: cast_nullable_to_non_nullable
          : aliases as List<String>?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $DishInputCopyWith on DishInput {
  /// Returns a callable class that can be used as follows: `instanceOfDishInput.copyWith(...)` or like so:`instanceOfDishInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DishInputCWProxy get copyWith => _$DishInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DishInput _$DishInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DishInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name']);
      final val = DishInput(
        aliases: $checkedConvert(
          'aliases',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DishInputToJson(DishInput instance) => <String, dynamic>{
  'aliases': ?instance.aliases,
  'name': instance.name,
};
