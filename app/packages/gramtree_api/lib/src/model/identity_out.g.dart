// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IdentityOutCWProxy {
  IdentityOut createdAt(String createdAt);

  IdentityOut email(String? email);

  IdentityOut kind(IdentityOutKindEnum kind);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IdentityOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IdentityOut(...).copyWith(id: 12, name: "My name")
  /// ````
  IdentityOut call({String createdAt, String? email, IdentityOutKindEnum kind});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfIdentityOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfIdentityOut.copyWith.fieldName(...)`
class _$IdentityOutCWProxyImpl implements _$IdentityOutCWProxy {
  const _$IdentityOutCWProxyImpl(this._value);

  final IdentityOut _value;

  @override
  IdentityOut createdAt(String createdAt) => this(createdAt: createdAt);

  @override
  IdentityOut email(String? email) => this(email: email);

  @override
  IdentityOut kind(IdentityOutKindEnum kind) => this(kind: kind);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IdentityOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IdentityOut(...).copyWith(id: 12, name: "My name")
  /// ````
  IdentityOut call({
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
  }) {
    return IdentityOut(
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as IdentityOutKindEnum,
    );
  }
}

extension $IdentityOutCopyWith on IdentityOut {
  /// Returns a callable class that can be used as follows: `instanceOfIdentityOut.copyWith(...)` or like so:`instanceOfIdentityOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IdentityOutCWProxy get copyWith => _$IdentityOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IdentityOut _$IdentityOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate('IdentityOut', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['created_at', 'email', 'kind']);
      final val = IdentityOut(
        createdAt: $checkedConvert('created_at', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String?),
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$IdentityOutKindEnumEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'createdAt': 'created_at'});

Map<String, dynamic> _$IdentityOutToJson(IdentityOut instance) =>
    <String, dynamic>{
      'created_at': instance.createdAt,
      'email': instance.email,
      'kind': _$IdentityOutKindEnumEnumMap[instance.kind]!,
    };

const _$IdentityOutKindEnumEnumMap = {
  IdentityOutKindEnum.email: 'email',
  IdentityOutKindEnum.apple: 'apple',
  IdentityOutKindEnum.phone: 'phone',
  IdentityOutKindEnum.wechat: 'wechat',
};
