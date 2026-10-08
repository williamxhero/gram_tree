// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'write_resource_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WriteResourceResultCWProxy {
  WriteResourceResult resourceId(String resourceId);

  WriteResourceResult resourceType(String resourceType);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `WriteResourceResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// WriteResourceResult(...).copyWith(id: 12, name: "My name")
  /// ````
  WriteResourceResult call({String resourceId, String resourceType});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfWriteResourceResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfWriteResourceResult.copyWith.fieldName(...)`
class _$WriteResourceResultCWProxyImpl implements _$WriteResourceResultCWProxy {
  const _$WriteResourceResultCWProxyImpl(this._value);

  final WriteResourceResult _value;

  @override
  WriteResourceResult resourceId(String resourceId) =>
      this(resourceId: resourceId);

  @override
  WriteResourceResult resourceType(String resourceType) =>
      this(resourceType: resourceType);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `WriteResourceResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// WriteResourceResult(...).copyWith(id: 12, name: "My name")
  /// ````
  WriteResourceResult call({
    Object? resourceId = const $CopyWithPlaceholder(),
    Object? resourceType = const $CopyWithPlaceholder(),
  }) {
    return WriteResourceResult(
      resourceId: resourceId == const $CopyWithPlaceholder()
          ? _value.resourceId
          // ignore: cast_nullable_to_non_nullable
          : resourceId as String,
      resourceType: resourceType == const $CopyWithPlaceholder()
          ? _value.resourceType
          // ignore: cast_nullable_to_non_nullable
          : resourceType as String,
    );
  }
}

extension $WriteResourceResultCopyWith on WriteResourceResult {
  /// Returns a callable class that can be used as follows: `instanceOfWriteResourceResult.copyWith(...)` or like so:`instanceOfWriteResourceResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WriteResourceResultCWProxy get copyWith =>
      _$WriteResourceResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WriteResourceResult _$WriteResourceResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'WriteResourceResult',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['resource_id', 'resource_type']);
        final val = WriteResourceResult(
          resourceId: $checkedConvert('resource_id', (v) => v as String),
          resourceType: $checkedConvert('resource_type', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'resourceId': 'resource_id',
        'resourceType': 'resource_type',
      },
    );

Map<String, dynamic> _$WriteResourceResultToJson(
  WriteResourceResult instance,
) => <String, dynamic>{
  'resource_id': instance.resourceId,
  'resource_type': instance.resourceType,
};
