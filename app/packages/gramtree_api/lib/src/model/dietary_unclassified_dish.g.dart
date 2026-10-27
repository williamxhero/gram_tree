// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dietary_unclassified_dish.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DietaryUnclassifiedDishCWProxy {
  DietaryUnclassifiedDish name(String? name);

  DietaryUnclassifiedDish occurredAt(String occurredAt);

  DietaryUnclassifiedDish recordId(String recordId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DietaryUnclassifiedDish(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DietaryUnclassifiedDish(...).copyWith(id: 12, name: "My name")
  /// ````
  DietaryUnclassifiedDish call({
    String? name,
    String occurredAt,
    String recordId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDietaryUnclassifiedDish.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDietaryUnclassifiedDish.copyWith.fieldName(...)`
class _$DietaryUnclassifiedDishCWProxyImpl
    implements _$DietaryUnclassifiedDishCWProxy {
  const _$DietaryUnclassifiedDishCWProxyImpl(this._value);

  final DietaryUnclassifiedDish _value;

  @override
  DietaryUnclassifiedDish name(String? name) => this(name: name);

  @override
  DietaryUnclassifiedDish occurredAt(String occurredAt) =>
      this(occurredAt: occurredAt);

  @override
  DietaryUnclassifiedDish recordId(String recordId) => this(recordId: recordId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DietaryUnclassifiedDish(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DietaryUnclassifiedDish(...).copyWith(id: 12, name: "My name")
  /// ````
  DietaryUnclassifiedDish call({
    Object? name = const $CopyWithPlaceholder(),
    Object? occurredAt = const $CopyWithPlaceholder(),
    Object? recordId = const $CopyWithPlaceholder(),
  }) {
    return DietaryUnclassifiedDish(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      occurredAt: occurredAt == const $CopyWithPlaceholder()
          ? _value.occurredAt
          // ignore: cast_nullable_to_non_nullable
          : occurredAt as String,
      recordId: recordId == const $CopyWithPlaceholder()
          ? _value.recordId
          // ignore: cast_nullable_to_non_nullable
          : recordId as String,
    );
  }
}

extension $DietaryUnclassifiedDishCopyWith on DietaryUnclassifiedDish {
  /// Returns a callable class that can be used as follows: `instanceOfDietaryUnclassifiedDish.copyWith(...)` or like so:`instanceOfDietaryUnclassifiedDish.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DietaryUnclassifiedDishCWProxy get copyWith =>
      _$DietaryUnclassifiedDishCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DietaryUnclassifiedDish _$DietaryUnclassifiedDishFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DietaryUnclassifiedDish', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'occurred_at', 'record_id']);
  final val = DietaryUnclassifiedDish(
    name: $checkedConvert('name', (v) => v as String?),
    occurredAt: $checkedConvert('occurred_at', (v) => v as String),
    recordId: $checkedConvert('record_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'occurredAt': 'occurred_at', 'recordId': 'record_id'});

Map<String, dynamic> _$DietaryUnclassifiedDishToJson(
  DietaryUnclassifiedDish instance,
) => <String, dynamic>{
  'name': instance.name,
  'occurred_at': instance.occurredAt,
  'record_id': instance.recordId,
};
