//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/normalize_candidate.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'normalize_result_item.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NormalizeResultItem {
  /// Returns a new [NormalizeResultItem] instance.
  NormalizeResultItem({

    required  this.candidates,

    required  this.confidence,

    required  this.ingredientId,

    required  this.name,

    required  this.standardName,
  });

      /// 只有 ambiguous 时非空
  @JsonKey(
    
    name: r'candidates',
    required: true,
    includeIfNull: false,
  )


  final List<NormalizeCandidate> candidates;



      /// exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
  @JsonKey(
    
    name: r'confidence',
    required: true,
    includeIfNull: false,
  )


  final NormalizeResultItemConfidenceEnum confidence;



  @JsonKey(
    
    name: r'ingredient_id',
    required: true,
    includeIfNull: true,
  )


  final String? ingredientId;



      /// 原样返回输入的名称
  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'standard_name',
    required: true,
    includeIfNull: true,
  )


  final String? standardName;





    @override
    bool operator ==(Object other) => identical(this, other) || other is NormalizeResultItem &&
      other.candidates == candidates &&
      other.confidence == confidence &&
      other.ingredientId == ingredientId &&
      other.name == name &&
      other.standardName == standardName;

    @override
    int get hashCode =>
        candidates.hashCode +
        confidence.hashCode +
        (ingredientId == null ? 0 : ingredientId.hashCode) +
        name.hashCode +
        (standardName == null ? 0 : standardName.hashCode);

  factory NormalizeResultItem.fromJson(Map<String, dynamic> json) => _$NormalizeResultItemFromJson(json);

  Map<String, dynamic> toJson() => _$NormalizeResultItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
enum NormalizeResultItemConfidenceEnum {
    /// exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
@JsonValue(r'exact')
exact(r'exact'),
    /// exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
@JsonValue(r'alias')
alias(r'alias'),
    /// exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
@JsonValue(r'fuzzy')
fuzzy(r'fuzzy'),
    /// exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
@JsonValue(r'ambiguous')
ambiguous(r'ambiguous'),
    /// exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
@JsonValue(r'unrecorded')
unrecorded(r'unrecorded');

const NormalizeResultItemConfidenceEnum(this.value);

final String value;

@override
String toString() => value;
}


