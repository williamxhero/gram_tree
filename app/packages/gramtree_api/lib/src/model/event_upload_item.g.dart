// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_upload_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EventUploadItemCWProxy {
  EventUploadItem appVersion(String appVersion);

  EventUploadItem content(Map<String, Object>? content);

  EventUploadItem correlation(EventCorrelationIds? correlation);

  EventUploadItem deviceId(String deviceId);

  EventUploadItem deviceTime(DateTime deviceTime);

  EventUploadItem eventType(String eventType);

  EventUploadItem id(String id);

  EventUploadItem typeVersion(int typeVersion);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EventUploadItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EventUploadItem(...).copyWith(id: 12, name: "My name")
  /// ````
  EventUploadItem call({
    String appVersion,
    Map<String, Object>? content,
    EventCorrelationIds? correlation,
    String deviceId,
    DateTime deviceTime,
    String eventType,
    String id,
    int typeVersion,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEventUploadItem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEventUploadItem.copyWith.fieldName(...)`
class _$EventUploadItemCWProxyImpl implements _$EventUploadItemCWProxy {
  const _$EventUploadItemCWProxyImpl(this._value);

  final EventUploadItem _value;

  @override
  EventUploadItem appVersion(String appVersion) => this(appVersion: appVersion);

  @override
  EventUploadItem content(Map<String, Object>? content) =>
      this(content: content);

  @override
  EventUploadItem correlation(EventCorrelationIds? correlation) =>
      this(correlation: correlation);

  @override
  EventUploadItem deviceId(String deviceId) => this(deviceId: deviceId);

  @override
  EventUploadItem deviceTime(DateTime deviceTime) =>
      this(deviceTime: deviceTime);

  @override
  EventUploadItem eventType(String eventType) => this(eventType: eventType);

  @override
  EventUploadItem id(String id) => this(id: id);

  @override
  EventUploadItem typeVersion(int typeVersion) =>
      this(typeVersion: typeVersion);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EventUploadItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EventUploadItem(...).copyWith(id: 12, name: "My name")
  /// ````
  EventUploadItem call({
    Object? appVersion = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
    Object? correlation = const $CopyWithPlaceholder(),
    Object? deviceId = const $CopyWithPlaceholder(),
    Object? deviceTime = const $CopyWithPlaceholder(),
    Object? eventType = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? typeVersion = const $CopyWithPlaceholder(),
  }) {
    return EventUploadItem(
      appVersion: appVersion == const $CopyWithPlaceholder()
          ? _value.appVersion
          // ignore: cast_nullable_to_non_nullable
          : appVersion as String,
      content: content == const $CopyWithPlaceholder()
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as Map<String, Object>?,
      correlation: correlation == const $CopyWithPlaceholder()
          ? _value.correlation
          // ignore: cast_nullable_to_non_nullable
          : correlation as EventCorrelationIds?,
      deviceId: deviceId == const $CopyWithPlaceholder()
          ? _value.deviceId
          // ignore: cast_nullable_to_non_nullable
          : deviceId as String,
      deviceTime: deviceTime == const $CopyWithPlaceholder()
          ? _value.deviceTime
          // ignore: cast_nullable_to_non_nullable
          : deviceTime as DateTime,
      eventType: eventType == const $CopyWithPlaceholder()
          ? _value.eventType
          // ignore: cast_nullable_to_non_nullable
          : eventType as String,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      typeVersion: typeVersion == const $CopyWithPlaceholder()
          ? _value.typeVersion
          // ignore: cast_nullable_to_non_nullable
          : typeVersion as int,
    );
  }
}

extension $EventUploadItemCopyWith on EventUploadItem {
  /// Returns a callable class that can be used as follows: `instanceOfEventUploadItem.copyWith(...)` or like so:`instanceOfEventUploadItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EventUploadItemCWProxy get copyWith => _$EventUploadItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventUploadItem _$EventUploadItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'EventUploadItem',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'app_version',
            'device_id',
            'device_time',
            'event_type',
            'id',
            'type_version',
          ],
        );
        final val = EventUploadItem(
          appVersion: $checkedConvert('app_version', (v) => v as String),
          content: $checkedConvert(
            'content',
            (v) => (v as Map<String, dynamic>?)?.map(
              (k, e) => MapEntry(k, e as Object),
            ),
          ),
          correlation: $checkedConvert(
            'correlation',
            (v) => v == null
                ? null
                : EventCorrelationIds.fromJson(v as Map<String, dynamic>),
          ),
          deviceId: $checkedConvert('device_id', (v) => v as String),
          deviceTime: $checkedConvert(
            'device_time',
            (v) => DateTime.parse(v as String),
          ),
          eventType: $checkedConvert('event_type', (v) => v as String),
          id: $checkedConvert('id', (v) => v as String),
          typeVersion: $checkedConvert(
            'type_version',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'appVersion': 'app_version',
        'deviceId': 'device_id',
        'deviceTime': 'device_time',
        'eventType': 'event_type',
        'typeVersion': 'type_version',
      },
    );

Map<String, dynamic> _$EventUploadItemToJson(EventUploadItem instance) =>
    <String, dynamic>{
      'app_version': instance.appVersion,
      'content': ?instance.content,
      'correlation': ?instance.correlation?.toJson(),
      'device_id': instance.deviceId,
      'device_time': instance.deviceTime.toIso8601String(),
      'event_type': instance.eventType,
      'id': instance.id,
      'type_version': instance.typeVersion,
    };
