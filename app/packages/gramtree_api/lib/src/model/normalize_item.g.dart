// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'normalize_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NormalizeItemCWProxy {
  NormalizeItem context(String? context);

  NormalizeItem name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NormalizeItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NormalizeItem(...).copyWith(id: 12, name: "My name")
  /// ````
  NormalizeItem call({String? context, String name});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfNormalizeItem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfNormalizeItem.copyWith.fieldName(...)`
class _$NormalizeItemCWProxyImpl implements _$NormalizeItemCWProxy {
  const _$NormalizeItemCWProxyImpl(this._value);

  final NormalizeItem _value;

  @override
  NormalizeItem context(String? context) => this(context: context);

  @override
  NormalizeItem name(String name) => this(name: name);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NormalizeItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NormalizeItem(...).copyWith(id: 12, name: "My name")
  /// ````
  NormalizeItem call({
    Object? context = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return NormalizeItem(
      context: context == const $CopyWithPlaceholder()
          ? _value.context
          // ignore: cast_nullable_to_non_nullable
          : context as String?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $NormalizeItemCopyWith on NormalizeItem {
  /// Returns a callable class that can be used as follows: `instanceOfNormalizeItem.copyWith(...)` or like so:`instanceOfNormalizeItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NormalizeItemCWProxy get copyWith => _$NormalizeItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NormalizeItem _$NormalizeItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NormalizeItem', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name']);
      final val = NormalizeItem(
        context: $checkedConvert('context', (v) => v as String?),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$NormalizeItemToJson(NormalizeItem instance) =>
    <String, dynamic>{'context': ?instance.context, 'name': instance.name};
