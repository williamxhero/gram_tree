//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'local_cuisine_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LocalCuisineOut {
  /// Returns a new [LocalCuisineOut] instance.
  LocalCuisineOut({required this.adjustments, required this.cuisine});

  @JsonKey(name: r'adjustments', required: true, includeIfNull: false)
  final Map<String, num> adjustments;

  @JsonKey(name: r'cuisine', required: true, includeIfNull: false)
  final String cuisine;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalCuisineOut &&
          other.adjustments == adjustments &&
          other.cuisine == cuisine;

  @override
  int get hashCode => adjustments.hashCode + cuisine.hashCode;

  factory LocalCuisineOut.fromJson(Map<String, dynamic> json) =>
      _$LocalCuisineOutFromJson(json);

  Map<String, dynamic> toJson() => _$LocalCuisineOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
