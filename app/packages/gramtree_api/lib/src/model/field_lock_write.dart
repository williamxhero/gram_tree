//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'field_lock_write.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FieldLockWrite {
  /// Returns a new [FieldLockWrite] instance.
  FieldLockWrite({required this.field, required this.locked});

  @JsonKey(name: r'field', required: true, includeIfNull: false)
  final String field;

  @JsonKey(name: r'locked', required: true, includeIfNull: false)
  final bool locked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldLockWrite && other.field == field && other.locked == locked;

  @override
  int get hashCode => field.hashCode + locked.hashCode;

  factory FieldLockWrite.fromJson(Map<String, dynamic> json) =>
      _$FieldLockWriteFromJson(json);

  Map<String, dynamic> toJson() => _$FieldLockWriteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
