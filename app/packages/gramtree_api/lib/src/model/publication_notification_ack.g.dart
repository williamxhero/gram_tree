// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publication_notification_ack.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicationNotificationAckCWProxy {
  PublicationNotificationAck licenseSeen(bool? licenseSeen);

  PublicationNotificationAck notificationIds(List<String>? notificationIds);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicationNotificationAck(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicationNotificationAck(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicationNotificationAck call({
    bool? licenseSeen,
    List<String>? notificationIds,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicationNotificationAck.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicationNotificationAck.copyWith.fieldName(...)`
class _$PublicationNotificationAckCWProxyImpl
    implements _$PublicationNotificationAckCWProxy {
  const _$PublicationNotificationAckCWProxyImpl(this._value);

  final PublicationNotificationAck _value;

  @override
  PublicationNotificationAck licenseSeen(bool? licenseSeen) =>
      this(licenseSeen: licenseSeen);

  @override
  PublicationNotificationAck notificationIds(List<String>? notificationIds) =>
      this(notificationIds: notificationIds);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicationNotificationAck(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicationNotificationAck(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicationNotificationAck call({
    Object? licenseSeen = const $CopyWithPlaceholder(),
    Object? notificationIds = const $CopyWithPlaceholder(),
  }) {
    return PublicationNotificationAck(
      licenseSeen: licenseSeen == const $CopyWithPlaceholder()
          ? _value.licenseSeen
          // ignore: cast_nullable_to_non_nullable
          : licenseSeen as bool?,
      notificationIds: notificationIds == const $CopyWithPlaceholder()
          ? _value.notificationIds
          // ignore: cast_nullable_to_non_nullable
          : notificationIds as List<String>?,
    );
  }
}

extension $PublicationNotificationAckCopyWith on PublicationNotificationAck {
  /// Returns a callable class that can be used as follows: `instanceOfPublicationNotificationAck.copyWith(...)` or like so:`instanceOfPublicationNotificationAck.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicationNotificationAckCWProxy get copyWith =>
      _$PublicationNotificationAckCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicationNotificationAck _$PublicationNotificationAckFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PublicationNotificationAck',
  json,
  ($checkedConvert) {
    final val = PublicationNotificationAck(
      licenseSeen: $checkedConvert('license_seen', (v) => v as bool? ?? false),
      notificationIds: $checkedConvert(
        'notification_ids',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'licenseSeen': 'license_seen',
    'notificationIds': 'notification_ids',
  },
);

Map<String, dynamic> _$PublicationNotificationAckToJson(
  PublicationNotificationAck instance,
) => <String, dynamic>{
  'license_seen': ?instance.licenseSeen,
  'notification_ids': ?instance.notificationIds,
};
