// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_upload_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EventUploadRequestCWProxy {
  EventUploadRequest events(List<EventUploadItem> events);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EventUploadRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EventUploadRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  EventUploadRequest call({List<EventUploadItem> events});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEventUploadRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEventUploadRequest.copyWith.fieldName(...)`
class _$EventUploadRequestCWProxyImpl implements _$EventUploadRequestCWProxy {
  const _$EventUploadRequestCWProxyImpl(this._value);

  final EventUploadRequest _value;

  @override
  EventUploadRequest events(List<EventUploadItem> events) =>
      this(events: events);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EventUploadRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EventUploadRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  EventUploadRequest call({Object? events = const $CopyWithPlaceholder()}) {
    return EventUploadRequest(
      events: events == const $CopyWithPlaceholder()
          ? _value.events
          // ignore: cast_nullable_to_non_nullable
          : events as List<EventUploadItem>,
    );
  }
}

extension $EventUploadRequestCopyWith on EventUploadRequest {
  /// Returns a callable class that can be used as follows: `instanceOfEventUploadRequest.copyWith(...)` or like so:`instanceOfEventUploadRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EventUploadRequestCWProxy get copyWith =>
      _$EventUploadRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventUploadRequest _$EventUploadRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EventUploadRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['events']);
      final val = EventUploadRequest(
        events: $checkedConvert(
          'events',
          (v) => (v as List<dynamic>)
              .map((e) => EventUploadItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$EventUploadRequestToJson(EventUploadRequest instance) =>
    <String, dynamic>{
      'events': instance.events.map((e) => e.toJson()).toList(),
    };
