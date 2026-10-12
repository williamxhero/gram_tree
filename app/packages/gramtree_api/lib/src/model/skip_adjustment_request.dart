//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'skip_adjustment_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SkipAdjustmentRequest {
  /// Returns a new [SkipAdjustmentRequest] instance.
  SkipAdjustmentRequest({

    required  this.componentId,
  });

      /// 要去掉来源调整的组件实例 ID
  @JsonKey(
    
    name: r'component_id',
    required: true,
    includeIfNull: false,
  )


  final String componentId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SkipAdjustmentRequest &&
      other.componentId == componentId;

    @override
    int get hashCode =>
        componentId.hashCode;

  factory SkipAdjustmentRequest.fromJson(Map<String, dynamic> json) => _$SkipAdjustmentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SkipAdjustmentRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

