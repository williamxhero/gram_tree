//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recipe_source.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RecipeSource {
  /// Returns a new [RecipeSource] instance.
  RecipeSource({
    required this.kind,

    this.note,

    this.platform = 'unknown',

    this.url,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final RecipeSourceKindEnum kind;

  @JsonKey(name: r'note', required: false, includeIfNull: false)
  final String? note;

  @JsonKey(
    defaultValue: 'unknown',
    name: r'platform',
    required: false,
    includeIfNull: false,
  )
  final String? platform;

  @JsonKey(name: r'url', required: false, includeIfNull: false)
  final String? url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeSource &&
          other.kind == kind &&
          other.note == note &&
          other.platform == platform &&
          other.url == url;

  @override
  int get hashCode =>
      kind.hashCode +
      (note == null ? 0 : note.hashCode) +
      platform.hashCode +
      (url == null ? 0 : url.hashCode);

  factory RecipeSource.fromJson(Map<String, dynamic> json) =>
      _$RecipeSourceFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeSourceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum RecipeSourceKindEnum {
  @JsonValue(r'imported')
  imported(r'imported');

  const RecipeSourceKindEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
