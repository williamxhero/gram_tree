//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attribution_answer.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AttributionAnswer {
  /// Returns a new [AttributionAnswer] instance.
  AttributionAnswer({required this.answer});

  @JsonKey(name: r'answer', required: true, includeIfNull: false)
  final AttributionAnswerAnswerEnum answer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttributionAnswer && other.answer == answer;

  @override
  int get hashCode => answer.hashCode;

  factory AttributionAnswer.fromJson(Map<String, dynamic> json) =>
      _$AttributionAnswerFromJson(json);

  Map<String, dynamic> toJson() => _$AttributionAnswerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum AttributionAnswerAnswerEnum {
  @JsonValue(r'personal')
  personal(r'personal'),
  @JsonValue(r'recipe')
  recipe(r'recipe'),
  @JsonValue(r'unanswered')
  unanswered(r'unanswered');

  const AttributionAnswerAnswerEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
