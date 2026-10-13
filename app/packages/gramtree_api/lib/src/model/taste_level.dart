//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'taste_level.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TasteLevel {
  /// Returns a new [TasteLevel] instance.
  TasteLevel({required this.coefficient, required this.label});

  @JsonKey(name: r'coefficient', required: true, includeIfNull: false)
  final num coefficient;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TasteLevel &&
          other.coefficient == coefficient &&
          other.label == label;

  @override
  int get hashCode => coefficient.hashCode + label.hashCode;

  factory TasteLevel.fromJson(Map<String, dynamic> json) =>
      _$TasteLevelFromJson(json);

  Map<String, dynamic> toJson() => _$TasteLevelToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
