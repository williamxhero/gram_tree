//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UserOut {
  /// Returns a new [UserOut] instance.
  UserOut({
    required this.createdAt,

    required this.id,

    required this.nickname,

    required this.phone,

    required this.realNameStatus,

    required this.status,

    required this.timezone,
  });

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final String createdAt;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'nickname', required: true, includeIfNull: false)
  final String nickname;

  @JsonKey(name: r'phone', required: true, includeIfNull: true)
  final String? phone;

  /// 预留：发布内容实名状态（SPEC-011）
  @JsonKey(name: r'real_name_status', required: true, includeIfNull: false)
  final UserOutRealNameStatusEnum realNameStatus;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final UserOutStatusEnum status;

  @JsonKey(name: r'timezone', required: true, includeIfNull: false)
  final String timezone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserOut &&
          other.createdAt == createdAt &&
          other.id == id &&
          other.nickname == nickname &&
          other.phone == phone &&
          other.realNameStatus == realNameStatus &&
          other.status == status &&
          other.timezone == timezone;

  @override
  int get hashCode =>
      createdAt.hashCode +
      id.hashCode +
      nickname.hashCode +
      (phone == null ? 0 : phone.hashCode) +
      realNameStatus.hashCode +
      status.hashCode +
      timezone.hashCode;

  factory UserOut.fromJson(Map<String, dynamic> json) =>
      _$UserOutFromJson(json);

  Map<String, dynamic> toJson() => _$UserOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

/// 预留：发布内容实名状态（SPEC-011）
enum UserOutRealNameStatusEnum {
  /// 预留：发布内容实名状态（SPEC-011）
  @JsonValue(r'none')
  none(r'none'),

  /// 预留：发布内容实名状态（SPEC-011）
  @JsonValue(r'pending')
  pending(r'pending'),

  /// 预留：发布内容实名状态（SPEC-011）
  @JsonValue(r'verified')
  verified(r'verified');

  const UserOutRealNameStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum UserOutStatusEnum {
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'deleting')
  deleting(r'deleting'),
  @JsonValue(r'deleted')
  deleted(r'deleted');

  const UserOutStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
