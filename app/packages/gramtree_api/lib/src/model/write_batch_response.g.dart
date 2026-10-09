// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'write_batch_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WriteBatchResponseCWProxy {
  WriteBatchResponse results(List<WriteResult> results);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `WriteBatchResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// WriteBatchResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  WriteBatchResponse call({List<WriteResult> results});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfWriteBatchResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfWriteBatchResponse.copyWith.fieldName(...)`
class _$WriteBatchResponseCWProxyImpl implements _$WriteBatchResponseCWProxy {
  const _$WriteBatchResponseCWProxyImpl(this._value);

  final WriteBatchResponse _value;

  @override
  WriteBatchResponse results(List<WriteResult> results) =>
      this(results: results);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `WriteBatchResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// WriteBatchResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  WriteBatchResponse call({Object? results = const $CopyWithPlaceholder()}) {
    return WriteBatchResponse(
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<WriteResult>,
    );
  }
}

extension $WriteBatchResponseCopyWith on WriteBatchResponse {
  /// Returns a callable class that can be used as follows: `instanceOfWriteBatchResponse.copyWith(...)` or like so:`instanceOfWriteBatchResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WriteBatchResponseCWProxy get copyWith =>
      _$WriteBatchResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WriteBatchResponse _$WriteBatchResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WriteBatchResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['results']);
      final val = WriteBatchResponse(
        results: $checkedConvert(
          'results',
          (v) => (v as List<dynamic>)
              .map((e) => WriteResult.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$WriteBatchResponseToJson(WriteBatchResponse instance) =>
    <String, dynamic>{
      'results': instance.results.map((e) => e.toJson()).toList(),
    };
