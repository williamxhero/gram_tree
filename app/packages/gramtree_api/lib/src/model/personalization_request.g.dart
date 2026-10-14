// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personalization_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PersonalizationRequestCWProxy {
  PersonalizationRequest confirmAllergyRisk(bool? confirmAllergyRisk);

  PersonalizationRequest dinerMemberIds(List<String>? dinerMemberIds);

  PersonalizationRequest equipment(List<String>? equipment);

  PersonalizationRequest primaryDinerId(String? primaryDinerId);

  PersonalizationRequest targetMold(MoldSpec? targetMold);

  PersonalizationRequest targetServings(int? targetServings);

  PersonalizationRequest versionId(String? versionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PersonalizationRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PersonalizationRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PersonalizationRequest call({
    bool? confirmAllergyRisk,
    List<String>? dinerMemberIds,
    List<String>? equipment,
    String? primaryDinerId,
    MoldSpec? targetMold,
    int? targetServings,
    String? versionId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPersonalizationRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPersonalizationRequest.copyWith.fieldName(...)`
class _$PersonalizationRequestCWProxyImpl
    implements _$PersonalizationRequestCWProxy {
  const _$PersonalizationRequestCWProxyImpl(this._value);

  final PersonalizationRequest _value;

  @override
  PersonalizationRequest confirmAllergyRisk(bool? confirmAllergyRisk) =>
      this(confirmAllergyRisk: confirmAllergyRisk);

  @override
  PersonalizationRequest dinerMemberIds(List<String>? dinerMemberIds) =>
      this(dinerMemberIds: dinerMemberIds);

  @override
  PersonalizationRequest equipment(List<String>? equipment) =>
      this(equipment: equipment);

  @override
  PersonalizationRequest primaryDinerId(String? primaryDinerId) =>
      this(primaryDinerId: primaryDinerId);

  @override
  PersonalizationRequest targetMold(MoldSpec? targetMold) =>
      this(targetMold: targetMold);

  @override
  PersonalizationRequest targetServings(int? targetServings) =>
      this(targetServings: targetServings);

  @override
  PersonalizationRequest versionId(String? versionId) =>
      this(versionId: versionId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PersonalizationRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PersonalizationRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PersonalizationRequest call({
    Object? confirmAllergyRisk = const $CopyWithPlaceholder(),
    Object? dinerMemberIds = const $CopyWithPlaceholder(),
    Object? equipment = const $CopyWithPlaceholder(),
    Object? primaryDinerId = const $CopyWithPlaceholder(),
    Object? targetMold = const $CopyWithPlaceholder(),
    Object? targetServings = const $CopyWithPlaceholder(),
    Object? versionId = const $CopyWithPlaceholder(),
  }) {
    return PersonalizationRequest(
      confirmAllergyRisk: confirmAllergyRisk == const $CopyWithPlaceholder()
          ? _value.confirmAllergyRisk
          // ignore: cast_nullable_to_non_nullable
          : confirmAllergyRisk as bool?,
      dinerMemberIds: dinerMemberIds == const $CopyWithPlaceholder()
          ? _value.dinerMemberIds
          // ignore: cast_nullable_to_non_nullable
          : dinerMemberIds as List<String>?,
      equipment: equipment == const $CopyWithPlaceholder()
          ? _value.equipment
          // ignore: cast_nullable_to_non_nullable
          : equipment as List<String>?,
      primaryDinerId: primaryDinerId == const $CopyWithPlaceholder()
          ? _value.primaryDinerId
          // ignore: cast_nullable_to_non_nullable
          : primaryDinerId as String?,
      targetMold: targetMold == const $CopyWithPlaceholder()
          ? _value.targetMold
          // ignore: cast_nullable_to_non_nullable
          : targetMold as MoldSpec?,
      targetServings: targetServings == const $CopyWithPlaceholder()
          ? _value.targetServings
          // ignore: cast_nullable_to_non_nullable
          : targetServings as int?,
      versionId: versionId == const $CopyWithPlaceholder()
          ? _value.versionId
          // ignore: cast_nullable_to_non_nullable
          : versionId as String?,
    );
  }
}

extension $PersonalizationRequestCopyWith on PersonalizationRequest {
  /// Returns a callable class that can be used as follows: `instanceOfPersonalizationRequest.copyWith(...)` or like so:`instanceOfPersonalizationRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PersonalizationRequestCWProxy get copyWith =>
      _$PersonalizationRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalizationRequest _$PersonalizationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PersonalizationRequest',
  json,
  ($checkedConvert) {
    final val = PersonalizationRequest(
      confirmAllergyRisk: $checkedConvert(
        'confirm_allergy_risk',
        (v) => v as bool? ?? false,
      ),
      dinerMemberIds: $checkedConvert(
        'diner_member_ids',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      equipment: $checkedConvert(
        'equipment',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      primaryDinerId: $checkedConvert('primary_diner_id', (v) => v as String?),
      targetMold: $checkedConvert(
        'target_mold',
        (v) => v == null ? null : MoldSpec.fromJson(v as Map<String, dynamic>),
      ),
      targetServings: $checkedConvert(
        'target_servings',
        (v) => (v as num?)?.toInt(),
      ),
      versionId: $checkedConvert('version_id', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'confirmAllergyRisk': 'confirm_allergy_risk',
    'dinerMemberIds': 'diner_member_ids',
    'primaryDinerId': 'primary_diner_id',
    'targetMold': 'target_mold',
    'targetServings': 'target_servings',
    'versionId': 'version_id',
  },
);

Map<String, dynamic> _$PersonalizationRequestToJson(
  PersonalizationRequest instance,
) => <String, dynamic>{
  'confirm_allergy_risk': ?instance.confirmAllergyRisk,
  'diner_member_ids': ?instance.dinerMemberIds,
  'equipment': ?instance.equipment,
  'primary_diner_id': ?instance.primaryDinerId,
  'target_mold': ?instance.targetMold?.toJson(),
  'target_servings': ?instance.targetServings,
  'version_id': ?instance.versionId,
};
