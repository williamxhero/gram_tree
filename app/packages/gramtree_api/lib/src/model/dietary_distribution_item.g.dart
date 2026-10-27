// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dietary_distribution_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DietaryDistributionItemCWProxy {
  DietaryDistributionItem count(int count);

  DietaryDistributionItem key(String key);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DietaryDistributionItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DietaryDistributionItem(...).copyWith(id: 12, name: "My name")
  /// ````
  DietaryDistributionItem call({int count, String key});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDietaryDistributionItem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDietaryDistributionItem.copyWith.fieldName(...)`
class _$DietaryDistributionItemCWProxyImpl
    implements _$DietaryDistributionItemCWProxy {
  const _$DietaryDistributionItemCWProxyImpl(this._value);

  final DietaryDistributionItem _value;

  @override
  DietaryDistributionItem count(int count) => this(count: count);

  @override
  DietaryDistributionItem key(String key) => this(key: key);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DietaryDistributionItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DietaryDistributionItem(...).copyWith(id: 12, name: "My name")
  /// ````
  DietaryDistributionItem call({
    Object? count = const $CopyWithPlaceholder(),
    Object? key = const $CopyWithPlaceholder(),
  }) {
    return DietaryDistributionItem(
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      key: key == const $CopyWithPlaceholder()
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
    );
  }
}

extension $DietaryDistributionItemCopyWith on DietaryDistributionItem {
  /// Returns a callable class that can be used as follows: `instanceOfDietaryDistributionItem.copyWith(...)` or like so:`instanceOfDietaryDistributionItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DietaryDistributionItemCWProxy get copyWith =>
      _$DietaryDistributionItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DietaryDistributionItem _$DietaryDistributionItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DietaryDistributionItem', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['count', 'key']);
  final val = DietaryDistributionItem(
    count: $checkedConvert('count', (v) => (v as num).toInt()),
    key: $checkedConvert('key', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$DietaryDistributionItemToJson(
  DietaryDistributionItem instance,
) => <String, dynamic>{'count': instance.count, 'key': instance.key};
