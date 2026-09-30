// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_upload_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AnalyticsUploadRequestCWProxy {
  AnalyticsUploadRequest events(List<AnalyticsEventIn> events);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AnalyticsUploadRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AnalyticsUploadRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AnalyticsUploadRequest call({List<AnalyticsEventIn> events});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAnalyticsUploadRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAnalyticsUploadRequest.copyWith.fieldName(...)`
class _$AnalyticsUploadRequestCWProxyImpl
    implements _$AnalyticsUploadRequestCWProxy {
  const _$AnalyticsUploadRequestCWProxyImpl(this._value);

  final AnalyticsUploadRequest _value;

  @override
  AnalyticsUploadRequest events(List<AnalyticsEventIn> events) =>
      this(events: events);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AnalyticsUploadRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AnalyticsUploadRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  AnalyticsUploadRequest call({Object? events = const $CopyWithPlaceholder()}) {
    return AnalyticsUploadRequest(
      events: events == const $CopyWithPlaceholder()
          ? _value.events
          // ignore: cast_nullable_to_non_nullable
          : events as List<AnalyticsEventIn>,
    );
  }
}

extension $AnalyticsUploadRequestCopyWith on AnalyticsUploadRequest {
  /// Returns a callable class that can be used as follows: `instanceOfAnalyticsUploadRequest.copyWith(...)` or like so:`instanceOfAnalyticsUploadRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AnalyticsUploadRequestCWProxy get copyWith =>
      _$AnalyticsUploadRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyticsUploadRequest _$AnalyticsUploadRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AnalyticsUploadRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['events']);
  final val = AnalyticsUploadRequest(
    events: $checkedConvert(
      'events',
      (v) => (v as List<dynamic>)
          .map((e) => AnalyticsEventIn.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$AnalyticsUploadRequestToJson(
  AnalyticsUploadRequest instance,
) => <String, dynamic>{
  'events': instance.events.map((e) => e.toJson()).toList(),
};
