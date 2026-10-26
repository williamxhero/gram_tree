//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'record_version_save_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecordVersionSaveInput {
  /// Returns a new [RecordVersionSaveInput] instance.
  RecordVersionSaveInput({this.changeNote = '临场调整', required this.requestId});

  @JsonKey(
    defaultValue: '临场调整',
    name: r'change_note',
    required: false,
    includeIfNull: false,
  )
  final String? changeNote;

  @JsonKey(name: r'request_id', required: true, includeIfNull: false)
  final String requestId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordVersionSaveInput &&
          other.changeNote == changeNote &&
          other.requestId == requestId;

  @override
  int get hashCode => changeNote.hashCode + requestId.hashCode;

  factory RecordVersionSaveInput.fromJson(Map<String, dynamic> json) =>
      _$RecordVersionSaveInputFromJson(json);

  Map<String, dynamic> toJson() => _$RecordVersionSaveInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
