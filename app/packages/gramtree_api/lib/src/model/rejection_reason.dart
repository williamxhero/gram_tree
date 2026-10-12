//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rejection_reason.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RejectionReason {
  /// Returns a new [RejectionReason] instance.
  RejectionReason({

    required  this.code,

    required  this.message,
  });

      /// 程序可判断的拒收原因代码：unknown_event_type / unsupported_version / invalid_content / invalid_correlation_id
  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



      /// 给人看的一句话说明，不包含事件内容本身
  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: false,
  )


  final String message;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RejectionReason &&
      other.code == code &&
      other.message == message;

    @override
    int get hashCode =>
        code.hashCode +
        message.hashCode;

  factory RejectionReason.fromJson(Map<String, dynamic> json) => _$RejectionReasonFromJson(json);

  Map<String, dynamic> toJson() => _$RejectionReasonToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

