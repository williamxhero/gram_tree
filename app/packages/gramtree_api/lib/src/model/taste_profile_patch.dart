//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'taste_profile_patch.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TasteProfilePatch {
  /// Returns a new [TasteProfilePatch] instance.
  TasteProfilePatch({required this.flavors});

  @JsonKey(name: r'flavors', required: true, includeIfNull: false)
  final Map<String, num> flavors;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TasteProfilePatch && other.flavors == flavors;

  @override
  int get hashCode => flavors.hashCode;

  factory TasteProfilePatch.fromJson(Map<String, dynamic> json) =>
      _$TasteProfilePatchFromJson(json);

  Map<String, dynamic> toJson() => _$TasteProfilePatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
