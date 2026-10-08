//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/taste_flavor_out.dart';
import 'package:gramtree_api/src/model/local_cuisine_out.dart';
import 'package:gramtree_api/src/model/taste_scale.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'taste_profile_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TasteProfileOut {
  /// Returns a new [TasteProfileOut] instance.
  TasteProfileOut({
    required this.flavors,

    required this.id,

    required this.localCuisines,

    required this.scale,

    required this.version,
  });

  @JsonKey(name: r'flavors', required: true, includeIfNull: false)
  final Map<String, TasteFlavorOut> flavors;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'local_cuisines', required: true, includeIfNull: false)
  final List<LocalCuisineOut> localCuisines;

  @JsonKey(name: r'scale', required: true, includeIfNull: false)
  final TasteScale scale;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final int version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TasteProfileOut &&
          other.flavors == flavors &&
          other.id == id &&
          other.localCuisines == localCuisines &&
          other.scale == scale &&
          other.version == version;

  @override
  int get hashCode =>
      flavors.hashCode +
      id.hashCode +
      localCuisines.hashCode +
      scale.hashCode +
      version.hashCode;

  factory TasteProfileOut.fromJson(Map<String, dynamic> json) =>
      _$TasteProfileOutFromJson(json);

  Map<String, dynamic> toJson() => _$TasteProfileOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
