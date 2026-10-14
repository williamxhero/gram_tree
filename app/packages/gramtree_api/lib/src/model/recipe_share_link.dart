//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_share_link.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeShareLink {
  /// Returns a new [RecipeShareLink] instance.
  RecipeShareLink({
    required this.appPath,

    required this.shareId,

    required this.url,
  });

  @JsonKey(name: r'app_path', required: true, includeIfNull: false)
  final String appPath;

  @JsonKey(name: r'share_id', required: true, includeIfNull: false)
  final String shareId;

  @JsonKey(name: r'url', required: true, includeIfNull: false)
  final String url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeShareLink &&
          other.appPath == appPath &&
          other.shareId == shareId &&
          other.url == url;

  @override
  int get hashCode => appPath.hashCode + shareId.hashCode + url.hashCode;

  factory RecipeShareLink.fromJson(Map<String, dynamic> json) =>
      _$RecipeShareLinkFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeShareLinkToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
