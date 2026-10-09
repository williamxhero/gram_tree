// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'write_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WriteResultCWProxy {
  WriteResult conflict(Object? conflict);

  WriteResult reasonCode(String? reasonCode);

  WriteResult result(WriteResourceResult? result);

  WriteResult status(WriteResultStatusEnum status);

  WriteResult writeId(String writeId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `WriteResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// WriteResult(...).copyWith(id: 12, name: "My name")
  /// ````
  WriteResult call({
    Object? conflict,
    String? reasonCode,
    WriteResourceResult? result,
    WriteResultStatusEnum status,
    String writeId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfWriteResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfWriteResult.copyWith.fieldName(...)`
class _$WriteResultCWProxyImpl implements _$WriteResultCWProxy {
  const _$WriteResultCWProxyImpl(this._value);

  final WriteResult _value;

  @override
  WriteResult conflict(Object? conflict) => this(conflict: conflict);

  @override
  WriteResult reasonCode(String? reasonCode) => this(reasonCode: reasonCode);

  @override
  WriteResult result(WriteResourceResult? result) => this(result: result);

  @override
  WriteResult status(WriteResultStatusEnum status) => this(status: status);

  @override
  WriteResult writeId(String writeId) => this(writeId: writeId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `WriteResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// WriteResult(...).copyWith(id: 12, name: "My name")
  /// ````
  WriteResult call({
    Object? conflict = const $CopyWithPlaceholder(),
    Object? reasonCode = const $CopyWithPlaceholder(),
    Object? result = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? writeId = const $CopyWithPlaceholder(),
  }) {
    return WriteResult(
      conflict: conflict == const $CopyWithPlaceholder()
          ? _value.conflict
          // ignore: cast_nullable_to_non_nullable
          : conflict as Object?,
      reasonCode: reasonCode == const $CopyWithPlaceholder()
          ? _value.reasonCode
          // ignore: cast_nullable_to_non_nullable
          : reasonCode as String?,
      result: result == const $CopyWithPlaceholder()
          ? _value.result
          // ignore: cast_nullable_to_non_nullable
          : result as WriteResourceResult?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as WriteResultStatusEnum,
      writeId: writeId == const $CopyWithPlaceholder()
          ? _value.writeId
          // ignore: cast_nullable_to_non_nullable
          : writeId as String,
    );
  }
}

extension $WriteResultCopyWith on WriteResult {
  /// Returns a callable class that can be used as follows: `instanceOfWriteResult.copyWith(...)` or like so:`instanceOfWriteResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WriteResultCWProxy get copyWith => _$WriteResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WriteResult _$WriteResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WriteResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['status', 'write_id']);
      final val = WriteResult(
        conflict: $checkedConvert('conflict', (v) => v),
        reasonCode: $checkedConvert('reason_code', (v) => v as String?),
        result: $checkedConvert(
          'result',
          (v) => v == null
              ? null
              : WriteResourceResult.fromJson(v as Map<String, dynamic>),
        ),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$WriteResultStatusEnumEnumMap, v),
        ),
        writeId: $checkedConvert('write_id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'reasonCode': 'reason_code', 'writeId': 'write_id'});

Map<String, dynamic> _$WriteResultToJson(WriteResult instance) =>
    <String, dynamic>{
      'conflict': ?instance.conflict,
      'reason_code': ?instance.reasonCode,
      'result': ?instance.result?.toJson(),
      'status': _$WriteResultStatusEnumEnumMap[instance.status]!,
      'write_id': instance.writeId,
    };

const _$WriteResultStatusEnumEnumMap = {
  WriteResultStatusEnum.confirmed: 'confirmed',
  WriteResultStatusEnum.alreadyProcessed: 'already_processed',
  WriteResultStatusEnum.deferred_: 'deferred',
  WriteResultStatusEnum.conflict: 'conflict',
  WriteResultStatusEnum.failed: 'failed',
};
