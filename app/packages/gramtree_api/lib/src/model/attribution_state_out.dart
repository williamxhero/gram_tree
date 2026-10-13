//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/attribution_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attribution_state_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AttributionStateOut {
  /// Returns a new [AttributionStateOut] instance.
  AttributionStateOut({required this.attribution, required this.reasonText});

  @JsonKey(name: r'attribution', required: true, includeIfNull: false)
  final AttributionOut attribution;

  @JsonKey(name: r'reason_text', required: true, includeIfNull: false)
  final String reasonText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttributionStateOut &&
          other.attribution == attribution &&
          other.reasonText == reasonText;

  @override
  int get hashCode => attribution.hashCode + reasonText.hashCode;

  factory AttributionStateOut.fromJson(Map<String, dynamic> json) =>
      _$AttributionStateOutFromJson(json);

  Map<String, dynamic> toJson() => _$AttributionStateOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
