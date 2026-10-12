//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/attribute_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'text_attribute.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TextAttribute {
  /// Returns a new [TextAttribute] instance.
  TextAttribute({

    required  this.estimate,

    required  this.source_,

    required  this.status,

    required  this.value,
  });

      /// 没经人工校对的字段按估算处理
  @JsonKey(
    
    name: r'estimate',
    required: true,
    includeIfNull: false,
  )


  final bool estimate;



      /// 这项数据的来源
  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final String source_;



      /// ai_draft：AI 起草；verified：人工校对过
  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final AttributeStatus status;



  @JsonKey(
    
    name: r'value',
    required: true,
    includeIfNull: false,
  )


  final String value;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TextAttribute &&
      other.estimate == estimate &&
      other.source_ == source_ &&
      other.status == status &&
      other.value == value;

    @override
    int get hashCode =>
        estimate.hashCode +
        source_.hashCode +
        status.hashCode +
        value.hashCode;

  factory TextAttribute.fromJson(Map<String, dynamic> json) => _$TextAttributeFromJson(json);

  Map<String, dynamic> toJson() => _$TextAttributeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

