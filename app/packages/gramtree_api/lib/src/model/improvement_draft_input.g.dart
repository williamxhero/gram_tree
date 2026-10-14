// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'improvement_draft_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImprovementDraftInputCWProxy {
  ImprovementDraftInput sourceVersionId(String sourceVersionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImprovementDraftInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImprovementDraftInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ImprovementDraftInput call({String sourceVersionId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfImprovementDraftInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfImprovementDraftInput.copyWith.fieldName(...)`
class _$ImprovementDraftInputCWProxyImpl
    implements _$ImprovementDraftInputCWProxy {
  const _$ImprovementDraftInputCWProxyImpl(this._value);

  final ImprovementDraftInput _value;

  @override
  ImprovementDraftInput sourceVersionId(String sourceVersionId) =>
      this(sourceVersionId: sourceVersionId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImprovementDraftInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImprovementDraftInput(...).copyWith(id: 12, name: "My name")
  /// ````
  ImprovementDraftInput call({
    Object? sourceVersionId = const $CopyWithPlaceholder(),
  }) {
    return ImprovementDraftInput(
      sourceVersionId: sourceVersionId == const $CopyWithPlaceholder()
          ? _value.sourceVersionId
          // ignore: cast_nullable_to_non_nullable
          : sourceVersionId as String,
    );
  }
}

extension $ImprovementDraftInputCopyWith on ImprovementDraftInput {
  /// Returns a callable class that can be used as follows: `instanceOfImprovementDraftInput.copyWith(...)` or like so:`instanceOfImprovementDraftInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImprovementDraftInputCWProxy get copyWith =>
      _$ImprovementDraftInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImprovementDraftInput _$ImprovementDraftInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ImprovementDraftInput', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['source_version_id']);
  final val = ImprovementDraftInput(
    sourceVersionId: $checkedConvert('source_version_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'sourceVersionId': 'source_version_id'});

Map<String, dynamic> _$ImprovementDraftInputToJson(
  ImprovementDraftInput instance,
) => <String, dynamic>{'source_version_id': instance.sourceVersionId};
