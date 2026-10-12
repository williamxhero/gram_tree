//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fallback_info.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FallbackInfo {
  /// Returns a new [FallbackInfo] instance.
  FallbackInfo({

    required  this.reasonCode,
  });

  @JsonKey(
    
    name: r'reason_code',
    required: true,
    includeIfNull: false,
  )


  final FallbackInfoReasonCodeEnum reasonCode;





    @override
    bool operator ==(Object other) => identical(this, other) || other is FallbackInfo &&
      other.reasonCode == reasonCode;

    @override
    int get hashCode =>
        reasonCode.hashCode;

  factory FallbackInfo.fromJson(Map<String, dynamic> json) => _$FallbackInfoFromJson(json);

  Map<String, dynamic> toJson() => _$FallbackInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum FallbackInfoReasonCodeEnum {
@JsonValue(r'unknown_major')
unknownMajor(r'unknown_major'),
@JsonValue(r'unknown_component')
unknownComponent(r'unknown_component'),
@JsonValue(r'illegal_action')
illegalAction(r'illegal_action'),
@JsonValue(r'invalid_data')
invalidData(r'invalid_data'),
@JsonValue(r'missing_required')
missingRequired(r'missing_required'),
@JsonValue(r'server_error')
serverError(r'server_error'),
@JsonValue(r'timeout')
timeout(r'timeout');

const FallbackInfoReasonCodeEnum(this.value);

final String value;

@override
String toString() => value;
}


