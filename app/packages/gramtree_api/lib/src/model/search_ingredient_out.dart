//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_ingredient_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SearchIngredientOut {
  /// Returns a new [SearchIngredientOut] instance.
  SearchIngredientOut({
    required this.aliases,

    required this.category,

    required this.id,

    required this.matchedName,

    required this.pinyin,

    required this.pinyinInitials,

    required this.standardName,

    required this.version,
  });

  @JsonKey(name: r'aliases', required: true, includeIfNull: false)
  final List<String> aliases;

  @JsonKey(name: r'category', required: true, includeIfNull: false)
  final String category;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  /// 实际命中的叫法；已合并食材保留旧叫法
  @JsonKey(name: r'matched_name', required: true, includeIfNull: false)
  final String matchedName;

  @JsonKey(name: r'pinyin', required: true, includeIfNull: false)
  final String pinyin;

  @JsonKey(name: r'pinyin_initials', required: true, includeIfNull: false)
  final String pinyinInitials;

  @JsonKey(name: r'standard_name', required: true, includeIfNull: false)
  final String standardName;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final String version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchIngredientOut &&
          other.aliases == aliases &&
          other.category == category &&
          other.id == id &&
          other.matchedName == matchedName &&
          other.pinyin == pinyin &&
          other.pinyinInitials == pinyinInitials &&
          other.standardName == standardName &&
          other.version == version;

  @override
  int get hashCode =>
      aliases.hashCode +
      category.hashCode +
      id.hashCode +
      matchedName.hashCode +
      pinyin.hashCode +
      pinyinInitials.hashCode +
      standardName.hashCode +
      version.hashCode;

  factory SearchIngredientOut.fromJson(Map<String, dynamic> json) =>
      _$SearchIngredientOutFromJson(json);

  Map<String, dynamic> toJson() => _$SearchIngredientOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
