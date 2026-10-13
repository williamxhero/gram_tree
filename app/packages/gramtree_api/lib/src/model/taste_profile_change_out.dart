//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'taste_profile_change_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TasteProfileChangeOut {
  /// Returns a new [TasteProfileChangeOut] instance.
  TasteProfileChangeOut({
    required this.createdAt,

    required this.field,

    required this.id,

    required this.newValue,

    required this.oldValue,

    required this.origin,

    required this.reason,

    this.revertedAt,

    required this.source_,

    this.sourceRecordIds,

    required this.status,

    required this.version,
  });

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final String createdAt;

  @JsonKey(name: r'field', required: true, includeIfNull: false)
  final String field;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'new_value', required: true, includeIfNull: false)
  final Object newValue;

  @JsonKey(name: r'old_value', required: true, includeIfNull: false)
  final Object oldValue;

  @JsonKey(name: r'origin', required: true, includeIfNull: false)
  final TasteProfileChangeOutOriginEnum origin;

  @JsonKey(name: r'reason', required: true, includeIfNull: false)
  final String reason;

  @JsonKey(name: r'reverted_at', required: false, includeIfNull: false)
  final String? revertedAt;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final String source_;

  @JsonKey(name: r'source_record_ids', required: false, includeIfNull: false)
  final List<String>? sourceRecordIds;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final TasteProfileChangeOutStatusEnum status;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final int version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TasteProfileChangeOut &&
          other.createdAt == createdAt &&
          other.field == field &&
          other.id == id &&
          other.newValue == newValue &&
          other.oldValue == oldValue &&
          other.origin == origin &&
          other.reason == reason &&
          other.revertedAt == revertedAt &&
          other.source_ == source_ &&
          other.sourceRecordIds == sourceRecordIds &&
          other.status == status &&
          other.version == version;

  @override
  int get hashCode =>
      createdAt.hashCode +
      field.hashCode +
      id.hashCode +
      newValue.hashCode +
      oldValue.hashCode +
      origin.hashCode +
      reason.hashCode +
      (revertedAt == null ? 0 : revertedAt.hashCode) +
      source_.hashCode +
      sourceRecordIds.hashCode +
      status.hashCode +
      version.hashCode;

  factory TasteProfileChangeOut.fromJson(Map<String, dynamic> json) =>
      _$TasteProfileChangeOutFromJson(json);

  Map<String, dynamic> toJson() => _$TasteProfileChangeOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum TasteProfileChangeOutOriginEnum {
  @JsonValue(r'manual')
  manual(r'manual'),
  @JsonValue(r'auto')
  auto(r'auto'),
  @JsonValue(r'explicit_save')
  explicitSave(r'explicit_save');

  const TasteProfileChangeOutOriginEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum TasteProfileChangeOutStatusEnum {
  @JsonValue(r'active')
  active(r'active'),
  @JsonValue(r'reverted')
  reverted(r'reverted'),
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'confirmed')
  confirmed(r'confirmed');

  const TasteProfileChangeOutStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
