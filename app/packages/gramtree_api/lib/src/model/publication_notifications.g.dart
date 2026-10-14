// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publication_notifications.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicationNotificationsCWProxy {
  PublicationNotifications items(List<PublicationNotificationOut>? items);

  PublicationNotifications licenseNotice(String? licenseNotice);

  PublicationNotifications nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicationNotifications(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicationNotifications(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicationNotifications call({
    List<PublicationNotificationOut>? items,
    String? licenseNotice,
    String? nextCursor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicationNotifications.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicationNotifications.copyWith.fieldName(...)`
class _$PublicationNotificationsCWProxyImpl
    implements _$PublicationNotificationsCWProxy {
  const _$PublicationNotificationsCWProxyImpl(this._value);

  final PublicationNotifications _value;

  @override
  PublicationNotifications items(List<PublicationNotificationOut>? items) =>
      this(items: items);

  @override
  PublicationNotifications licenseNotice(String? licenseNotice) =>
      this(licenseNotice: licenseNotice);

  @override
  PublicationNotifications nextCursor(String? nextCursor) =>
      this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicationNotifications(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicationNotifications(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicationNotifications call({
    Object? items = const $CopyWithPlaceholder(),
    Object? licenseNotice = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return PublicationNotifications(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PublicationNotificationOut>?,
      licenseNotice: licenseNotice == const $CopyWithPlaceholder()
          ? _value.licenseNotice
          // ignore: cast_nullable_to_non_nullable
          : licenseNotice as String?,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $PublicationNotificationsCopyWith on PublicationNotifications {
  /// Returns a callable class that can be used as follows: `instanceOfPublicationNotifications.copyWith(...)` or like so:`instanceOfPublicationNotifications.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicationNotificationsCWProxy get copyWith =>
      _$PublicationNotificationsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicationNotifications _$PublicationNotificationsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PublicationNotifications',
  json,
  ($checkedConvert) {
    final val = PublicationNotifications(
      items: $checkedConvert(
        'items',
        (v) => (v as List<dynamic>?)
            ?.map(
              (e) => PublicationNotificationOut.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(),
      ),
      licenseNotice: $checkedConvert('license_notice', (v) => v as String?),
      nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'licenseNotice': 'license_notice',
    'nextCursor': 'next_cursor',
  },
);

Map<String, dynamic> _$PublicationNotificationsToJson(
  PublicationNotifications instance,
) => <String, dynamic>{
  'items': ?instance.items?.map((e) => e.toJson()).toList(),
  'license_notice': ?instance.licenseNotice,
  'next_cursor': ?instance.nextCursor,
};
