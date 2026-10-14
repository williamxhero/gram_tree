//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'detail_preference.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DetailPreference {
  /// Returns a new [DetailPreference] instance.
  DetailPreference({required this.detail});

  @JsonKey(name: r'detail', required: true, includeIfNull: false)
  final DetailPreferenceDetailEnum detail;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetailPreference && other.detail == detail;

  @override
  int get hashCode => detail.hashCode;

  factory DetailPreference.fromJson(Map<String, dynamic> json) =>
      _$DetailPreferenceFromJson(json);

  Map<String, dynamic> toJson() => _$DetailPreferenceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum DetailPreferenceDetailEnum {
  @JsonValue(r'auto')
  auto(r'auto'),
  @JsonValue(r'brief')
  brief(r'brief'),
  @JsonValue(r'detailed')
  detailed(r'detailed');

  const DetailPreferenceDetailEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
