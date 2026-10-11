// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_explanation_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChangeExplanationResultCWProxy {
  ChangeExplanationResult changeNote(String? changeNote);

  ChangeExplanationResult changesFingerprint(String changesFingerprint);

  ChangeExplanationResult error(String? error);

  ChangeExplanationResult source_(ChangeExplanationResultSource_Enum? source_);

  ChangeExplanationResult status(AIStatus status);

  ChangeExplanationResult tags(List<String>? tags);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChangeExplanationResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChangeExplanationResult(...).copyWith(id: 12, name: "My name")
  /// ````
  ChangeExplanationResult call({
    String? changeNote,
    String changesFingerprint,
    String? error,
    ChangeExplanationResultSource_Enum? source_,
    AIStatus status,
    List<String>? tags,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfChangeExplanationResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfChangeExplanationResult.copyWith.fieldName(...)`
class _$ChangeExplanationResultCWProxyImpl
    implements _$ChangeExplanationResultCWProxy {
  const _$ChangeExplanationResultCWProxyImpl(this._value);

  final ChangeExplanationResult _value;

  @override
  ChangeExplanationResult changeNote(String? changeNote) =>
      this(changeNote: changeNote);

  @override
  ChangeExplanationResult changesFingerprint(String changesFingerprint) =>
      this(changesFingerprint: changesFingerprint);

  @override
  ChangeExplanationResult error(String? error) => this(error: error);

  @override
  ChangeExplanationResult source_(
    ChangeExplanationResultSource_Enum? source_,
  ) => this(source_: source_);

  @override
  ChangeExplanationResult status(AIStatus status) => this(status: status);

  @override
  ChangeExplanationResult tags(List<String>? tags) => this(tags: tags);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ChangeExplanationResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ChangeExplanationResult(...).copyWith(id: 12, name: "My name")
  /// ````
  ChangeExplanationResult call({
    Object? changeNote = const $CopyWithPlaceholder(),
    Object? changesFingerprint = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? tags = const $CopyWithPlaceholder(),
  }) {
    return ChangeExplanationResult(
      changeNote: changeNote == const $CopyWithPlaceholder()
          ? _value.changeNote
          // ignore: cast_nullable_to_non_nullable
          : changeNote as String?,
      changesFingerprint: changesFingerprint == const $CopyWithPlaceholder()
          ? _value.changesFingerprint
          // ignore: cast_nullable_to_non_nullable
          : changesFingerprint as String,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as ChangeExplanationResultSource_Enum?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AIStatus,
      tags: tags == const $CopyWithPlaceholder()
          ? _value.tags
          // ignore: cast_nullable_to_non_nullable
          : tags as List<String>?,
    );
  }
}

extension $ChangeExplanationResultCopyWith on ChangeExplanationResult {
  /// Returns a callable class that can be used as follows: `instanceOfChangeExplanationResult.copyWith(...)` or like so:`instanceOfChangeExplanationResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChangeExplanationResultCWProxy get copyWith =>
      _$ChangeExplanationResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangeExplanationResult _$ChangeExplanationResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ChangeExplanationResult',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['changes_fingerprint', 'status']);
    final val = ChangeExplanationResult(
      changeNote: $checkedConvert('change_note', (v) => v as String?),
      changesFingerprint: $checkedConvert(
        'changes_fingerprint',
        (v) => v as String,
      ),
      error: $checkedConvert('error', (v) => v as String?),
      source_: $checkedConvert(
        'source',
        (v) =>
            $enumDecodeNullable(_$ChangeExplanationResultSource_EnumEnumMap, v),
      ),
      status: $checkedConvert(
        'status',
        (v) => AIStatus.fromJson(v as Map<String, dynamic>),
      ),
      tags: $checkedConvert(
        'tags',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'changeNote': 'change_note',
    'changesFingerprint': 'changes_fingerprint',
    'source_': 'source',
  },
);

Map<String, dynamic> _$ChangeExplanationResultToJson(
  ChangeExplanationResult instance,
) => <String, dynamic>{
  'change_note': ?instance.changeNote,
  'changes_fingerprint': instance.changesFingerprint,
  'error': ?instance.error,
  'source': ?_$ChangeExplanationResultSource_EnumEnumMap[instance.source_],
  'status': instance.status.toJson(),
  'tags': ?instance.tags,
};

const _$ChangeExplanationResultSource_EnumEnumMap = {
  ChangeExplanationResultSource_Enum.aiEstimated: 'ai_estimated',
};
