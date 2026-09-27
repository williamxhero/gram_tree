// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_update.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProfileUpdateCWProxy {
  ProfileUpdate nickname(String? nickname);

  ProfileUpdate timezone(String? timezone);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ProfileUpdate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ProfileUpdate(...).copyWith(id: 12, name: "My name")
  /// ````
  ProfileUpdate call({String? nickname, String? timezone});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfProfileUpdate.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfProfileUpdate.copyWith.fieldName(...)`
class _$ProfileUpdateCWProxyImpl implements _$ProfileUpdateCWProxy {
  const _$ProfileUpdateCWProxyImpl(this._value);

  final ProfileUpdate _value;

  @override
  ProfileUpdate nickname(String? nickname) => this(nickname: nickname);

  @override
  ProfileUpdate timezone(String? timezone) => this(timezone: timezone);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ProfileUpdate(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ProfileUpdate(...).copyWith(id: 12, name: "My name")
  /// ````
  ProfileUpdate call({
    Object? nickname = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
  }) {
    return ProfileUpdate(
      nickname: nickname == const $CopyWithPlaceholder()
          ? _value.nickname
          // ignore: cast_nullable_to_non_nullable
          : nickname as String?,
      timezone: timezone == const $CopyWithPlaceholder()
          ? _value.timezone
          // ignore: cast_nullable_to_non_nullable
          : timezone as String?,
    );
  }
}

extension $ProfileUpdateCopyWith on ProfileUpdate {
  /// Returns a callable class that can be used as follows: `instanceOfProfileUpdate.copyWith(...)` or like so:`instanceOfProfileUpdate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProfileUpdateCWProxy get copyWith => _$ProfileUpdateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileUpdate _$ProfileUpdateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProfileUpdate', json, ($checkedConvert) {
      final val = ProfileUpdate(
        nickname: $checkedConvert('nickname', (v) => v as String?),
        timezone: $checkedConvert('timezone', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ProfileUpdateToJson(ProfileUpdate instance) =>
    <String, dynamic>{
      'nickname': ?instance.nickname,
      'timezone': ?instance.timezone,
    };
