//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'email_code_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EmailCodeRequest {
  /// Returns a new [EmailCodeRequest] instance.
  EmailCodeRequest({

    required  this.email,

    required  this.purpose,
  });

  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: false,
  )


  final String email;



  @JsonKey(
    
    name: r'purpose',
    required: true,
    includeIfNull: false,
  )


  final EmailCodeRequestPurposeEnum purpose;





    @override
    bool operator ==(Object other) => identical(this, other) || other is EmailCodeRequest &&
      other.email == email &&
      other.purpose == purpose;

    @override
    int get hashCode =>
        email.hashCode +
        purpose.hashCode;

  factory EmailCodeRequest.fromJson(Map<String, dynamic> json) => _$EmailCodeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EmailCodeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum EmailCodeRequestPurposeEnum {
@JsonValue(r'login')
login(r'login'),
@JsonValue(r'bind')
bind(r'bind'),
@JsonValue(r'reauth')
reauth(r'reauth');

const EmailCodeRequestPurposeEnum(this.value);

final String value;

@override
String toString() => value;
}


