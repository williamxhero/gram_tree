//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'modification_confirm_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ModificationConfirmInput {
  /// Returns a new [ModificationConfirmInput] instance.
  ModificationConfirmInput({this.changeNote = '', required this.revision});

  @JsonKey(
    defaultValue: '',
    name: r'change_note',
    required: false,
    includeIfNull: false,
  )
  final String? changeNote;

  // minimum: 0
  @JsonKey(name: r'revision', required: true, includeIfNull: false)
  final int revision;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModificationConfirmInput &&
          other.changeNote == changeNote &&
          other.revision == revision;

  @override
  int get hashCode => changeNote.hashCode + revision.hashCode;

  factory ModificationConfirmInput.fromJson(Map<String, dynamic> json) =>
      _$ModificationConfirmInputFromJson(json);

  Map<String, dynamic> toJson() => _$ModificationConfirmInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
