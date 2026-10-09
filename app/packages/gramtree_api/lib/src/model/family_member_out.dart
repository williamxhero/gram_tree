//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/family_allergies_out.dart';
import 'package:gramtree_api/src/model/family_avoidance_out.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'family_member_out.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FamilyMemberOut {
  /// Returns a new [FamilyMemberOut] instance.
  FamilyMemberOut({
    required this.ageBand,

    required this.allergies,

    required this.avoidances,

    required this.flavors,

    required this.id,

    required this.nickname,

    required this.source_,
  });

  @JsonKey(name: r'age_band', required: true, includeIfNull: false)
  final FamilyMemberOutAgeBandEnum ageBand;

  @JsonKey(name: r'allergies', required: true, includeIfNull: false)
  final FamilyAllergiesOut allergies;

  @JsonKey(name: r'avoidances', required: true, includeIfNull: false)
  final List<FamilyAvoidanceOut> avoidances;

  @JsonKey(name: r'flavors', required: true, includeIfNull: false)
  final Map<String, num> flavors;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'nickname', required: true, includeIfNull: false)
  final String nickname;

  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final FamilyMemberOutSource_Enum source_;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyMemberOut &&
          other.ageBand == ageBand &&
          other.allergies == allergies &&
          other.avoidances == avoidances &&
          other.flavors == flavors &&
          other.id == id &&
          other.nickname == nickname &&
          other.source_ == source_;

  @override
  int get hashCode =>
      ageBand.hashCode +
      allergies.hashCode +
      avoidances.hashCode +
      flavors.hashCode +
      id.hashCode +
      nickname.hashCode +
      source_.hashCode;

  factory FamilyMemberOut.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberOutFromJson(json);

  Map<String, dynamic> toJson() => _$FamilyMemberOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum FamilyMemberOutAgeBandEnum {
  @JsonValue(r'under_1')
  under1(r'under_1'),
  @JsonValue(r'1_to_3')
  n1to3(r'1_to_3'),
  @JsonValue(r'3_to_6')
  n3to6(r'3_to_6'),
  @JsonValue(r'6_to_12')
  n6to12(r'6_to_12'),
  @JsonValue(r'12_to_18')
  n12to18(r'12_to_18'),
  @JsonValue(r'adult')
  adult(r'adult'),
  @JsonValue(r'elder')
  elder(r'elder');

  const FamilyMemberOutAgeBandEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum FamilyMemberOutSource_Enum {
  @JsonValue(r'manual')
  manual(r'manual');

  const FamilyMemberOutSource_Enum(this.value);

  final String value;

  @override
  String toString() => value;
}
