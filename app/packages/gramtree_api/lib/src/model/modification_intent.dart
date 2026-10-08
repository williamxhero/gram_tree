//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'modification_intent.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ModificationIntent {
  /// Returns a new [ModificationIntent] instance.
  ModificationIntent({
    required this.category,

    required this.confidence,

    this.parameters,
  });

  @JsonKey(name: r'category', required: true, includeIfNull: false)
  final ModificationIntentCategoryEnum category;

  // minimum: 0.0
  // maximum: 1.0
  @JsonKey(name: r'confidence', required: true, includeIfNull: false)
  final num confidence;

  @JsonKey(name: r'parameters', required: false, includeIfNull: false)
  final Object? parameters;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModificationIntent &&
          other.category == category &&
          other.confidence == confidence &&
          other.parameters == parameters;

  @override
  int get hashCode =>
      category.hashCode + confidence.hashCode + parameters.hashCode;

  factory ModificationIntent.fromJson(Map<String, dynamic> json) =>
      _$ModificationIntentFromJson(json);

  Map<String, dynamic> toJson() => _$ModificationIntentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ModificationIntentCategoryEnum {
  @JsonValue(r'taste')
  taste(r'taste'),
  @JsonValue(r'cookware')
  cookware(r'cookware'),
  @JsonValue(r'substitution')
  substitution(r'substitution'),
  @JsonValue(r'time_difficulty')
  timeDifficulty(r'time_difficulty'),
  @JsonValue(r'method')
  method(r'method'),
  @JsonValue(r'text')
  text(r'text'),
  @JsonValue(r'unknown')
  unknown(r'unknown');

  const ModificationIntentCategoryEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
