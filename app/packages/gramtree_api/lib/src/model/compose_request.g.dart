// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compose_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComposeRequestCWProxy {
  ComposeRequest beforeChangeId(String? beforeChangeId);

  ComposeRequest detailOverride(
    ComposeRequestDetailOverrideEnum? detailOverride,
  );

  ComposeRequest pageType(String pageType);

  ComposeRequest personalization(PersonalizationRequest? personalization);

  ComposeRequest personalizationView(
    ComposeRequestPersonalizationViewEnum personalizationView,
  );

  ComposeRequest protocolVersion(String protocolVersion);

  ComposeRequest recipeId(String? recipeId);

  ComposeRequest screenWidth(int? screenWidth);

  ComposeRequest skippedComponents(List<String>? skippedComponents);

  ComposeRequest supportedComponents(List<String>? supportedComponents);

  ComposeRequest versionId(String? versionId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComposeRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComposeRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ComposeRequest call({
    String? beforeChangeId,
    ComposeRequestDetailOverrideEnum? detailOverride,
    String pageType,
    PersonalizationRequest? personalization,
    ComposeRequestPersonalizationViewEnum personalizationView,
    String protocolVersion,
    String? recipeId,
    int? screenWidth,
    List<String>? skippedComponents,
    List<String>? supportedComponents,
    String? versionId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComposeRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComposeRequest.copyWith.fieldName(...)`
class _$ComposeRequestCWProxyImpl implements _$ComposeRequestCWProxy {
  const _$ComposeRequestCWProxyImpl(this._value);

  final ComposeRequest _value;

  @override
  ComposeRequest beforeChangeId(String? beforeChangeId) =>
      this(beforeChangeId: beforeChangeId);

  @override
  ComposeRequest detailOverride(
    ComposeRequestDetailOverrideEnum? detailOverride,
  ) => this(detailOverride: detailOverride);

  @override
  ComposeRequest pageType(String pageType) => this(pageType: pageType);

  @override
  ComposeRequest personalization(PersonalizationRequest? personalization) =>
      this(personalization: personalization);

  @override
  ComposeRequest personalizationView(
    ComposeRequestPersonalizationViewEnum personalizationView,
  ) => this(personalizationView: personalizationView);

  @override
  ComposeRequest protocolVersion(String protocolVersion) =>
      this(protocolVersion: protocolVersion);

  @override
  ComposeRequest recipeId(String? recipeId) => this(recipeId: recipeId);

  @override
  ComposeRequest screenWidth(int? screenWidth) =>
      this(screenWidth: screenWidth);

  @override
  ComposeRequest skippedComponents(List<String>? skippedComponents) =>
      this(skippedComponents: skippedComponents);

  @override
  ComposeRequest supportedComponents(List<String>? supportedComponents) =>
      this(supportedComponents: supportedComponents);

  @override
  ComposeRequest versionId(String? versionId) => this(versionId: versionId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComposeRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComposeRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ComposeRequest call({
    Object? beforeChangeId = const $CopyWithPlaceholder(),
    Object? detailOverride = const $CopyWithPlaceholder(),
    Object? pageType = const $CopyWithPlaceholder(),
    Object? personalization = const $CopyWithPlaceholder(),
    Object? personalizationView = const $CopyWithPlaceholder(),
    Object? protocolVersion = const $CopyWithPlaceholder(),
    Object? recipeId = const $CopyWithPlaceholder(),
    Object? screenWidth = const $CopyWithPlaceholder(),
    Object? skippedComponents = const $CopyWithPlaceholder(),
    Object? supportedComponents = const $CopyWithPlaceholder(),
    Object? versionId = const $CopyWithPlaceholder(),
  }) {
    return ComposeRequest(
      beforeChangeId: beforeChangeId == const $CopyWithPlaceholder()
          ? _value.beforeChangeId
          // ignore: cast_nullable_to_non_nullable
          : beforeChangeId as String?,
      detailOverride: detailOverride == const $CopyWithPlaceholder()
          ? _value.detailOverride
          // ignore: cast_nullable_to_non_nullable
          : detailOverride as ComposeRequestDetailOverrideEnum?,
      pageType: pageType == const $CopyWithPlaceholder()
          ? _value.pageType
          // ignore: cast_nullable_to_non_nullable
          : pageType as String,
      personalization: personalization == const $CopyWithPlaceholder()
          ? _value.personalization
          // ignore: cast_nullable_to_non_nullable
          : personalization as PersonalizationRequest?,
      personalizationView: personalizationView == const $CopyWithPlaceholder()
          ? _value.personalizationView
          // ignore: cast_nullable_to_non_nullable
          : personalizationView as ComposeRequestPersonalizationViewEnum,
      protocolVersion: protocolVersion == const $CopyWithPlaceholder()
          ? _value.protocolVersion
          // ignore: cast_nullable_to_non_nullable
          : protocolVersion as String,
      recipeId: recipeId == const $CopyWithPlaceholder()
          ? _value.recipeId
          // ignore: cast_nullable_to_non_nullable
          : recipeId as String?,
      screenWidth: screenWidth == const $CopyWithPlaceholder()
          ? _value.screenWidth
          // ignore: cast_nullable_to_non_nullable
          : screenWidth as int?,
      skippedComponents: skippedComponents == const $CopyWithPlaceholder()
          ? _value.skippedComponents
          // ignore: cast_nullable_to_non_nullable
          : skippedComponents as List<String>?,
      supportedComponents: supportedComponents == const $CopyWithPlaceholder()
          ? _value.supportedComponents
          // ignore: cast_nullable_to_non_nullable
          : supportedComponents as List<String>?,
      versionId: versionId == const $CopyWithPlaceholder()
          ? _value.versionId
          // ignore: cast_nullable_to_non_nullable
          : versionId as String?,
    );
  }
}

extension $ComposeRequestCopyWith on ComposeRequest {
  /// Returns a callable class that can be used as follows: `instanceOfComposeRequest.copyWith(...)` or like so:`instanceOfComposeRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComposeRequestCWProxy get copyWith => _$ComposeRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComposeRequest _$ComposeRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ComposeRequest',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'page_type',
        'personalization_view',
        'protocol_version',
      ],
    );
    final val = ComposeRequest(
      beforeChangeId: $checkedConvert('before_change_id', (v) => v as String?),
      detailOverride: $checkedConvert(
        'detail_override',
        (v) =>
            $enumDecodeNullable(_$ComposeRequestDetailOverrideEnumEnumMap, v),
      ),
      pageType: $checkedConvert('page_type', (v) => v as String),
      personalization: $checkedConvert(
        'personalization',
        (v) => v == null
            ? null
            : PersonalizationRequest.fromJson(v as Map<String, dynamic>),
      ),
      personalizationView: $checkedConvert(
        'personalization_view',
        (v) => $enumDecode(_$ComposeRequestPersonalizationViewEnumEnumMap, v),
      ),
      protocolVersion: $checkedConvert('protocol_version', (v) => v as String),
      recipeId: $checkedConvert('recipe_id', (v) => v as String?),
      screenWidth: $checkedConvert(
        'screen_width',
        (v) => (v as num?)?.toInt() ?? 400,
      ),
      skippedComponents: $checkedConvert(
        'skipped_components',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      supportedComponents: $checkedConvert(
        'supported_components',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      versionId: $checkedConvert('version_id', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'beforeChangeId': 'before_change_id',
    'detailOverride': 'detail_override',
    'pageType': 'page_type',
    'personalizationView': 'personalization_view',
    'protocolVersion': 'protocol_version',
    'recipeId': 'recipe_id',
    'screenWidth': 'screen_width',
    'skippedComponents': 'skipped_components',
    'supportedComponents': 'supported_components',
    'versionId': 'version_id',
  },
);

Map<String, dynamic> _$ComposeRequestToJson(ComposeRequest instance) =>
    <String, dynamic>{
      'before_change_id': ?instance.beforeChangeId,
      'detail_override':
          ?_$ComposeRequestDetailOverrideEnumEnumMap[instance.detailOverride],
      'page_type': instance.pageType,
      'personalization': ?instance.personalization?.toJson(),
      'personalization_view':
          _$ComposeRequestPersonalizationViewEnumEnumMap[instance
              .personalizationView]!,
      'protocol_version': instance.protocolVersion,
      'recipe_id': ?instance.recipeId,
      'screen_width': ?instance.screenWidth,
      'skipped_components': ?instance.skippedComponents,
      'supported_components': ?instance.supportedComponents,
      'version_id': ?instance.versionId,
    };

const _$ComposeRequestDetailOverrideEnumEnumMap = {
  ComposeRequestDetailOverrideEnum.auto: 'auto',
  ComposeRequestDetailOverrideEnum.brief: 'brief',
  ComposeRequestDetailOverrideEnum.detailed: 'detailed',
};

const _$ComposeRequestPersonalizationViewEnumEnumMap = {
  ComposeRequestPersonalizationViewEnum.personalized: 'personalized',
  ComposeRequestPersonalizationViewEnum.original: 'original',
};
