// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attribution_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttributionOutCWProxy {
  AttributionOut answered(bool answered);

  AttributionOut asked(bool asked);

  AttributionOut decisionSource(
    AttributionOutDecisionSourceEnum decisionSource,
  );

  AttributionOut flavors(Map<String, int> flavors);

  AttributionOut learningEligibility(
    AttributionOutLearningEligibilityEnum learningEligibility,
  );

  AttributionOut reasonCode(String reasonCode);

  AttributionOut recipeVersionId(String? recipeVersionId);

  AttributionOut recordId(String recordId);

  AttributionOut rulesVersion(String rulesVersion);

  AttributionOut sampleSize(int sampleSize);

  AttributionOut updatedAt(String updatedAt);

  AttributionOut verdict(AttributionOutVerdictEnum verdict);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttributionOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttributionOut(...).copyWith(id: 12, name: "My name")
  /// ````
  AttributionOut call({
    bool answered,
    bool asked,
    AttributionOutDecisionSourceEnum decisionSource,
    Map<String, int> flavors,
    AttributionOutLearningEligibilityEnum learningEligibility,
    String reasonCode,
    String? recipeVersionId,
    String recordId,
    String rulesVersion,
    int sampleSize,
    String updatedAt,
    AttributionOutVerdictEnum verdict,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAttributionOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAttributionOut.copyWith.fieldName(...)`
class _$AttributionOutCWProxyImpl implements _$AttributionOutCWProxy {
  const _$AttributionOutCWProxyImpl(this._value);

  final AttributionOut _value;

  @override
  AttributionOut answered(bool answered) => this(answered: answered);

  @override
  AttributionOut asked(bool asked) => this(asked: asked);

  @override
  AttributionOut decisionSource(
    AttributionOutDecisionSourceEnum decisionSource,
  ) => this(decisionSource: decisionSource);

  @override
  AttributionOut flavors(Map<String, int> flavors) => this(flavors: flavors);

  @override
  AttributionOut learningEligibility(
    AttributionOutLearningEligibilityEnum learningEligibility,
  ) => this(learningEligibility: learningEligibility);

  @override
  AttributionOut reasonCode(String reasonCode) => this(reasonCode: reasonCode);

  @override
  AttributionOut recipeVersionId(String? recipeVersionId) =>
      this(recipeVersionId: recipeVersionId);

  @override
  AttributionOut recordId(String recordId) => this(recordId: recordId);

  @override
  AttributionOut rulesVersion(String rulesVersion) =>
      this(rulesVersion: rulesVersion);

  @override
  AttributionOut sampleSize(int sampleSize) => this(sampleSize: sampleSize);

  @override
  AttributionOut updatedAt(String updatedAt) => this(updatedAt: updatedAt);

  @override
  AttributionOut verdict(AttributionOutVerdictEnum verdict) =>
      this(verdict: verdict);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttributionOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttributionOut(...).copyWith(id: 12, name: "My name")
  /// ````
  AttributionOut call({
    Object? answered = const $CopyWithPlaceholder(),
    Object? asked = const $CopyWithPlaceholder(),
    Object? decisionSource = const $CopyWithPlaceholder(),
    Object? flavors = const $CopyWithPlaceholder(),
    Object? learningEligibility = const $CopyWithPlaceholder(),
    Object? reasonCode = const $CopyWithPlaceholder(),
    Object? recipeVersionId = const $CopyWithPlaceholder(),
    Object? recordId = const $CopyWithPlaceholder(),
    Object? rulesVersion = const $CopyWithPlaceholder(),
    Object? sampleSize = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? verdict = const $CopyWithPlaceholder(),
  }) {
    return AttributionOut(
      answered: answered == const $CopyWithPlaceholder()
          ? _value.answered
          // ignore: cast_nullable_to_non_nullable
          : answered as bool,
      asked: asked == const $CopyWithPlaceholder()
          ? _value.asked
          // ignore: cast_nullable_to_non_nullable
          : asked as bool,
      decisionSource: decisionSource == const $CopyWithPlaceholder()
          ? _value.decisionSource
          // ignore: cast_nullable_to_non_nullable
          : decisionSource as AttributionOutDecisionSourceEnum,
      flavors: flavors == const $CopyWithPlaceholder()
          ? _value.flavors
          // ignore: cast_nullable_to_non_nullable
          : flavors as Map<String, int>,
      learningEligibility: learningEligibility == const $CopyWithPlaceholder()
          ? _value.learningEligibility
          // ignore: cast_nullable_to_non_nullable
          : learningEligibility as AttributionOutLearningEligibilityEnum,
      reasonCode: reasonCode == const $CopyWithPlaceholder()
          ? _value.reasonCode
          // ignore: cast_nullable_to_non_nullable
          : reasonCode as String,
      recipeVersionId: recipeVersionId == const $CopyWithPlaceholder()
          ? _value.recipeVersionId
          // ignore: cast_nullable_to_non_nullable
          : recipeVersionId as String?,
      recordId: recordId == const $CopyWithPlaceholder()
          ? _value.recordId
          // ignore: cast_nullable_to_non_nullable
          : recordId as String,
      rulesVersion: rulesVersion == const $CopyWithPlaceholder()
          ? _value.rulesVersion
          // ignore: cast_nullable_to_non_nullable
          : rulesVersion as String,
      sampleSize: sampleSize == const $CopyWithPlaceholder()
          ? _value.sampleSize
          // ignore: cast_nullable_to_non_nullable
          : sampleSize as int,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as String,
      verdict: verdict == const $CopyWithPlaceholder()
          ? _value.verdict
          // ignore: cast_nullable_to_non_nullable
          : verdict as AttributionOutVerdictEnum,
    );
  }
}

extension $AttributionOutCopyWith on AttributionOut {
  /// Returns a callable class that can be used as follows: `instanceOfAttributionOut.copyWith(...)` or like so:`instanceOfAttributionOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttributionOutCWProxy get copyWith => _$AttributionOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttributionOut _$AttributionOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AttributionOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'answered',
            'asked',
            'decision_source',
            'flavors',
            'learning_eligibility',
            'reason_code',
            'record_id',
            'rules_version',
            'sample_size',
            'updated_at',
            'verdict',
          ],
        );
        final val = AttributionOut(
          answered: $checkedConvert('answered', (v) => v as bool),
          asked: $checkedConvert('asked', (v) => v as bool),
          decisionSource: $checkedConvert(
            'decision_source',
            (v) => $enumDecode(_$AttributionOutDecisionSourceEnumEnumMap, v),
          ),
          flavors: $checkedConvert(
            'flavors',
            (v) => Map<String, int>.from(v as Map),
          ),
          learningEligibility: $checkedConvert(
            'learning_eligibility',
            (v) =>
                $enumDecode(_$AttributionOutLearningEligibilityEnumEnumMap, v),
          ),
          reasonCode: $checkedConvert('reason_code', (v) => v as String),
          recipeVersionId: $checkedConvert(
            'recipe_version_id',
            (v) => v as String?,
          ),
          recordId: $checkedConvert('record_id', (v) => v as String),
          rulesVersion: $checkedConvert('rules_version', (v) => v as String),
          sampleSize: $checkedConvert('sample_size', (v) => (v as num).toInt()),
          updatedAt: $checkedConvert('updated_at', (v) => v as String),
          verdict: $checkedConvert(
            'verdict',
            (v) => $enumDecode(_$AttributionOutVerdictEnumEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'decisionSource': 'decision_source',
        'learningEligibility': 'learning_eligibility',
        'reasonCode': 'reason_code',
        'recipeVersionId': 'recipe_version_id',
        'recordId': 'record_id',
        'rulesVersion': 'rules_version',
        'sampleSize': 'sample_size',
        'updatedAt': 'updated_at',
      },
    );

Map<String, dynamic> _$AttributionOutToJson(AttributionOut instance) =>
    <String, dynamic>{
      'answered': instance.answered,
      'asked': instance.asked,
      'decision_source':
          _$AttributionOutDecisionSourceEnumEnumMap[instance.decisionSource]!,
      'flavors': instance.flavors,
      'learning_eligibility':
          _$AttributionOutLearningEligibilityEnumEnumMap[instance
              .learningEligibility]!,
      'reason_code': instance.reasonCode,
      'recipe_version_id': ?instance.recipeVersionId,
      'record_id': instance.recordId,
      'rules_version': instance.rulesVersion,
      'sample_size': instance.sampleSize,
      'updated_at': instance.updatedAt,
      'verdict': _$AttributionOutVerdictEnumEnumMap[instance.verdict]!,
    };

const _$AttributionOutDecisionSourceEnumEnumMap = {
  AttributionOutDecisionSourceEnum.rule: 'rule',
  AttributionOutDecisionSourceEnum.user: 'user',
  AttributionOutDecisionSourceEnum.unanswered: 'unanswered',
};

const _$AttributionOutLearningEligibilityEnumEnumMap = {
  AttributionOutLearningEligibilityEnum.strong: 'strong',
  AttributionOutLearningEligibilityEnum.reduced: 'reduced',
  AttributionOutLearningEligibilityEnum.excluded: 'excluded',
};

const _$AttributionOutVerdictEnumEnumMap = {
  AttributionOutVerdictEnum.personal: 'personal',
  AttributionOutVerdictEnum.recipe: 'recipe',
  AttributionOutVerdictEnum.pending: 'pending',
};
