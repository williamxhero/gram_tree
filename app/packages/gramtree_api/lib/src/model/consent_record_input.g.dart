// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_record_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConsentRecordInputCWProxy {
  ConsentRecordInput action(ConsentRecordInputActionEnum action);

  ConsentRecordInput deviceId(String? deviceId);

  ConsentRecordInput id(String id);

  ConsentRecordInput kind(ConsentRecordInputKindEnum kind);

  ConsentRecordInput occurredAt(DateTime occurredAt);

  ConsentRecordInput version(String version);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ConsentRecordInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ConsentRecordInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ConsentRecordInput call({
    ConsentRecordInputActionEnum action,
    String? deviceId,
    String id,
    ConsentRecordInputKindEnum kind,
    DateTime occurredAt,
    String version,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfConsentRecordInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfConsentRecordInput.copyWith.fieldName(...)`
class _$ConsentRecordInputCWProxyImpl implements _$ConsentRecordInputCWProxy {
  const _$ConsentRecordInputCWProxyImpl(this._value);

  final ConsentRecordInput _value;

  @override
  ConsentRecordInput action(ConsentRecordInputActionEnum action) =>
      this(action: action);

  @override
  ConsentRecordInput deviceId(String? deviceId) => this(deviceId: deviceId);

  @override
  ConsentRecordInput id(String id) => this(id: id);

  @override
  ConsentRecordInput kind(ConsentRecordInputKindEnum kind) => this(kind: kind);

  @override
  ConsentRecordInput occurredAt(DateTime occurredAt) =>
      this(occurredAt: occurredAt);

  @override
  ConsentRecordInput version(String version) => this(version: version);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ConsentRecordInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ConsentRecordInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ConsentRecordInput call({
    Object? action = const $CopyWithPlaceholder(),
    Object? deviceId = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? occurredAt = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return ConsentRecordInput(
      action: action == const $CopyWithPlaceholder()
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as ConsentRecordInputActionEnum,
      deviceId: deviceId == const $CopyWithPlaceholder()
          ? _value.deviceId
          // ignore: cast_nullable_to_non_nullable
          : deviceId as String?,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as ConsentRecordInputKindEnum,
      occurredAt: occurredAt == const $CopyWithPlaceholder()
          ? _value.occurredAt
          // ignore: cast_nullable_to_non_nullable
          : occurredAt as DateTime,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String,
    );
  }
}

extension $ConsentRecordInputCopyWith on ConsentRecordInput {
  /// Returns a callable class that can be used as follows: `instanceOfConsentRecordInput.copyWith(...)` or like so:`instanceOfConsentRecordInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConsentRecordInputCWProxy get copyWith =>
      _$ConsentRecordInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConsentRecordInput _$ConsentRecordInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ConsentRecordInput', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['action', 'id', 'kind', 'occurred_at', 'version'],
  );
  final val = ConsentRecordInput(
    action: $checkedConvert(
      'action',
      (v) => $enumDecode(_$ConsentRecordInputActionEnumEnumMap, v),
    ),
    deviceId: $checkedConvert('device_id', (v) => v as String?),
    id: $checkedConvert('id', (v) => v as String),
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$ConsentRecordInputKindEnumEnumMap, v),
    ),
    occurredAt: $checkedConvert(
      'occurred_at',
      (v) => DateTime.parse(v as String),
    ),
    version: $checkedConvert('version', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'deviceId': 'device_id', 'occurredAt': 'occurred_at'});

Map<String, dynamic> _$ConsentRecordInputToJson(ConsentRecordInput instance) =>
    <String, dynamic>{
      'action': _$ConsentRecordInputActionEnumEnumMap[instance.action]!,
      'device_id': ?instance.deviceId,
      'id': instance.id,
      'kind': _$ConsentRecordInputKindEnumEnumMap[instance.kind]!,
      'occurred_at': instance.occurredAt.toIso8601String(),
      'version': instance.version,
    };

const _$ConsentRecordInputActionEnumEnumMap = {
  ConsentRecordInputActionEnum.agree: 'agree',
  ConsentRecordInputActionEnum.withdraw: 'withdraw',
};

const _$ConsentRecordInputKindEnumEnumMap = {
  ConsentRecordInputKindEnum.terms: 'terms',
  ConsentRecordInputKindEnum.privacy: 'privacy',
  ConsentRecordInputKindEnum.sensitivePersonalInfo: 'sensitive_personal_info',
  ConsentRecordInputKindEnum.productAnalytics: 'product_analytics',
};
