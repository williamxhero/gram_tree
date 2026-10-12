//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'email_code_sent.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EmailCodeSent {
  /// Returns a new [EmailCodeSent] instance.
  EmailCodeSent({

    required  this.expiresInSeconds,

    required  this.resendAfterSeconds,
  });

  @JsonKey(
    
    name: r'expires_in_seconds',
    required: true,
    includeIfNull: false,
  )


  final int expiresInSeconds;



  @JsonKey(
    
    name: r'resend_after_seconds',
    required: true,
    includeIfNull: false,
  )


  final int resendAfterSeconds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is EmailCodeSent &&
      other.expiresInSeconds == expiresInSeconds &&
      other.resendAfterSeconds == resendAfterSeconds;

    @override
    int get hashCode =>
        expiresInSeconds.hashCode +
        resendAfterSeconds.hashCode;

  factory EmailCodeSent.fromJson(Map<String, dynamic> json) => _$EmailCodeSentFromJson(json);

  Map<String, dynamic> toJson() => _$EmailCodeSentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

