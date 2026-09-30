//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'storage_advice.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StorageAdvice {
  /// Returns a new [StorageAdvice] instance.
  StorageAdvice({

    required  this.days,

    required  this.method,
  });

      /// 建议存放天数
  @JsonKey(
    
    name: r'days',
    required: true,
    includeIfNull: false,
  )


  final int days;



      /// 常温、冷藏或冷冻
  @JsonKey(
    
    name: r'method',
    required: true,
    includeIfNull: false,
  )


  final String method;





    @override
    bool operator ==(Object other) => identical(this, other) || other is StorageAdvice &&
      other.days == days &&
      other.method == method;

    @override
    int get hashCode =>
        days.hashCode +
        method.hashCode;

  factory StorageAdvice.fromJson(Map<String, dynamic> json) => _$StorageAdviceFromJson(json);

  Map<String, dynamic> toJson() => _$StorageAdviceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

