// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'improvement_taste_proposal.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ImprovementTasteProposalCWProxy {
  ImprovementTasteProposal coefficients(Map<String, num>? coefficients);

  ImprovementTasteProposal convertible(bool convertible);

  ImprovementTasteProposal profileVersion(int? profileVersion);

  ImprovementTasteProposal reason(String? reason);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImprovementTasteProposal(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImprovementTasteProposal(...).copyWith(id: 12, name: "My name")
  /// ````
  ImprovementTasteProposal call({
    Map<String, num>? coefficients,
    bool convertible,
    int? profileVersion,
    String? reason,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfImprovementTasteProposal.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfImprovementTasteProposal.copyWith.fieldName(...)`
class _$ImprovementTasteProposalCWProxyImpl
    implements _$ImprovementTasteProposalCWProxy {
  const _$ImprovementTasteProposalCWProxyImpl(this._value);

  final ImprovementTasteProposal _value;

  @override
  ImprovementTasteProposal coefficients(Map<String, num>? coefficients) =>
      this(coefficients: coefficients);

  @override
  ImprovementTasteProposal convertible(bool convertible) =>
      this(convertible: convertible);

  @override
  ImprovementTasteProposal profileVersion(int? profileVersion) =>
      this(profileVersion: profileVersion);

  @override
  ImprovementTasteProposal reason(String? reason) => this(reason: reason);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ImprovementTasteProposal(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ImprovementTasteProposal(...).copyWith(id: 12, name: "My name")
  /// ````
  ImprovementTasteProposal call({
    Object? coefficients = const $CopyWithPlaceholder(),
    Object? convertible = const $CopyWithPlaceholder(),
    Object? profileVersion = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return ImprovementTasteProposal(
      coefficients: coefficients == const $CopyWithPlaceholder()
          ? _value.coefficients
          // ignore: cast_nullable_to_non_nullable
          : coefficients as Map<String, num>?,
      convertible: convertible == const $CopyWithPlaceholder()
          ? _value.convertible
          // ignore: cast_nullable_to_non_nullable
          : convertible as bool,
      profileVersion: profileVersion == const $CopyWithPlaceholder()
          ? _value.profileVersion
          // ignore: cast_nullable_to_non_nullable
          : profileVersion as int?,
      reason: reason == const $CopyWithPlaceholder()
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String?,
    );
  }
}

extension $ImprovementTasteProposalCopyWith on ImprovementTasteProposal {
  /// Returns a callable class that can be used as follows: `instanceOfImprovementTasteProposal.copyWith(...)` or like so:`instanceOfImprovementTasteProposal.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ImprovementTasteProposalCWProxy get copyWith =>
      _$ImprovementTasteProposalCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImprovementTasteProposal _$ImprovementTasteProposalFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ImprovementTasteProposal', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['convertible']);
  final val = ImprovementTasteProposal(
    coefficients: $checkedConvert(
      'coefficients',
      (v) => (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as num)),
    ),
    convertible: $checkedConvert('convertible', (v) => v as bool),
    profileVersion: $checkedConvert(
      'profile_version',
      (v) => (v as num?)?.toInt(),
    ),
    reason: $checkedConvert('reason', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'profileVersion': 'profile_version'});

Map<String, dynamic> _$ImprovementTasteProposalToJson(
  ImprovementTasteProposal instance,
) => <String, dynamic>{
  'coefficients': ?instance.coefficients,
  'convertible': instance.convertible,
  'profile_version': ?instance.profileVersion,
  'reason': ?instance.reason,
};
