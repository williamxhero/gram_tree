// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publication_panel.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicationPanelCWProxy {
  PublicationPanel automaticallyPublishes(bool? automaticallyPublishes);

  PublicationPanel baselineVersionId(String? baselineVersionId);

  PublicationPanel cumulativeConclusion(String? cumulativeConclusion);

  PublicationPanel everPublic(bool everPublic);

  PublicationPanel highRisk(bool? highRisk);

  PublicationPanel missing(List<PublicationCondition>? missing);

  PublicationPanel reviewLevel(PublicationPanelReviewLevelEnum reviewLevel);

  PublicationPanel rulesVersion(String? rulesVersion);

  PublicationPanel state(PublicationPanelStateEnum state);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicationPanel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicationPanel(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicationPanel call({
    bool? automaticallyPublishes,
    String? baselineVersionId,
    String? cumulativeConclusion,
    bool everPublic,
    bool? highRisk,
    List<PublicationCondition>? missing,
    PublicationPanelReviewLevelEnum reviewLevel,
    String? rulesVersion,
    PublicationPanelStateEnum state,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicationPanel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicationPanel.copyWith.fieldName(...)`
class _$PublicationPanelCWProxyImpl implements _$PublicationPanelCWProxy {
  const _$PublicationPanelCWProxyImpl(this._value);

  final PublicationPanel _value;

  @override
  PublicationPanel automaticallyPublishes(bool? automaticallyPublishes) =>
      this(automaticallyPublishes: automaticallyPublishes);

  @override
  PublicationPanel baselineVersionId(String? baselineVersionId) =>
      this(baselineVersionId: baselineVersionId);

  @override
  PublicationPanel cumulativeConclusion(String? cumulativeConclusion) =>
      this(cumulativeConclusion: cumulativeConclusion);

  @override
  PublicationPanel everPublic(bool everPublic) => this(everPublic: everPublic);

  @override
  PublicationPanel highRisk(bool? highRisk) => this(highRisk: highRisk);

  @override
  PublicationPanel missing(List<PublicationCondition>? missing) =>
      this(missing: missing);

  @override
  PublicationPanel reviewLevel(PublicationPanelReviewLevelEnum reviewLevel) =>
      this(reviewLevel: reviewLevel);

  @override
  PublicationPanel rulesVersion(String? rulesVersion) =>
      this(rulesVersion: rulesVersion);

  @override
  PublicationPanel state(PublicationPanelStateEnum state) => this(state: state);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicationPanel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicationPanel(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicationPanel call({
    Object? automaticallyPublishes = const $CopyWithPlaceholder(),
    Object? baselineVersionId = const $CopyWithPlaceholder(),
    Object? cumulativeConclusion = const $CopyWithPlaceholder(),
    Object? everPublic = const $CopyWithPlaceholder(),
    Object? highRisk = const $CopyWithPlaceholder(),
    Object? missing = const $CopyWithPlaceholder(),
    Object? reviewLevel = const $CopyWithPlaceholder(),
    Object? rulesVersion = const $CopyWithPlaceholder(),
    Object? state = const $CopyWithPlaceholder(),
  }) {
    return PublicationPanel(
      automaticallyPublishes:
          automaticallyPublishes == const $CopyWithPlaceholder()
          ? _value.automaticallyPublishes
          // ignore: cast_nullable_to_non_nullable
          : automaticallyPublishes as bool?,
      baselineVersionId: baselineVersionId == const $CopyWithPlaceholder()
          ? _value.baselineVersionId
          // ignore: cast_nullable_to_non_nullable
          : baselineVersionId as String?,
      cumulativeConclusion: cumulativeConclusion == const $CopyWithPlaceholder()
          ? _value.cumulativeConclusion
          // ignore: cast_nullable_to_non_nullable
          : cumulativeConclusion as String?,
      everPublic: everPublic == const $CopyWithPlaceholder()
          ? _value.everPublic
          // ignore: cast_nullable_to_non_nullable
          : everPublic as bool,
      highRisk: highRisk == const $CopyWithPlaceholder()
          ? _value.highRisk
          // ignore: cast_nullable_to_non_nullable
          : highRisk as bool?,
      missing: missing == const $CopyWithPlaceholder()
          ? _value.missing
          // ignore: cast_nullable_to_non_nullable
          : missing as List<PublicationCondition>?,
      reviewLevel: reviewLevel == const $CopyWithPlaceholder()
          ? _value.reviewLevel
          // ignore: cast_nullable_to_non_nullable
          : reviewLevel as PublicationPanelReviewLevelEnum,
      rulesVersion: rulesVersion == const $CopyWithPlaceholder()
          ? _value.rulesVersion
          // ignore: cast_nullable_to_non_nullable
          : rulesVersion as String?,
      state: state == const $CopyWithPlaceholder()
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as PublicationPanelStateEnum,
    );
  }
}

extension $PublicationPanelCopyWith on PublicationPanel {
  /// Returns a callable class that can be used as follows: `instanceOfPublicationPanel.copyWith(...)` or like so:`instanceOfPublicationPanel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicationPanelCWProxy get copyWith => _$PublicationPanelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicationPanel _$PublicationPanelFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PublicationPanel',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['ever_public', 'review_level', 'state'],
        );
        final val = PublicationPanel(
          automaticallyPublishes: $checkedConvert(
            'automatically_publishes',
            (v) => v as bool? ?? true,
          ),
          baselineVersionId: $checkedConvert(
            'baseline_version_id',
            (v) => v as String?,
          ),
          cumulativeConclusion: $checkedConvert(
            'cumulative_conclusion',
            (v) => v as String?,
          ),
          everPublic: $checkedConvert('ever_public', (v) => v as bool),
          highRisk: $checkedConvert('high_risk', (v) => v as bool? ?? false),
          missing: $checkedConvert(
            'missing',
            (v) => (v as List<dynamic>?)
                ?.map(
                  (e) =>
                      PublicationCondition.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          ),
          reviewLevel: $checkedConvert(
            'review_level',
            (v) => $enumDecode(_$PublicationPanelReviewLevelEnumEnumMap, v),
          ),
          rulesVersion: $checkedConvert('rules_version', (v) => v as String?),
          state: $checkedConvert(
            'state',
            (v) => $enumDecode(_$PublicationPanelStateEnumEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'automaticallyPublishes': 'automatically_publishes',
        'baselineVersionId': 'baseline_version_id',
        'cumulativeConclusion': 'cumulative_conclusion',
        'everPublic': 'ever_public',
        'highRisk': 'high_risk',
        'reviewLevel': 'review_level',
        'rulesVersion': 'rules_version',
      },
    );

Map<String, dynamic> _$PublicationPanelToJson(PublicationPanel instance) =>
    <String, dynamic>{
      'automatically_publishes': ?instance.automaticallyPublishes,
      'baseline_version_id': ?instance.baselineVersionId,
      'cumulative_conclusion': ?instance.cumulativeConclusion,
      'ever_public': instance.everPublic,
      'high_risk': ?instance.highRisk,
      'missing': ?instance.missing?.map((e) => e.toJson()).toList(),
      'review_level':
          _$PublicationPanelReviewLevelEnumEnumMap[instance.reviewLevel]!,
      'rules_version': ?instance.rulesVersion,
      'state': _$PublicationPanelStateEnumEnumMap[instance.state]!,
    };

const _$PublicationPanelReviewLevelEnumEnumMap = {
  PublicationPanelReviewLevelEnum.standard: 'standard',
  PublicationPanelReviewLevelEnum.high: 'high',
};

const _$PublicationPanelStateEnumEnumMap = {
  PublicationPanelStateEnum.draft: 'draft',
  PublicationPanelStateEnum.published: 'published',
  PublicationPanelStateEnum.pendingVerification: 'pending_verification',
  PublicationPanelStateEnum.withdrawn: 'withdrawn',
};
