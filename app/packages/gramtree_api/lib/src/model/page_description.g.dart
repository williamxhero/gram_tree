// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_description.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PageDescriptionCWProxy {
  PageDescription cache(CacheInfo cache);

  PageDescription components(List<ComponentDescriptor>? components);

  PageDescription compositionId(String compositionId);

  PageDescription experiment(ExperimentInfo? experiment);

  PageDescription fallback(FallbackInfo? fallback);

  PageDescription generatedAt(String generatedAt);

  PageDescription pageType(String pageType);

  PageDescription protocol(String protocol);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PageDescription(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PageDescription(...).copyWith(id: 12, name: "My name")
  /// ````
  PageDescription call({
    CacheInfo cache,
    List<ComponentDescriptor>? components,
    String compositionId,
    ExperimentInfo? experiment,
    FallbackInfo? fallback,
    String generatedAt,
    String pageType,
    String protocol,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPageDescription.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPageDescription.copyWith.fieldName(...)`
class _$PageDescriptionCWProxyImpl implements _$PageDescriptionCWProxy {
  const _$PageDescriptionCWProxyImpl(this._value);

  final PageDescription _value;

  @override
  PageDescription cache(CacheInfo cache) => this(cache: cache);

  @override
  PageDescription components(List<ComponentDescriptor>? components) =>
      this(components: components);

  @override
  PageDescription compositionId(String compositionId) =>
      this(compositionId: compositionId);

  @override
  PageDescription experiment(ExperimentInfo? experiment) =>
      this(experiment: experiment);

  @override
  PageDescription fallback(FallbackInfo? fallback) => this(fallback: fallback);

  @override
  PageDescription generatedAt(String generatedAt) =>
      this(generatedAt: generatedAt);

  @override
  PageDescription pageType(String pageType) => this(pageType: pageType);

  @override
  PageDescription protocol(String protocol) => this(protocol: protocol);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PageDescription(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PageDescription(...).copyWith(id: 12, name: "My name")
  /// ````
  PageDescription call({
    Object? cache = const $CopyWithPlaceholder(),
    Object? components = const $CopyWithPlaceholder(),
    Object? compositionId = const $CopyWithPlaceholder(),
    Object? experiment = const $CopyWithPlaceholder(),
    Object? fallback = const $CopyWithPlaceholder(),
    Object? generatedAt = const $CopyWithPlaceholder(),
    Object? pageType = const $CopyWithPlaceholder(),
    Object? protocol = const $CopyWithPlaceholder(),
  }) {
    return PageDescription(
      cache: cache == const $CopyWithPlaceholder()
          ? _value.cache
          // ignore: cast_nullable_to_non_nullable
          : cache as CacheInfo,
      components: components == const $CopyWithPlaceholder()
          ? _value.components
          // ignore: cast_nullable_to_non_nullable
          : components as List<ComponentDescriptor>?,
      compositionId: compositionId == const $CopyWithPlaceholder()
          ? _value.compositionId
          // ignore: cast_nullable_to_non_nullable
          : compositionId as String,
      experiment: experiment == const $CopyWithPlaceholder()
          ? _value.experiment
          // ignore: cast_nullable_to_non_nullable
          : experiment as ExperimentInfo?,
      fallback: fallback == const $CopyWithPlaceholder()
          ? _value.fallback
          // ignore: cast_nullable_to_non_nullable
          : fallback as FallbackInfo?,
      generatedAt: generatedAt == const $CopyWithPlaceholder()
          ? _value.generatedAt
          // ignore: cast_nullable_to_non_nullable
          : generatedAt as String,
      pageType: pageType == const $CopyWithPlaceholder()
          ? _value.pageType
          // ignore: cast_nullable_to_non_nullable
          : pageType as String,
      protocol: protocol == const $CopyWithPlaceholder()
          ? _value.protocol
          // ignore: cast_nullable_to_non_nullable
          : protocol as String,
    );
  }
}

extension $PageDescriptionCopyWith on PageDescription {
  /// Returns a callable class that can be used as follows: `instanceOfPageDescription.copyWith(...)` or like so:`instanceOfPageDescription.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PageDescriptionCWProxy get copyWith => _$PageDescriptionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageDescription _$PageDescriptionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PageDescription',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'cache',
            'composition_id',
            'generated_at',
            'page_type',
            'protocol',
          ],
        );
        final val = PageDescription(
          cache: $checkedConvert(
            'cache',
            (v) => CacheInfo.fromJson(v as Map<String, dynamic>),
          ),
          components: $checkedConvert(
            'components',
            (v) => (v as List<dynamic>?)
                ?.map(
                  (e) =>
                      ComponentDescriptor.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          ),
          compositionId: $checkedConvert('composition_id', (v) => v as String),
          experiment: $checkedConvert(
            'experiment',
            (v) => v == null
                ? null
                : ExperimentInfo.fromJson(v as Map<String, dynamic>),
          ),
          fallback: $checkedConvert(
            'fallback',
            (v) => v == null
                ? null
                : FallbackInfo.fromJson(v as Map<String, dynamic>),
          ),
          generatedAt: $checkedConvert('generated_at', (v) => v as String),
          pageType: $checkedConvert('page_type', (v) => v as String),
          protocol: $checkedConvert('protocol', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'compositionId': 'composition_id',
        'generatedAt': 'generated_at',
        'pageType': 'page_type',
      },
    );

Map<String, dynamic> _$PageDescriptionToJson(PageDescription instance) =>
    <String, dynamic>{
      'cache': instance.cache.toJson(),
      'components': ?instance.components?.map((e) => e.toJson()).toList(),
      'composition_id': instance.compositionId,
      'experiment': ?instance.experiment?.toJson(),
      'fallback': ?instance.fallback?.toJson(),
      'generated_at': instance.generatedAt,
      'page_type': instance.pageType,
      'protocol': instance.protocol,
    };
