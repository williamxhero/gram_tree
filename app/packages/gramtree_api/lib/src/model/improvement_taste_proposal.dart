//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'improvement_taste_proposal.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImprovementTasteProposal {
  /// Returns a new [ImprovementTasteProposal] instance.
  ImprovementTasteProposal({
    this.coefficients,

    required this.convertible,

    this.profileVersion,

    this.reason,
  });

  @JsonKey(name: r'coefficients', required: false, includeIfNull: false)
  final Map<String, num>? coefficients;

  @JsonKey(name: r'convertible', required: true, includeIfNull: false)
  final bool convertible;

  @JsonKey(name: r'profile_version', required: false, includeIfNull: false)
  final int? profileVersion;

  @JsonKey(name: r'reason', required: false, includeIfNull: false)
  final String? reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImprovementTasteProposal &&
          other.coefficients == coefficients &&
          other.convertible == convertible &&
          other.profileVersion == profileVersion &&
          other.reason == reason;

  @override
  int get hashCode =>
      coefficients.hashCode +
      convertible.hashCode +
      (profileVersion == null ? 0 : profileVersion.hashCode) +
      (reason == null ? 0 : reason.hashCode);

  factory ImprovementTasteProposal.fromJson(Map<String, dynamic> json) =>
      _$ImprovementTasteProposalFromJson(json);

  Map<String, dynamic> toJson() => _$ImprovementTasteProposalToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
