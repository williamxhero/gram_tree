// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_mold_conversion_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RecipeMoldConversionRequestCWProxy {
  RecipeMoldConversionRequest targetMold(MoldSpec targetMold);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeMoldConversionRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeMoldConversionRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeMoldConversionRequest call({MoldSpec targetMold});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRecipeMoldConversionRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRecipeMoldConversionRequest.copyWith.fieldName(...)`
class _$RecipeMoldConversionRequestCWProxyImpl
    implements _$RecipeMoldConversionRequestCWProxy {
  const _$RecipeMoldConversionRequestCWProxyImpl(this._value);

  final RecipeMoldConversionRequest _value;

  @override
  RecipeMoldConversionRequest targetMold(MoldSpec targetMold) =>
      this(targetMold: targetMold);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RecipeMoldConversionRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RecipeMoldConversionRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  RecipeMoldConversionRequest call({
    Object? targetMold = const $CopyWithPlaceholder(),
  }) {
    return RecipeMoldConversionRequest(
      targetMold: targetMold == const $CopyWithPlaceholder()
          ? _value.targetMold
          // ignore: cast_nullable_to_non_nullable
          : targetMold as MoldSpec,
    );
  }
}

extension $RecipeMoldConversionRequestCopyWith on RecipeMoldConversionRequest {
  /// Returns a callable class that can be used as follows: `instanceOfRecipeMoldConversionRequest.copyWith(...)` or like so:`instanceOfRecipeMoldConversionRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RecipeMoldConversionRequestCWProxy get copyWith =>
      _$RecipeMoldConversionRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeMoldConversionRequest _$RecipeMoldConversionRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RecipeMoldConversionRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['target_mold']);
  final val = RecipeMoldConversionRequest(
    targetMold: $checkedConvert(
      'target_mold',
      (v) => MoldSpec.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'targetMold': 'target_mold'});

Map<String, dynamic> _$RecipeMoldConversionRequestToJson(
  RecipeMoldConversionRequest instance,
) => <String, dynamic>{'target_mold': instance.targetMold.toJson()};
