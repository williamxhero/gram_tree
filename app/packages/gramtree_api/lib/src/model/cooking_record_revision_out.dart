//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cooking_record_revision_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CookingRecordRevisionOut {
  /// Returns a new [CookingRecordRevisionOut] instance.
  CookingRecordRevisionOut({
    required this.createdAt,

    required this.field,

    required this.note,

    required this.revision,

    required this.revisionId,

    required this.value,
  });

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final String createdAt;

  @JsonKey(name: r'field', required: true, includeIfNull: false)
  final String field;

  @JsonKey(name: r'note', required: true, includeIfNull: false)
  final String note;

  @JsonKey(name: r'revision', required: true, includeIfNull: false)
  final int revision;

  @JsonKey(name: r'revision_id', required: true, includeIfNull: false)
  final String revisionId;

  @JsonKey(name: r'value', required: true, includeIfNull: false)
  final Object value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CookingRecordRevisionOut &&
          other.createdAt == createdAt &&
          other.field == field &&
          other.note == note &&
          other.revision == revision &&
          other.revisionId == revisionId &&
          other.value == value;

  @override
  int get hashCode =>
      createdAt.hashCode +
      field.hashCode +
      note.hashCode +
      revision.hashCode +
      revisionId.hashCode +
      value.hashCode;

  factory CookingRecordRevisionOut.fromJson(Map<String, dynamic> json) =>
      _$CookingRecordRevisionOutFromJson(json);

  Map<String, dynamic> toJson() => _$CookingRecordRevisionOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
