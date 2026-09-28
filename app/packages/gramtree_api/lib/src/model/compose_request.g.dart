// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compose_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComposeRequestCWProxy {
  ComposeRequest pageType(String pageType);

  ComposeRequest protocolVersion(String protocolVersion);

  ComposeRequest supportedComponents(List<String>? supportedComponents);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComposeRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComposeRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ComposeRequest call({
    String pageType,
    String protocolVersion,
    List<String>? supportedComponents,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComposeRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComposeRequest.copyWith.fieldName(...)`
class _$ComposeRequestCWProxyImpl implements _$ComposeRequestCWProxy {
  const _$ComposeRequestCWProxyImpl(this._value);

  final ComposeRequest _value;

  @override
  ComposeRequest pageType(String pageType) => this(pageType: pageType);

  @override
  ComposeRequest protocolVersion(String protocolVersion) =>
      this(protocolVersion: protocolVersion);

  @override
  ComposeRequest supportedComponents(List<String>? supportedComponents) =>
      this(supportedComponents: supportedComponents);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComposeRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComposeRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ComposeRequest call({
    Object? pageType = const $CopyWithPlaceholder(),
    Object? protocolVersion = const $CopyWithPlaceholder(),
    Object? supportedComponents = const $CopyWithPlaceholder(),
  }) {
    return ComposeRequest(
      pageType: pageType == const $CopyWithPlaceholder()
          ? _value.pageType
          // ignore: cast_nullable_to_non_nullable
          : pageType as String,
      protocolVersion: protocolVersion == const $CopyWithPlaceholder()
          ? _value.protocolVersion
          // ignore: cast_nullable_to_non_nullable
          : protocolVersion as String,
      supportedComponents: supportedComponents == const $CopyWithPlaceholder()
          ? _value.supportedComponents
          // ignore: cast_nullable_to_non_nullable
          : supportedComponents as List<String>?,
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

ComposeRequest _$ComposeRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ComposeRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['page_type', 'protocol_version']);
        final val = ComposeRequest(
          pageType: $checkedConvert('page_type', (v) => v as String),
          protocolVersion: $checkedConvert(
            'protocol_version',
            (v) => v as String,
          ),
          supportedComponents: $checkedConvert(
            'supported_components',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'pageType': 'page_type',
        'protocolVersion': 'protocol_version',
        'supportedComponents': 'supported_components',
      },
    );

Map<String, dynamic> _$ComposeRequestToJson(ComposeRequest instance) =>
    <String, dynamic>{
      'page_type': instance.pageType,
      'protocol_version': instance.protocolVersion,
      'supported_components': ?instance.supportedComponents,
    };
