//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/normalize_result_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'normalize_response.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NormalizeResponse {
  /// Returns a new [NormalizeResponse] instance.
  NormalizeResponse({required this.results});

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<NormalizeResultItem> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NormalizeResponse && other.results == results;

  @override
  int get hashCode => results.hashCode;

  factory NormalizeResponse.fromJson(Map<String, dynamic> json) =>
      _$NormalizeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NormalizeResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
