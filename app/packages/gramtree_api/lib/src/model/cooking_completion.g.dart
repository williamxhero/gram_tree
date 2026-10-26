// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_completion.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CookingCompletionCWProxy {
  CookingCompletion completedSteps(List<String> completedSteps);

  CookingCompletion executionToken(String executionToken);

  CookingCompletion finishedAt(DateTime finishedAt);

  CookingCompletion reachedSteps(List<String> reachedSteps);

  CookingCompletion sessionId(String sessionId);

  CookingCompletion skippedSteps(List<String>? skippedSteps);

  CookingCompletion startedAt(DateTime startedAt);

  CookingCompletion status(CookingCompletionStatusEnum status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingCompletion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingCompletion(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingCompletion call({
    List<String> completedSteps,
    String executionToken,
    DateTime finishedAt,
    List<String> reachedSteps,
    String sessionId,
    List<String>? skippedSteps,
    DateTime startedAt,
    CookingCompletionStatusEnum status,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCookingCompletion.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCookingCompletion.copyWith.fieldName(...)`
class _$CookingCompletionCWProxyImpl implements _$CookingCompletionCWProxy {
  const _$CookingCompletionCWProxyImpl(this._value);

  final CookingCompletion _value;

  @override
  CookingCompletion completedSteps(List<String> completedSteps) =>
      this(completedSteps: completedSteps);

  @override
  CookingCompletion executionToken(String executionToken) =>
      this(executionToken: executionToken);

  @override
  CookingCompletion finishedAt(DateTime finishedAt) =>
      this(finishedAt: finishedAt);

  @override
  CookingCompletion reachedSteps(List<String> reachedSteps) =>
      this(reachedSteps: reachedSteps);

  @override
  CookingCompletion sessionId(String sessionId) => this(sessionId: sessionId);

  @override
  CookingCompletion skippedSteps(List<String>? skippedSteps) =>
      this(skippedSteps: skippedSteps);

  @override
  CookingCompletion startedAt(DateTime startedAt) => this(startedAt: startedAt);

  @override
  CookingCompletion status(CookingCompletionStatusEnum status) =>
      this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CookingCompletion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CookingCompletion(...).copyWith(id: 12, name: "My name")
  /// ````
  CookingCompletion call({
    Object? completedSteps = const $CopyWithPlaceholder(),
    Object? executionToken = const $CopyWithPlaceholder(),
    Object? finishedAt = const $CopyWithPlaceholder(),
    Object? reachedSteps = const $CopyWithPlaceholder(),
    Object? sessionId = const $CopyWithPlaceholder(),
    Object? skippedSteps = const $CopyWithPlaceholder(),
    Object? startedAt = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return CookingCompletion(
      completedSteps: completedSteps == const $CopyWithPlaceholder()
          ? _value.completedSteps
          // ignore: cast_nullable_to_non_nullable
          : completedSteps as List<String>,
      executionToken: executionToken == const $CopyWithPlaceholder()
          ? _value.executionToken
          // ignore: cast_nullable_to_non_nullable
          : executionToken as String,
      finishedAt: finishedAt == const $CopyWithPlaceholder()
          ? _value.finishedAt
          // ignore: cast_nullable_to_non_nullable
          : finishedAt as DateTime,
      reachedSteps: reachedSteps == const $CopyWithPlaceholder()
          ? _value.reachedSteps
          // ignore: cast_nullable_to_non_nullable
          : reachedSteps as List<String>,
      sessionId: sessionId == const $CopyWithPlaceholder()
          ? _value.sessionId
          // ignore: cast_nullable_to_non_nullable
          : sessionId as String,
      skippedSteps: skippedSteps == const $CopyWithPlaceholder()
          ? _value.skippedSteps
          // ignore: cast_nullable_to_non_nullable
          : skippedSteps as List<String>?,
      startedAt: startedAt == const $CopyWithPlaceholder()
          ? _value.startedAt
          // ignore: cast_nullable_to_non_nullable
          : startedAt as DateTime,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as CookingCompletionStatusEnum,
    );
  }
}

extension $CookingCompletionCopyWith on CookingCompletion {
  /// Returns a callable class that can be used as follows: `instanceOfCookingCompletion.copyWith(...)` or like so:`instanceOfCookingCompletion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CookingCompletionCWProxy get copyWith =>
      _$CookingCompletionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CookingCompletion _$CookingCompletionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CookingCompletion',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'completed_steps',
            'execution_token',
            'finished_at',
            'reached_steps',
            'session_id',
            'started_at',
            'status',
          ],
        );
        final val = CookingCompletion(
          completedSteps: $checkedConvert(
            'completed_steps',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          executionToken: $checkedConvert(
            'execution_token',
            (v) => v as String,
          ),
          finishedAt: $checkedConvert(
            'finished_at',
            (v) => DateTime.parse(v as String),
          ),
          reachedSteps: $checkedConvert(
            'reached_steps',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          sessionId: $checkedConvert('session_id', (v) => v as String),
          skippedSteps: $checkedConvert(
            'skipped_steps',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
          startedAt: $checkedConvert(
            'started_at',
            (v) => DateTime.parse(v as String),
          ),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$CookingCompletionStatusEnumEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'completedSteps': 'completed_steps',
        'executionToken': 'execution_token',
        'finishedAt': 'finished_at',
        'reachedSteps': 'reached_steps',
        'sessionId': 'session_id',
        'skippedSteps': 'skipped_steps',
        'startedAt': 'started_at',
      },
    );

Map<String, dynamic> _$CookingCompletionToJson(CookingCompletion instance) =>
    <String, dynamic>{
      'completed_steps': instance.completedSteps,
      'execution_token': instance.executionToken,
      'finished_at': instance.finishedAt.toIso8601String(),
      'reached_steps': instance.reachedSteps,
      'session_id': instance.sessionId,
      'skipped_steps': ?instance.skippedSteps,
      'started_at': instance.startedAt.toIso8601String(),
      'status': _$CookingCompletionStatusEnumEnumMap[instance.status]!,
    };

const _$CookingCompletionStatusEnumEnumMap = {
  CookingCompletionStatusEnum.completed: 'completed',
};
