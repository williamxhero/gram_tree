// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_complaint_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ShareComplaintInputCWProxy {
  ShareComplaintInput contact(String contact);

  ShareComplaintInput message(String message);

  ShareComplaintInput shareId(String? shareId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ShareComplaintInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ShareComplaintInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ShareComplaintInput call({String contact, String message, String? shareId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfShareComplaintInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfShareComplaintInput.copyWith.fieldName(...)`
class _$ShareComplaintInputCWProxyImpl implements _$ShareComplaintInputCWProxy {
  const _$ShareComplaintInputCWProxyImpl(this._value);

  final ShareComplaintInput _value;

  @override
  ShareComplaintInput contact(String contact) => this(contact: contact);

  @override
  ShareComplaintInput message(String message) => this(message: message);

  @override
  ShareComplaintInput shareId(String? shareId) => this(shareId: shareId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ShareComplaintInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ShareComplaintInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ShareComplaintInput call({
    Object? contact = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? shareId = const $CopyWithPlaceholder(),
  }) {
    return ShareComplaintInput(
      contact: contact == const $CopyWithPlaceholder()
          ? _value.contact
          // ignore: cast_nullable_to_non_nullable
          : contact as String,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
      shareId: shareId == const $CopyWithPlaceholder()
          ? _value.shareId
          // ignore: cast_nullable_to_non_nullable
          : shareId as String?,
    );
  }
}

extension $ShareComplaintInputCopyWith on ShareComplaintInput {
  /// Returns a callable class that can be used as follows: `instanceOfShareComplaintInput.copyWith(...)` or like so:`instanceOfShareComplaintInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ShareComplaintInputCWProxy get copyWith =>
      _$ShareComplaintInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShareComplaintInput _$ShareComplaintInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ShareComplaintInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['contact', 'message']);
      final val = ShareComplaintInput(
        contact: $checkedConvert('contact', (v) => v as String),
        message: $checkedConvert('message', (v) => v as String),
        shareId: $checkedConvert('share_id', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'shareId': 'share_id'});

Map<String, dynamic> _$ShareComplaintInputToJson(
  ShareComplaintInput instance,
) => <String, dynamic>{
  'contact': instance.contact,
  'message': instance.message,
  'share_id': ?instance.shareId,
};
