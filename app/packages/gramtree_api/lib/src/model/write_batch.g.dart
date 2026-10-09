// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'write_batch.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WriteBatchCWProxy {
  WriteBatch writes(List<WriteEnvelope> writes);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `WriteBatch(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// WriteBatch(...).copyWith(id: 12, name: "My name")
  /// ````
  WriteBatch call({List<WriteEnvelope> writes});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfWriteBatch.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfWriteBatch.copyWith.fieldName(...)`
class _$WriteBatchCWProxyImpl implements _$WriteBatchCWProxy {
  const _$WriteBatchCWProxyImpl(this._value);

  final WriteBatch _value;

  @override
  WriteBatch writes(List<WriteEnvelope> writes) => this(writes: writes);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `WriteBatch(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// WriteBatch(...).copyWith(id: 12, name: "My name")
  /// ````
  WriteBatch call({Object? writes = const $CopyWithPlaceholder()}) {
    return WriteBatch(
      writes: writes == const $CopyWithPlaceholder()
          ? _value.writes
          // ignore: cast_nullable_to_non_nullable
          : writes as List<WriteEnvelope>,
    );
  }
}

extension $WriteBatchCopyWith on WriteBatch {
  /// Returns a callable class that can be used as follows: `instanceOfWriteBatch.copyWith(...)` or like so:`instanceOfWriteBatch.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WriteBatchCWProxy get copyWith => _$WriteBatchCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WriteBatch _$WriteBatchFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WriteBatch', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['writes']);
      final val = WriteBatch(
        writes: $checkedConvert(
          'writes',
          (v) => (v as List<dynamic>)
              .map((e) => WriteEnvelope.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$WriteBatchToJson(WriteBatch instance) =>
    <String, dynamic>{
      'writes': instance.writes.map((e) => e.toJson()).toList(),
    };
