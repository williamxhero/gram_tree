//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'flavor_profile.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FlavorProfile {
  /// Returns a new [FlavorProfile] instance.
  FlavorProfile({
    this.numbing = 0,

    this.oily = 0,

    this.salty = 0,

    this.sour = 0,

    this.spicy = 0,

    this.sweet = 0,

    this.umami = 0,
  });

  /// 麻
  // minimum: 0
  // maximum: 3
  @JsonKey(
    defaultValue: 0,
    name: r'numbing',
    required: false,
    includeIfNull: false,
  )
  final int? numbing;

  /// 油
  // minimum: 0
  // maximum: 3
  @JsonKey(
    defaultValue: 0,
    name: r'oily',
    required: false,
    includeIfNull: false,
  )
  final int? oily;

  /// 咸
  // minimum: 0
  // maximum: 3
  @JsonKey(
    defaultValue: 0,
    name: r'salty',
    required: false,
    includeIfNull: false,
  )
  final int? salty;

  /// 酸
  // minimum: 0
  // maximum: 3
  @JsonKey(
    defaultValue: 0,
    name: r'sour',
    required: false,
    includeIfNull: false,
  )
  final int? sour;

  /// 辣
  // minimum: 0
  // maximum: 3
  @JsonKey(
    defaultValue: 0,
    name: r'spicy',
    required: false,
    includeIfNull: false,
  )
  final int? spicy;

  /// 甜
  // minimum: 0
  // maximum: 3
  @JsonKey(
    defaultValue: 0,
    name: r'sweet',
    required: false,
    includeIfNull: false,
  )
  final int? sweet;

  /// 鲜
  // minimum: 0
  // maximum: 3
  @JsonKey(
    defaultValue: 0,
    name: r'umami',
    required: false,
    includeIfNull: false,
  )
  final int? umami;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlavorProfile &&
          other.numbing == numbing &&
          other.oily == oily &&
          other.salty == salty &&
          other.sour == sour &&
          other.spicy == spicy &&
          other.sweet == sweet &&
          other.umami == umami;

  @override
  int get hashCode =>
      numbing.hashCode +
      oily.hashCode +
      salty.hashCode +
      sour.hashCode +
      spicy.hashCode +
      sweet.hashCode +
      umami.hashCode;

  factory FlavorProfile.fromJson(Map<String, dynamic> json) =>
      _$FlavorProfileFromJson(json);

  Map<String, dynamic> toJson() => _$FlavorProfileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
