// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'captcha_verification_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CaptchaVerificationOutCWProxy {
  CaptchaVerificationOut accepted(bool accepted);

  CaptchaVerificationOut accessRestored(bool accessRestored);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CaptchaVerificationOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CaptchaVerificationOut(...).copyWith(id: 12, name: "My name")
  /// ````
  CaptchaVerificationOut call({bool accepted, bool accessRestored});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCaptchaVerificationOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCaptchaVerificationOut.copyWith.fieldName(...)`
class _$CaptchaVerificationOutCWProxyImpl
    implements _$CaptchaVerificationOutCWProxy {
  const _$CaptchaVerificationOutCWProxyImpl(this._value);

  final CaptchaVerificationOut _value;

  @override
  CaptchaVerificationOut accepted(bool accepted) => this(accepted: accepted);

  @override
  CaptchaVerificationOut accessRestored(bool accessRestored) =>
      this(accessRestored: accessRestored);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CaptchaVerificationOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CaptchaVerificationOut(...).copyWith(id: 12, name: "My name")
  /// ````
  CaptchaVerificationOut call({
    Object? accepted = const $CopyWithPlaceholder(),
    Object? accessRestored = const $CopyWithPlaceholder(),
  }) {
    return CaptchaVerificationOut(
      accepted: accepted == const $CopyWithPlaceholder()
          ? _value.accepted
          // ignore: cast_nullable_to_non_nullable
          : accepted as bool,
      accessRestored: accessRestored == const $CopyWithPlaceholder()
          ? _value.accessRestored
          // ignore: cast_nullable_to_non_nullable
          : accessRestored as bool,
    );
  }
}

extension $CaptchaVerificationOutCopyWith on CaptchaVerificationOut {
  /// Returns a callable class that can be used as follows: `instanceOfCaptchaVerificationOut.copyWith(...)` or like so:`instanceOfCaptchaVerificationOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CaptchaVerificationOutCWProxy get copyWith =>
      _$CaptchaVerificationOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CaptchaVerificationOut _$CaptchaVerificationOutFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CaptchaVerificationOut', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['accepted', 'access_restored']);
  final val = CaptchaVerificationOut(
    accepted: $checkedConvert('accepted', (v) => v as bool),
    accessRestored: $checkedConvert('access_restored', (v) => v as bool),
  );
  return val;
}, fieldKeyMap: const {'accessRestored': 'access_restored'});

Map<String, dynamic> _$CaptchaVerificationOutToJson(
  CaptchaVerificationOut instance,
) => <String, dynamic>{
  'accepted': instance.accepted,
  'access_restored': instance.accessRestored,
};
