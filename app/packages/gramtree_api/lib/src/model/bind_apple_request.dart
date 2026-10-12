//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bind_apple_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BindAppleRequest {
  /// Returns a new [BindAppleRequest] instance.
  BindAppleRequest({

     this.authorizationCode,

    required  this.identityToken,
  });

  @JsonKey(
    
    name: r'authorization_code',
    required: false,
    includeIfNull: false,
  )


  final String? authorizationCode;



  @JsonKey(
    
    name: r'identity_token',
    required: true,
    includeIfNull: false,
  )


  final String identityToken;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BindAppleRequest &&
      other.authorizationCode == authorizationCode &&
      other.identityToken == identityToken;

    @override
    int get hashCode =>
        (authorizationCode == null ? 0 : authorizationCode.hashCode) +
        identityToken.hashCode;

  factory BindAppleRequest.fromJson(Map<String, dynamic> json) => _$BindAppleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BindAppleRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

