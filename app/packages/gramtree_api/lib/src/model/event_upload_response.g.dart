// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_upload_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EventUploadResponseCWProxy {
  EventUploadResponse results(List<EventUploadResultItem> results);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EventUploadResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EventUploadResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  EventUploadResponse call({List<EventUploadResultItem> results});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEventUploadResponse.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEventUploadResponse.copyWith.fieldName(...)`
class _$EventUploadResponseCWProxyImpl implements _$EventUploadResponseCWProxy {
  const _$EventUploadResponseCWProxyImpl(this._value);

  final EventUploadResponse _value;

  @override
  EventUploadResponse results(List<EventUploadResultItem> results) =>
      this(results: results);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EventUploadResponse(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EventUploadResponse(...).copyWith(id: 12, name: "My name")
  /// ````
  EventUploadResponse call({Object? results = const $CopyWithPlaceholder()}) {
    return EventUploadResponse(
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<EventUploadResultItem>,
    );
  }
}

extension $EventUploadResponseCopyWith on EventUploadResponse {
  /// Returns a callable class that can be used as follows: `instanceOfEventUploadResponse.copyWith(...)` or like so:`instanceOfEventUploadResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EventUploadResponseCWProxy get copyWith =>
      _$EventUploadResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventUploadResponse _$EventUploadResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EventUploadResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['results']);
      final val = EventUploadResponse(
        results: $checkedConvert(
          'results',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    EventUploadResultItem.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$EventUploadResponseToJson(
  EventUploadResponse instance,
) => <String, dynamic>{
  'results': instance.results.map((e) => e.toJson()).toList(),
};
