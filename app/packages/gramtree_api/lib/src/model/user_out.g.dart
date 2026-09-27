// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UserOutCWProxy {
  UserOut createdAt(String createdAt);

  UserOut id(String id);

  UserOut nickname(String nickname);

  UserOut phone(String? phone);

  UserOut realNameStatus(UserOutRealNameStatusEnum realNameStatus);

  UserOut status(UserOutStatusEnum status);

  UserOut timezone(String timezone);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UserOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UserOut(...).copyWith(id: 12, name: "My name")
  /// ````
  UserOut call({
    String createdAt,
    String id,
    String nickname,
    String? phone,
    UserOutRealNameStatusEnum realNameStatus,
    UserOutStatusEnum status,
    String timezone,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUserOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUserOut.copyWith.fieldName(...)`
class _$UserOutCWProxyImpl implements _$UserOutCWProxy {
  const _$UserOutCWProxyImpl(this._value);

  final UserOut _value;

  @override
  UserOut createdAt(String createdAt) => this(createdAt: createdAt);

  @override
  UserOut id(String id) => this(id: id);

  @override
  UserOut nickname(String nickname) => this(nickname: nickname);

  @override
  UserOut phone(String? phone) => this(phone: phone);

  @override
  UserOut realNameStatus(UserOutRealNameStatusEnum realNameStatus) =>
      this(realNameStatus: realNameStatus);

  @override
  UserOut status(UserOutStatusEnum status) => this(status: status);

  @override
  UserOut timezone(String timezone) => this(timezone: timezone);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UserOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UserOut(...).copyWith(id: 12, name: "My name")
  /// ````
  UserOut call({
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? nickname = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? realNameStatus = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
  }) {
    return UserOut(
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as String,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      nickname: nickname == const $CopyWithPlaceholder()
          ? _value.nickname
          // ignore: cast_nullable_to_non_nullable
          : nickname as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
      realNameStatus: realNameStatus == const $CopyWithPlaceholder()
          ? _value.realNameStatus
          // ignore: cast_nullable_to_non_nullable
          : realNameStatus as UserOutRealNameStatusEnum,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as UserOutStatusEnum,
      timezone: timezone == const $CopyWithPlaceholder()
          ? _value.timezone
          // ignore: cast_nullable_to_non_nullable
          : timezone as String,
    );
  }
}

extension $UserOutCopyWith on UserOut {
  /// Returns a callable class that can be used as follows: `instanceOfUserOut.copyWith(...)` or like so:`instanceOfUserOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UserOutCWProxy get copyWith => _$UserOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserOut _$UserOutFromJson(Map<String, dynamic> json) => $checkedCreate(
  'UserOut',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'created_at',
        'id',
        'nickname',
        'phone',
        'real_name_status',
        'status',
        'timezone',
      ],
    );
    final val = UserOut(
      createdAt: $checkedConvert('created_at', (v) => v as String),
      id: $checkedConvert('id', (v) => v as String),
      nickname: $checkedConvert('nickname', (v) => v as String),
      phone: $checkedConvert('phone', (v) => v as String?),
      realNameStatus: $checkedConvert(
        'real_name_status',
        (v) => $enumDecode(_$UserOutRealNameStatusEnumEnumMap, v),
      ),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$UserOutStatusEnumEnumMap, v),
      ),
      timezone: $checkedConvert('timezone', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'createdAt': 'created_at',
    'realNameStatus': 'real_name_status',
  },
);

Map<String, dynamic> _$UserOutToJson(UserOut instance) => <String, dynamic>{
  'created_at': instance.createdAt,
  'id': instance.id,
  'nickname': instance.nickname,
  'phone': instance.phone,
  'real_name_status':
      _$UserOutRealNameStatusEnumEnumMap[instance.realNameStatus]!,
  'status': _$UserOutStatusEnumEnumMap[instance.status]!,
  'timezone': instance.timezone,
};

const _$UserOutRealNameStatusEnumEnumMap = {
  UserOutRealNameStatusEnum.none: 'none',
  UserOutRealNameStatusEnum.pending: 'pending',
  UserOutRealNameStatusEnum.verified: 'verified',
};

const _$UserOutStatusEnumEnumMap = {
  UserOutStatusEnum.active: 'active',
  UserOutStatusEnum.deleting: 'deleting',
  UserOutStatusEnum.deleted: 'deleted',
};
