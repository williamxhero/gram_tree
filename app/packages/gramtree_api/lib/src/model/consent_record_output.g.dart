// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_record_output.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConsentRecordOutputCWProxy {
  ConsentRecordOutput action(ConsentRecordOutputActionEnum action);

  ConsentRecordOutput deviceId(String? deviceId);

  ConsentRecordOutput id(String id);

  ConsentRecordOutput kind(ConsentRecordOutputKindEnum kind);

  ConsentRecordOutput occurredAt(String occurredAt);

  ConsentRecordOutput version(String version);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ConsentRecordOutput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ConsentRecordOutput(...).copyWith(id: 12, name: "My name")
  /// ````
  ConsentRecordOutput call({
    ConsentRecordOutputActionEnum action,
    String? deviceId,
    String id,
    ConsentRecordOutputKindEnum kind,
    String occurredAt,
    String version,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfConsentRecordOutput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfConsentRecordOutput.copyWith.fieldName(...)`
class _$ConsentRecordOutputCWProxyImpl implements _$ConsentRecordOutputCWProxy {
  const _$ConsentRecordOutputCWProxyImpl(this._value);

  final ConsentRecordOutput _value;

  @override
  ConsentRecordOutput action(ConsentRecordOutputActionEnum action) =>
      this(action: action);

  @override
  ConsentRecordOutput deviceId(String? deviceId) => this(deviceId: deviceId);

  @override
  ConsentRecordOutput id(String id) => this(id: id);

  @override
  ConsentRecordOutput kind(ConsentRecordOutputKindEnum kind) =>
      this(kind: kind);

  @override
  ConsentRecordOutput occurredAt(String occurredAt) =>
      this(occurredAt: occurredAt);

  @override
  ConsentRecordOutput version(String version) => this(version: version);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ConsentRecordOutput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ConsentRecordOutput(...).copyWith(id: 12, name: "My name")
  /// ````
  ConsentRecordOutput call({
    Object? action = const $CopyWithPlaceholder(),
    Object? deviceId = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? occurredAt = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return ConsentRecordOutput(
      action: action == const $CopyWithPlaceholder()
          ? _value.action
          // ignore: cast_nullable_to_non_nullable
          : action as ConsentRecordOutputActionEnum,
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
          : kind as ConsentRecordOutputKindEnum,
      occurredAt: occurredAt == const $CopyWithPlaceholder()
          ? _value.occurredAt
          // ignore: cast_nullable_to_non_nullable
          : occurredAt as String,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String,
    );
  }
}

extension $ConsentRecordOutputCopyWith on ConsentRecordOutput {
  /// Returns a callable class that can be used as follows: `instanceOfConsentRecordOutput.copyWith(...)` or like so:`instanceOfConsentRecordOutput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConsentRecordOutputCWProxy get copyWith =>
      _$ConsentRecordOutputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConsentRecordOutput _$ConsentRecordOutputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ConsentRecordOutput', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['action', 'id', 'kind', 'occurred_at', 'version'],
  );
  final val = ConsentRecordOutput(
    action: $checkedConvert(
      'action',
      (v) => $enumDecode(_$ConsentRecordOutputActionEnumEnumMap, v),
    ),
    deviceId: $checkedConvert('device_id', (v) => v as String?),
    id: $checkedConvert('id', (v) => v as String),
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$ConsentRecordOutputKindEnumEnumMap, v),
    ),
    occurredAt: $checkedConvert('occurred_at', (v) => v as String),
    version: $checkedConvert('version', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'deviceId': 'device_id', 'occurredAt': 'occurred_at'});

Map<String, dynamic> _$ConsentRecordOutputToJson(
  ConsentRecordOutput instance,
) => <String, dynamic>{
  'action': _$ConsentRecordOutputActionEnumEnumMap[instance.action]!,
  'device_id': ?instance.deviceId,
  'id': instance.id,
  'kind': _$ConsentRecordOutputKindEnumEnumMap[instance.kind]!,
  'occurred_at': instance.occurredAt,
  'version': instance.version,
};

const _$ConsentRecordOutputActionEnumEnumMap = {
  ConsentRecordOutputActionEnum.agree: 'agree',
  ConsentRecordOutputActionEnum.withdraw: 'withdraw',
};

const _$ConsentRecordOutputKindEnumEnumMap = {
  ConsentRecordOutputKindEnum.terms: 'terms',
  ConsentRecordOutputKindEnum.privacy: 'privacy',
  ConsentRecordOutputKindEnum.sensitivePersonalInfo: 'sensitive_personal_info',
  ConsentRecordOutputKindEnum.productAnalytics: 'product_analytics',
};
