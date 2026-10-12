//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/user_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token_pair.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TokenPair {
  /// Returns a new [TokenPair] instance.
  TokenPair({

    required  this.accessExpiresIn,

    required  this.accessToken,

    required  this.refreshToken,

    required  this.user,
  });

      /// 访问令牌多少秒后过期
  @JsonKey(
    
    name: r'access_expires_in',
    required: true,
    includeIfNull: false,
  )


  final int accessExpiresIn;



  @JsonKey(
    
    name: r'access_token',
    required: true,
    includeIfNull: false,
  )


  final String accessToken;



      /// 续期用；每次续期都会换发新的，旧的立即作废
  @JsonKey(
    
    name: r'refresh_token',
    required: true,
    includeIfNull: false,
  )


  final String refreshToken;



  @JsonKey(
    
    name: r'user',
    required: true,
    includeIfNull: false,
  )


  final UserOut user;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TokenPair &&
      other.accessExpiresIn == accessExpiresIn &&
      other.accessToken == accessToken &&
      other.refreshToken == refreshToken &&
      other.user == user;

    @override
    int get hashCode =>
        accessExpiresIn.hashCode +
        accessToken.hashCode +
        refreshToken.hashCode +
        user.hashCode;

  factory TokenPair.fromJson(Map<String, dynamic> json) => _$TokenPairFromJson(json);

  Map<String, dynamic> toJson() => _$TokenPairToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

