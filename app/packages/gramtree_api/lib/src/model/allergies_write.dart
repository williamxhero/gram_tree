//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'allergies_write.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AllergiesWrite {
  /// Returns a new [AllergiesWrite] instance.
  AllergiesWrite({
    required this.authorizationVersion,

    required this.categories,

    required this.consentId,

    required this.ingredientIds,
  });

  // minimum: 0
  @JsonKey(name: r'authorization_version', required: true, includeIfNull: false)
  final int authorizationVersion;

  @JsonKey(name: r'categories', required: true, includeIfNull: false)
  final List<String> categories;

  @JsonKey(name: r'consent_id', required: true, includeIfNull: false)
  final String consentId;

  @JsonKey(name: r'ingredient_ids', required: true, includeIfNull: false)
  final List<String> ingredientIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllergiesWrite &&
          other.authorizationVersion == authorizationVersion &&
          other.categories == categories &&
          other.consentId == consentId &&
          other.ingredientIds == ingredientIds;

  @override
  int get hashCode =>
      authorizationVersion.hashCode +
      categories.hashCode +
      consentId.hashCode +
      ingredientIds.hashCode;

  factory AllergiesWrite.fromJson(Map<String, dynamic> json) =>
      _$AllergiesWriteFromJson(json);

  Map<String, dynamic> toJson() => _$AllergiesWriteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
