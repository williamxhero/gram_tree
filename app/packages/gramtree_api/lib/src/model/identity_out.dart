//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'identity_out.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IdentityOut {
  /// Returns a new [IdentityOut] instance.
  IdentityOut({

    required  this.createdAt,

    required  this.email,

    required  this.kind,
  });

  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final String createdAt;



  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: true,
  )


  final String? email;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final IdentityOutKindEnum kind;





    @override
    bool operator ==(Object other) => identical(this, other) || other is IdentityOut &&
      other.createdAt == createdAt &&
      other.email == email &&
      other.kind == kind;

    @override
    int get hashCode =>
        createdAt.hashCode +
        (email == null ? 0 : email.hashCode) +
        kind.hashCode;

  factory IdentityOut.fromJson(Map<String, dynamic> json) => _$IdentityOutFromJson(json);

  Map<String, dynamic> toJson() => _$IdentityOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum IdentityOutKindEnum {
@JsonValue(r'email')
email(r'email'),
@JsonValue(r'apple')
apple(r'apple'),
@JsonValue(r'phone')
phone(r'phone'),
@JsonValue(r'wechat')
wechat(r'wechat');

const IdentityOutKindEnum(this.value);

final String value;

@override
String toString() => value;
}


