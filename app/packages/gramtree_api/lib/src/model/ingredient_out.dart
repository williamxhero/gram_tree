//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ingredient_out.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IngredientOut {
  /// Returns a new [IngredientOut] instance.
  IngredientOut({

    required  this.aliases,

    required  this.category,

    required  this.id,

    required  this.pinyin,

    required  this.pinyinInitials,

    required  this.standardName,

    required  this.version,
  });

  @JsonKey(
    
    name: r'aliases',
    required: true,
    includeIfNull: false,
  )


  final List<String> aliases;



  @JsonKey(
    
    name: r'category',
    required: true,
    includeIfNull: false,
  )


  final String category;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'pinyin',
    required: true,
    includeIfNull: false,
  )


  final String pinyin;



  @JsonKey(
    
    name: r'pinyin_initials',
    required: true,
    includeIfNull: false,
  )


  final String pinyinInitials;



  @JsonKey(
    
    name: r'standard_name',
    required: true,
    includeIfNull: false,
  )


  final String standardName;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final String version;





    @override
    bool operator ==(Object other) => identical(this, other) || other is IngredientOut &&
      other.aliases == aliases &&
      other.category == category &&
      other.id == id &&
      other.pinyin == pinyin &&
      other.pinyinInitials == pinyinInitials &&
      other.standardName == standardName &&
      other.version == version;

    @override
    int get hashCode =>
        aliases.hashCode +
        category.hashCode +
        id.hashCode +
        pinyin.hashCode +
        pinyinInitials.hashCode +
        standardName.hashCode +
        version.hashCode;

  factory IngredientOut.fromJson(Map<String, dynamic> json) => _$IngredientOutFromJson(json);

  Map<String, dynamic> toJson() => _$IngredientOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

