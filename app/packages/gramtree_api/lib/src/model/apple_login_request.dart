//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'apple_login_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppleLoginRequest {
  /// Returns a new [AppleLoginRequest] instance.
  AppleLoginRequest({

     this.authorizationCode,

     this.familyName,

     this.givenName,

    required  this.identityToken,
  });

  @JsonKey(
    
    name: r'authorization_code',
    required: false,
    includeIfNull: false,
  )


  final String? authorizationCode;



  @JsonKey(
    
    name: r'family_name',
    required: false,
    includeIfNull: false,
  )


  final String? familyName;



  @JsonKey(
    
    name: r'given_name',
    required: false,
    includeIfNull: false,
  )


  final String? givenName;



  @JsonKey(
    
    name: r'identity_token',
    required: true,
    includeIfNull: false,
  )


  final String identityToken;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AppleLoginRequest &&
      other.authorizationCode == authorizationCode &&
      other.familyName == familyName &&
      other.givenName == givenName &&
      other.identityToken == identityToken;

    @override
    int get hashCode =>
        (authorizationCode == null ? 0 : authorizationCode.hashCode) +
        (familyName == null ? 0 : familyName.hashCode) +
        (givenName == null ? 0 : givenName.hashCode) +
        identityToken.hashCode;

  factory AppleLoginRequest.fromJson(Map<String, dynamic> json) => _$AppleLoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AppleLoginRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

