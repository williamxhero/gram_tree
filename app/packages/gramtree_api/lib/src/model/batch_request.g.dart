// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BatchRequestCWProxy {
  BatchRequest ids(List<String> ids);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BatchRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BatchRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  BatchRequest call({List<String> ids});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBatchRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBatchRequest.copyWith.fieldName(...)`
class _$BatchRequestCWProxyImpl implements _$BatchRequestCWProxy {
  const _$BatchRequestCWProxyImpl(this._value);

  final BatchRequest _value;

  @override
  BatchRequest ids(List<String> ids) => this(ids: ids);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BatchRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BatchRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  BatchRequest call({Object? ids = const $CopyWithPlaceholder()}) {
    return BatchRequest(
      ids: ids == const $CopyWithPlaceholder()
          ? _value.ids
          // ignore: cast_nullable_to_non_nullable
          : ids as List<String>,
    );
  }
}

extension $BatchRequestCopyWith on BatchRequest {
  /// Returns a callable class that can be used as follows: `instanceOfBatchRequest.copyWith(...)` or like so:`instanceOfBatchRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BatchRequestCWProxy get copyWith => _$BatchRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchRequest _$BatchRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BatchRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['ids']);
      final val = BatchRequest(
        ids: $checkedConvert(
          'ids',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BatchRequestToJson(BatchRequest instance) =>
    <String, dynamic>{'ids': instance.ids};
