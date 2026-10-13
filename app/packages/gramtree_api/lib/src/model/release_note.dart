//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'release_note.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReleaseNote {
  /// Returns a new [ReleaseNote] instance.
  ReleaseNote({required this.changelog, required this.version});

  @JsonKey(name: r'changelog', required: true, includeIfNull: false)
  final String changelog;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final String version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReleaseNote &&
          other.changelog == changelog &&
          other.version == version;

  @override
  int get hashCode => changelog.hashCode + version.hashCode;

  factory ReleaseNote.fromJson(Map<String, dynamic> json) =>
      _$ReleaseNoteFromJson(json);

  Map<String, dynamic> toJson() => _$ReleaseNoteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
