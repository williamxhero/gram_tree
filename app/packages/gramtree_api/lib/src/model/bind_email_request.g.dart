// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bind_email_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BindEmailRequestCWProxy {
  BindEmailRequest code(String code);

  BindEmailRequest email(String email);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BindEmailRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BindEmailRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  BindEmailRequest call({String code, String email});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBindEmailRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBindEmailRequest.copyWith.fieldName(...)`
class _$BindEmailRequestCWProxyImpl implements _$BindEmailRequestCWProxy {
  const _$BindEmailRequestCWProxyImpl(this._value);

  final BindEmailRequest _value;

  @override
  BindEmailRequest code(String code) => this(code: code);

  @override
  BindEmailRequest email(String email) => this(email: email);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BindEmailRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BindEmailRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  BindEmailRequest call({
    Object? code = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
  }) {
    return BindEmailRequest(
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String,
    );
  }
}

extension $BindEmailRequestCopyWith on BindEmailRequest {
  /// Returns a callable class that can be used as follows: `instanceOfBindEmailRequest.copyWith(...)` or like so:`instanceOfBindEmailRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BindEmailRequestCWProxy get copyWith => _$BindEmailRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BindEmailRequest _$BindEmailRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BindEmailRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['code', 'email']);
      final val = BindEmailRequest(
        code: $checkedConvert('code', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$BindEmailRequestToJson(BindEmailRequest instance) =>
    <String, dynamic>{'code': instance.code, 'email': instance.email};
