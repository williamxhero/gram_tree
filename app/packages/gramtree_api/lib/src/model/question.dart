//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'question.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Question {
  /// Returns a new [Question] instance.
  Question({required this.default_, required this.key, required this.text});

  @JsonKey(name: r'default', required: true, includeIfNull: false)
  final String default_;

  @JsonKey(name: r'key', required: true, includeIfNull: false)
  final QuestionKeyEnum key;

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question &&
          other.default_ == default_ &&
          other.key == key &&
          other.text == text;

  @override
  int get hashCode => default_.hashCode + key.hashCode + text.hashCode;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum QuestionKeyEnum {
  @JsonValue(r'servings')
  servings(r'servings'),
  @JsonValue(r'cookware')
  cookware(r'cookware');

  const QuestionKeyEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
