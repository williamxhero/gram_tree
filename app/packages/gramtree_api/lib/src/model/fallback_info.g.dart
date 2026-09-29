// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fallback_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FallbackInfoCWProxy {
  FallbackInfo reasonCode(FallbackInfoReasonCodeEnum reasonCode);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FallbackInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FallbackInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  FallbackInfo call({FallbackInfoReasonCodeEnum reasonCode});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFallbackInfo.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFallbackInfo.copyWith.fieldName(...)`
class _$FallbackInfoCWProxyImpl implements _$FallbackInfoCWProxy {
  const _$FallbackInfoCWProxyImpl(this._value);

  final FallbackInfo _value;

  @override
  FallbackInfo reasonCode(FallbackInfoReasonCodeEnum reasonCode) =>
      this(reasonCode: reasonCode);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FallbackInfo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FallbackInfo(...).copyWith(id: 12, name: "My name")
  /// ````
  FallbackInfo call({Object? reasonCode = const $CopyWithPlaceholder()}) {
    return FallbackInfo(
      reasonCode: reasonCode == const $CopyWithPlaceholder()
          ? _value.reasonCode
          // ignore: cast_nullable_to_non_nullable
          : reasonCode as FallbackInfoReasonCodeEnum,
    );
  }
}

extension $FallbackInfoCopyWith on FallbackInfo {
  /// Returns a callable class that can be used as follows: `instanceOfFallbackInfo.copyWith(...)` or like so:`instanceOfFallbackInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FallbackInfoCWProxy get copyWith => _$FallbackInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FallbackInfo _$FallbackInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FallbackInfo', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['reason_code']);
      final val = FallbackInfo(
        reasonCode: $checkedConvert(
          'reason_code',
          (v) => $enumDecode(_$FallbackInfoReasonCodeEnumEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'reasonCode': 'reason_code'});

Map<String, dynamic> _$FallbackInfoToJson(FallbackInfo instance) =>
    <String, dynamic>{
      'reason_code': _$FallbackInfoReasonCodeEnumEnumMap[instance.reasonCode]!,
    };

const _$FallbackInfoReasonCodeEnumEnumMap = {
  FallbackInfoReasonCodeEnum.unknownMajor: 'unknown_major',
  FallbackInfoReasonCodeEnum.unknownComponent: 'unknown_component',
  FallbackInfoReasonCodeEnum.illegalAction: 'illegal_action',
  FallbackInfoReasonCodeEnum.invalidData: 'invalid_data',
  FallbackInfoReasonCodeEnum.missingRequired: 'missing_required',
  FallbackInfoReasonCodeEnum.serverError: 'server_error',
  FallbackInfoReasonCodeEnum.timeout: 'timeout',
};
