// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skip_adjustment_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkipAdjustmentRequestCWProxy {
  SkipAdjustmentRequest componentId(String componentId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SkipAdjustmentRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SkipAdjustmentRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  SkipAdjustmentRequest call({String componentId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSkipAdjustmentRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSkipAdjustmentRequest.copyWith.fieldName(...)`
class _$SkipAdjustmentRequestCWProxyImpl
    implements _$SkipAdjustmentRequestCWProxy {
  const _$SkipAdjustmentRequestCWProxyImpl(this._value);

  final SkipAdjustmentRequest _value;

  @override
  SkipAdjustmentRequest componentId(String componentId) =>
      this(componentId: componentId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SkipAdjustmentRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SkipAdjustmentRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  SkipAdjustmentRequest call({
    Object? componentId = const $CopyWithPlaceholder(),
  }) {
    return SkipAdjustmentRequest(
      componentId: componentId == const $CopyWithPlaceholder()
          ? _value.componentId
          // ignore: cast_nullable_to_non_nullable
          : componentId as String,
    );
  }
}

extension $SkipAdjustmentRequestCopyWith on SkipAdjustmentRequest {
  /// Returns a callable class that can be used as follows: `instanceOfSkipAdjustmentRequest.copyWith(...)` or like so:`instanceOfSkipAdjustmentRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SkipAdjustmentRequestCWProxy get copyWith =>
      _$SkipAdjustmentRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkipAdjustmentRequest _$SkipAdjustmentRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SkipAdjustmentRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['component_id']);
  final val = SkipAdjustmentRequest(
    componentId: $checkedConvert('component_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'componentId': 'component_id'});

Map<String, dynamic> _$SkipAdjustmentRequestToJson(
  SkipAdjustmentRequest instance,
) => <String, dynamic>{'component_id': instance.componentId};
