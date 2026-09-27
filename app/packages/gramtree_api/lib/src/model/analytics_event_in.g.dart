// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_event_in.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AnalyticsEventInCWProxy {
  AnalyticsEventIn deviceId(String? deviceId);

  AnalyticsEventIn durationMs(int? durationMs);

  AnalyticsEventIn eventType(AnalyticsEventInEventTypeEnum eventType);

  AnalyticsEventIn id(String id);

  AnalyticsEventIn occurredAt(DateTime occurredAt);

  AnalyticsEventIn target(String target);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AnalyticsEventIn(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AnalyticsEventIn(...).copyWith(id: 12, name: "My name")
  /// ````
  AnalyticsEventIn call({
    String? deviceId,
    int? durationMs,
    AnalyticsEventInEventTypeEnum eventType,
    String id,
    DateTime occurredAt,
    String target,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAnalyticsEventIn.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAnalyticsEventIn.copyWith.fieldName(...)`
class _$AnalyticsEventInCWProxyImpl implements _$AnalyticsEventInCWProxy {
  const _$AnalyticsEventInCWProxyImpl(this._value);

  final AnalyticsEventIn _value;

  @override
  AnalyticsEventIn deviceId(String? deviceId) => this(deviceId: deviceId);

  @override
  AnalyticsEventIn durationMs(int? durationMs) => this(durationMs: durationMs);

  @override
  AnalyticsEventIn eventType(AnalyticsEventInEventTypeEnum eventType) =>
      this(eventType: eventType);

  @override
  AnalyticsEventIn id(String id) => this(id: id);

  @override
  AnalyticsEventIn occurredAt(DateTime occurredAt) =>
      this(occurredAt: occurredAt);

  @override
  AnalyticsEventIn target(String target) => this(target: target);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AnalyticsEventIn(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AnalyticsEventIn(...).copyWith(id: 12, name: "My name")
  /// ````
  AnalyticsEventIn call({
    Object? deviceId = const $CopyWithPlaceholder(),
    Object? durationMs = const $CopyWithPlaceholder(),
    Object? eventType = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? occurredAt = const $CopyWithPlaceholder(),
    Object? target = const $CopyWithPlaceholder(),
  }) {
    return AnalyticsEventIn(
      deviceId: deviceId == const $CopyWithPlaceholder()
          ? _value.deviceId
          // ignore: cast_nullable_to_non_nullable
          : deviceId as String?,
      durationMs: durationMs == const $CopyWithPlaceholder()
          ? _value.durationMs
          // ignore: cast_nullable_to_non_nullable
          : durationMs as int?,
      eventType: eventType == const $CopyWithPlaceholder()
          ? _value.eventType
          // ignore: cast_nullable_to_non_nullable
          : eventType as AnalyticsEventInEventTypeEnum,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      occurredAt: occurredAt == const $CopyWithPlaceholder()
          ? _value.occurredAt
          // ignore: cast_nullable_to_non_nullable
          : occurredAt as DateTime,
      target: target == const $CopyWithPlaceholder()
          ? _value.target
          // ignore: cast_nullable_to_non_nullable
          : target as String,
    );
  }
}

extension $AnalyticsEventInCopyWith on AnalyticsEventIn {
  /// Returns a callable class that can be used as follows: `instanceOfAnalyticsEventIn.copyWith(...)` or like so:`instanceOfAnalyticsEventIn.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AnalyticsEventInCWProxy get copyWith => _$AnalyticsEventInCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyticsEventIn _$AnalyticsEventInFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AnalyticsEventIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['event_type', 'id', 'occurred_at', 'target'],
        );
        final val = AnalyticsEventIn(
          deviceId: $checkedConvert('device_id', (v) => v as String?),
          durationMs: $checkedConvert(
            'duration_ms',
            (v) => (v as num?)?.toInt(),
          ),
          eventType: $checkedConvert(
            'event_type',
            (v) => $enumDecode(_$AnalyticsEventInEventTypeEnumEnumMap, v),
          ),
          id: $checkedConvert('id', (v) => v as String),
          occurredAt: $checkedConvert(
            'occurred_at',
            (v) => DateTime.parse(v as String),
          ),
          target: $checkedConvert('target', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'deviceId': 'device_id',
        'durationMs': 'duration_ms',
        'eventType': 'event_type',
        'occurredAt': 'occurred_at',
      },
    );

Map<String, dynamic> _$AnalyticsEventInToJson(AnalyticsEventIn instance) =>
    <String, dynamic>{
      'device_id': ?instance.deviceId,
      'duration_ms': ?instance.durationMs,
      'event_type': _$AnalyticsEventInEventTypeEnumEnumMap[instance.eventType]!,
      'id': instance.id,
      'occurred_at': instance.occurredAt.toIso8601String(),
      'target': instance.target,
    };

const _$AnalyticsEventInEventTypeEnumEnumMap = {
  AnalyticsEventInEventTypeEnum.pageView: 'page_view',
  AnalyticsEventInEventTypeEnum.tap: 'tap',
  AnalyticsEventInEventTypeEnum.loadDuration: 'load_duration',
};
