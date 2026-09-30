//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'value_source.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ValueSource {
  /// Returns a new [ValueSource] instance.
  ValueSource({
    required this.basis,

    required this.confidence,

    required this.original,

    required this.source_,
  });

  @JsonKey(name: r'basis', required: true, includeIfNull: false)
  final String basis;

  @JsonKey(name: r'confidence', required: true, includeIfNull: false)
  final num confidence;

  @JsonKey(name: r'original', required: true, includeIfNull: false)
  final String original;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final ValueSourceSource_Enum source_;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueSource &&
          other.basis == basis &&
          other.confidence == confidence &&
          other.original == original &&
          other.source_ == source_;

  @override
  int get hashCode =>
      basis.hashCode +
      confidence.hashCode +
      original.hashCode +
      source_.hashCode;

  factory ValueSource.fromJson(Map<String, dynamic> json) =>
      _$ValueSourceFromJson(json);

  Map<String, dynamic> toJson() => _$ValueSourceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ValueSourceSource_Enum {
  @JsonValue(r'author_filled')
  authorFilled(r'author_filled'),
  @JsonValue(r'ai_estimated')
  aiEstimated(r'ai_estimated'),
  @JsonValue(r'verified')
  verified(r'verified');

  const ValueSourceSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}
