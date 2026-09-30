// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_attribute.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NutritionAttributeCWProxy {
  NutritionAttribute estimate(bool estimate);

  NutritionAttribute source_(String source_);

  NutritionAttribute status(AttributeStatus status);

  NutritionAttribute value(Nutrition value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NutritionAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NutritionAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  NutritionAttribute call({
    bool estimate,
    String source_,
    AttributeStatus status,
    Nutrition value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfNutritionAttribute.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfNutritionAttribute.copyWith.fieldName(...)`
class _$NutritionAttributeCWProxyImpl implements _$NutritionAttributeCWProxy {
  const _$NutritionAttributeCWProxyImpl(this._value);

  final NutritionAttribute _value;

  @override
  NutritionAttribute estimate(bool estimate) => this(estimate: estimate);

  @override
  NutritionAttribute source_(String source_) => this(source_: source_);

  @override
  NutritionAttribute status(AttributeStatus status) => this(status: status);

  @override
  NutritionAttribute value(Nutrition value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NutritionAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NutritionAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  NutritionAttribute call({
    Object? estimate = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return NutritionAttribute(
      estimate: estimate == const $CopyWithPlaceholder()
          ? _value.estimate
          // ignore: cast_nullable_to_non_nullable
          : estimate as bool,
      source_: source_ == const $CopyWithPlaceholder()
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AttributeStatus,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as Nutrition,
    );
  }
}

extension $NutritionAttributeCopyWith on NutritionAttribute {
  /// Returns a callable class that can be used as follows: `instanceOfNutritionAttribute.copyWith(...)` or like so:`instanceOfNutritionAttribute.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NutritionAttributeCWProxy get copyWith =>
      _$NutritionAttributeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NutritionAttribute _$NutritionAttributeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NutritionAttribute', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['estimate', 'source', 'status', 'value'],
      );
      final val = NutritionAttribute(
        estimate: $checkedConvert('estimate', (v) => v as bool),
        source_: $checkedConvert('source', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$AttributeStatusEnumMap, v),
        ),
        value: $checkedConvert(
          'value',
          (v) => Nutrition.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$NutritionAttributeToJson(NutritionAttribute instance) =>
    <String, dynamic>{
      'estimate': instance.estimate,
      'source': instance.source_,
      'status': _$AttributeStatusEnumMap[instance.status]!,
      'value': instance.value.toJson(),
    };

const _$AttributeStatusEnumMap = {
  AttributeStatus.aiDraft: 'ai_draft',
  AttributeStatus.verified: 'verified',
};
