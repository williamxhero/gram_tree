// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publication_notification_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicationNotificationOutCWProxy {
  PublicationNotificationOut id(String id);

  PublicationNotificationOut message(String message);

  PublicationNotificationOut recipeId(String recipeId);

  PublicationNotificationOut title(String title);

  PublicationNotificationOut versionId(String versionId);

  PublicationNotificationOut versionNumber(int versionNumber);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicationNotificationOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicationNotificationOut(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicationNotificationOut call({
    String id,
    String message,
    String recipeId,
    String title,
    String versionId,
    int versionNumber,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicationNotificationOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicationNotificationOut.copyWith.fieldName(...)`
class _$PublicationNotificationOutCWProxyImpl
    implements _$PublicationNotificationOutCWProxy {
  const _$PublicationNotificationOutCWProxyImpl(this._value);

  final PublicationNotificationOut _value;

  @override
  PublicationNotificationOut id(String id) => this(id: id);

  @override
  PublicationNotificationOut message(String message) => this(message: message);

  @override
  PublicationNotificationOut recipeId(String recipeId) =>
      this(recipeId: recipeId);

  @override
  PublicationNotificationOut title(String title) => this(title: title);

  @override
  PublicationNotificationOut versionId(String versionId) =>
      this(versionId: versionId);

  @override
  PublicationNotificationOut versionNumber(int versionNumber) =>
      this(versionNumber: versionNumber);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicationNotificationOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicationNotificationOut(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicationNotificationOut call({
    Object? id = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? recipeId = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? versionId = const $CopyWithPlaceholder(),
    Object? versionNumber = const $CopyWithPlaceholder(),
  }) {
    return PublicationNotificationOut(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
      recipeId: recipeId == const $CopyWithPlaceholder()
          ? _value.recipeId
          // ignore: cast_nullable_to_non_nullable
          : recipeId as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      versionId: versionId == const $CopyWithPlaceholder()
          ? _value.versionId
          // ignore: cast_nullable_to_non_nullable
          : versionId as String,
      versionNumber: versionNumber == const $CopyWithPlaceholder()
          ? _value.versionNumber
          // ignore: cast_nullable_to_non_nullable
          : versionNumber as int,
    );
  }
}

extension $PublicationNotificationOutCopyWith on PublicationNotificationOut {
  /// Returns a callable class that can be used as follows: `instanceOfPublicationNotificationOut.copyWith(...)` or like so:`instanceOfPublicationNotificationOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicationNotificationOutCWProxy get copyWith =>
      _$PublicationNotificationOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicationNotificationOut _$PublicationNotificationOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PublicationNotificationOut',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'message',
        'recipe_id',
        'title',
        'version_id',
        'version_number',
      ],
    );
    final val = PublicationNotificationOut(
      id: $checkedConvert('id', (v) => v as String),
      message: $checkedConvert('message', (v) => v as String),
      recipeId: $checkedConvert('recipe_id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      versionId: $checkedConvert('version_id', (v) => v as String),
      versionNumber: $checkedConvert(
        'version_number',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'recipeId': 'recipe_id',
    'versionId': 'version_id',
    'versionNumber': 'version_number',
  },
);

Map<String, dynamic> _$PublicationNotificationOutToJson(
  PublicationNotificationOut instance,
) => <String, dynamic>{
  'id': instance.id,
  'message': instance.message,
  'recipe_id': instance.recipeId,
  'title': instance.title,
  'version_id': instance.versionId,
  'version_number': instance.versionNumber,
};
