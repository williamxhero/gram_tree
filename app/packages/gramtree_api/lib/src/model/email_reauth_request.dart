//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'email_reauth_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EmailReauthRequest {
  /// Returns a new [EmailReauthRequest] instance.
  EmailReauthRequest({

    required  this.code,

    required  this.email,
  });

  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: false,
  )


  final String email;





    @override
    bool operator ==(Object other) => identical(this, other) || other is EmailReauthRequest &&
      other.code == code &&
      other.email == email;

    @override
    int get hashCode =>
        code.hashCode +
        email.hashCode;

  factory EmailReauthRequest.fromJson(Map<String, dynamic> json) => _$EmailReauthRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EmailReauthRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

