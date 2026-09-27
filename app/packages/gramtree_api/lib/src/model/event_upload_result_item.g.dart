// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_upload_result_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$EventUploadResultItemCWProxy {
  EventUploadResultItem id(String id);

  EventUploadResultItem reason(RejectionReason? reason);

  EventUploadResultItem status(EventUploadResultItemStatusEnum status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EventUploadResultItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EventUploadResultItem(...).copyWith(id: 12, name: "My name")
  /// ````
  EventUploadResultItem call({
    String id,
    RejectionReason? reason,
    EventUploadResultItemStatusEnum status,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfEventUploadResultItem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfEventUploadResultItem.copyWith.fieldName(...)`
class _$EventUploadResultItemCWProxyImpl
    implements _$EventUploadResultItemCWProxy {
  const _$EventUploadResultItemCWProxyImpl(this._value);

  final EventUploadResultItem _value;

  @override
  EventUploadResultItem id(String id) => this(id: id);

  @override
  EventUploadResultItem reason(RejectionReason? reason) => this(reason: reason);

  @override
  EventUploadResultItem status(EventUploadResultItemStatusEnum status) =>
      this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `EventUploadResultItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// EventUploadResultItem(...).copyWith(id: 12, name: "My name")
  /// ````
  EventUploadResultItem call({
    Object? id = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return EventUploadResultItem(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as RejectionReason?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as EventUploadResultItemStatusEnum,
    );
  }
}

extension $EventUploadResultItemCopyWith on EventUploadResultItem {
  /// Returns a callable class that can be used as follows: `instanceOfEventUploadResultItem.copyWith(...)` or like so:`instanceOfEventUploadResultItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$EventUploadResultItemCWProxy get copyWith =>
      _$EventUploadResultItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventUploadResultItem _$EventUploadResultItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('EventUploadResultItem', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'status']);
  final val = EventUploadResultItem(
    id: $checkedConvert('id', (v) => v as String),
    reason: $checkedConvert(
      'reason',
      (v) => v == null
          ? null
          : RejectionReason.fromJson(v as Map<String, dynamic>),
    ),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$EventUploadResultItemStatusEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$EventUploadResultItemToJson(
  EventUploadResultItem instance,
) => <String, dynamic>{
  'id': instance.id,
  'reason': ?instance.reason?.toJson(),
  'status': _$EventUploadResultItemStatusEnumEnumMap[instance.status]!,
};

const _$EventUploadResultItemStatusEnumEnumMap = {
  EventUploadResultItemStatusEnum.accepted: 'accepted',
  EventUploadResultItemStatusEnum.duplicate: 'duplicate',
  EventUploadResultItemStatusEnum.rejected: 'rejected',
};
