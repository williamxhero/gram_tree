//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/sourced_value.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'skip_adjustment_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SkipAdjustmentResult {
  /// Returns a new [SkipAdjustmentResult] instance.
  SkipAdjustmentResult({

    required  this.componentId,

    required  this.source_,
  });

  @JsonKey(
    
    name: r'component_id',
    required: true,
    includeIfNull: false,
  )


  final String componentId;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final SourcedValue source_;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SkipAdjustmentResult &&
      other.componentId == componentId &&
      other.source_ == source_;

    @override
    int get hashCode =>
        componentId.hashCode +
        source_.hashCode;

  factory SkipAdjustmentResult.fromJson(Map<String, dynamic> json) => _$SkipAdjustmentResultFromJson(json);

  Map<String, dynamic> toJson() => _$SkipAdjustmentResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

