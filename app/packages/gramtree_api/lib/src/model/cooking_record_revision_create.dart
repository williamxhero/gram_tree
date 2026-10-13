//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cooking_record_revision_create.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CookingRecordRevisionCreate {
  /// Returns a new [CookingRecordRevisionCreate] instance.
  CookingRecordRevisionCreate({
    required this.field,

    this.note = '',

    required this.revisionId,

    required this.value,
  });

  @JsonKey(name: r'field', required: true, includeIfNull: false)
  final CookingRecordRevisionCreateFieldEnum field;

  @JsonKey(
    defaultValue: '',
    name: r'note',
    required: false,
    includeIfNull: false,
  )
  final String? note;

  @JsonKey(name: r'revision_id', required: true, includeIfNull: false)
  final String revisionId;

  @JsonKey(name: r'value', required: true, includeIfNull: false)
  final Object value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CookingRecordRevisionCreate &&
          other.field == field &&
          other.note == note &&
          other.revisionId == revisionId &&
          other.value == value;

  @override
  int get hashCode =>
      field.hashCode + note.hashCode + revisionId.hashCode + value.hashCode;

  factory CookingRecordRevisionCreate.fromJson(Map<String, dynamic> json) =>
      _$CookingRecordRevisionCreateFromJson(json);

  Map<String, dynamic> toJson() => _$CookingRecordRevisionCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum CookingRecordRevisionCreateFieldEnum {
  @JsonValue(r'rating')
  rating(r'rating'),
  @JsonValue(r'feedback')
  feedback(r'feedback'),
  @JsonValue(r'tags')
  tags(r'tags'),
  @JsonValue(r'adjustments')
  adjustments(r'adjustments');

  const CookingRecordRevisionCreateFieldEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
