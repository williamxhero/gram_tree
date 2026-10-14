//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/publication_condition.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'publication_panel.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicationPanel {
  /// Returns a new [PublicationPanel] instance.
  PublicationPanel({
    this.automaticallyPublishes = true,

    this.baselineVersionId,

    this.cumulativeConclusion,

    required this.everPublic,

    this.highRisk = false,

    this.missing,

    required this.reviewLevel,

    this.rulesVersion,

    required this.state,
  });

  @JsonKey(
    defaultValue: true,
    name: r'automatically_publishes',
    required: false,
    includeIfNull: false,
  )
  final bool? automaticallyPublishes;

  @JsonKey(name: r'baseline_version_id', required: false, includeIfNull: false)
  final String? baselineVersionId;

  @JsonKey(
    name: r'cumulative_conclusion',
    required: false,
    includeIfNull: false,
  )
  final String? cumulativeConclusion;

  @JsonKey(name: r'ever_public', required: true, includeIfNull: false)
  final bool everPublic;

  @JsonKey(
    defaultValue: false,
    name: r'high_risk',
    required: false,
    includeIfNull: false,
  )
  final bool? highRisk;

  @JsonKey(name: r'missing', required: false, includeIfNull: false)
  final List<PublicationCondition>? missing;

  @JsonKey(name: r'review_level', required: true, includeIfNull: false)
  final PublicationPanelReviewLevelEnum reviewLevel;

  @JsonKey(name: r'rules_version', required: false, includeIfNull: false)
  final String? rulesVersion;

  @JsonKey(name: r'state', required: true, includeIfNull: false)
  final PublicationPanelStateEnum state;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicationPanel &&
          other.automaticallyPublishes == automaticallyPublishes &&
          other.baselineVersionId == baselineVersionId &&
          other.cumulativeConclusion == cumulativeConclusion &&
          other.everPublic == everPublic &&
          other.highRisk == highRisk &&
          other.missing == missing &&
          other.reviewLevel == reviewLevel &&
          other.rulesVersion == rulesVersion &&
          other.state == state;

  @override
  int get hashCode =>
      automaticallyPublishes.hashCode +
      (baselineVersionId == null ? 0 : baselineVersionId.hashCode) +
      (cumulativeConclusion == null ? 0 : cumulativeConclusion.hashCode) +
      everPublic.hashCode +
      highRisk.hashCode +
      missing.hashCode +
      reviewLevel.hashCode +
      (rulesVersion == null ? 0 : rulesVersion.hashCode) +
      state.hashCode;

  factory PublicationPanel.fromJson(Map<String, dynamic> json) =>
      _$PublicationPanelFromJson(json);

  Map<String, dynamic> toJson() => _$PublicationPanelToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum PublicationPanelReviewLevelEnum {
  @JsonValue(r'standard')
  standard(r'standard'),
  @JsonValue(r'high')
  high(r'high');

  const PublicationPanelReviewLevelEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum PublicationPanelStateEnum {
  @JsonValue(r'draft')
  draft(r'draft'),
  @JsonValue(r'published')
  published(r'published'),
  @JsonValue(r'pending_verification')
  pendingVerification(r'pending_verification'),
  @JsonValue(r'withdrawn')
  withdrawn(r'withdrawn');

  const PublicationPanelStateEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
