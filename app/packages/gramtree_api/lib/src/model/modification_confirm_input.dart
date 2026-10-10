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
  ModificationConfirmInput({
    this.changeNote = '',

    this.explanationFingerprint,

    required this.revision,

    this.tags,
  });

  @JsonKey(
    defaultValue: '',
    name: r'change_note',
    required: false,
    includeIfNull: false,
  )
  final String? changeNote;

  @JsonKey(
    name: r'explanation_fingerprint',
    required: false,
    includeIfNull: false,
  )
  final String? explanationFingerprint;

  // minimum: 0
  @JsonKey(name: r'revision', required: true, includeIfNull: false)
  final int revision;

  @JsonKey(name: r'tags', required: false, includeIfNull: false)
  final List<String>? tags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModificationConfirmInput &&
          other.changeNote == changeNote &&
          other.explanationFingerprint == explanationFingerprint &&
          other.revision == revision &&
          other.tags == tags;

  @override
  int get hashCode =>
      changeNote.hashCode +
      (explanationFingerprint == null ? 0 : explanationFingerprint.hashCode) +
      revision.hashCode +
      (tags == null ? 0 : tags.hashCode);

  factory ModificationConfirmInput.fromJson(Map<String, dynamic> json) =>
      _$ModificationConfirmInputFromJson(json);

  Map<String, dynamic> toJson() => _$ModificationConfirmInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
