// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BatchResponseCWProxy {
  BatchResponse items(List<IngredientDetail> items);

  BatchResponse missingIds(List<String> missingIds);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BatchResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BatchResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  BatchResponse call({List<IngredientDetail> items, List<String> missingIds});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBatchResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBatchResponse.copyWith.fieldName(...)`
class _$BatchResponseCWProxyImpl implements _$BatchResponseCWProxy {
  const _$BatchResponseCWProxyImpl(this._value);

  final BatchResponse _value;

  @override
  BatchResponse items(List<IngredientDetail> items) => this(items: items);

  @override
  BatchResponse missingIds(List<String> missingIds) =>
      this(missingIds: missingIds);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BatchResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BatchResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  BatchResponse call({
    Object? items = const $CopyWithPlaceholder(),
    Object? missingIds = const $CopyWithPlaceholder(),
  }) {
    return BatchResponse(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<IngredientDetail>,
      missingIds: missingIds == const $CopyWithPlaceholder()
          ? _value.missingIds
          // ignore: cast_nullable_to_non_nullable
          : missingIds as List<String>,
    );
  }
}

extension $BatchResponseCopyWith on BatchResponse {
  /// Returns a callable class that can be used as follows: `instanceOfBatchResponse.copyWith(...)` or like so:`instanceOfBatchResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BatchResponseCWProxy get copyWith => _$BatchResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchResponse _$BatchResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BatchResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items', 'missing_ids']);
      final val = BatchResponse(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => IngredientDetail.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        missingIds: $checkedConvert(
          'missing_ids',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'missingIds': 'missing_ids'});

Map<String, dynamic> _$BatchResponseToJson(BatchResponse instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'missing_ids': instance.missingIds,
    };
