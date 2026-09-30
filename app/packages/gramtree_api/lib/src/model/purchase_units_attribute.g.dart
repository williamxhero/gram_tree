// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_units_attribute.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PurchaseUnitsAttributeCWProxy {
  PurchaseUnitsAttribute estimate(bool estimate);

  PurchaseUnitsAttribute source_(String source_);

  PurchaseUnitsAttribute status(AttributeStatus status);

  PurchaseUnitsAttribute value(List<PurchaseUnit> value);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PurchaseUnitsAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PurchaseUnitsAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  PurchaseUnitsAttribute call({
    bool estimate,
    String source_,
    AttributeStatus status,
    List<PurchaseUnit> value,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPurchaseUnitsAttribute.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPurchaseUnitsAttribute.copyWith.fieldName(...)`
class _$PurchaseUnitsAttributeCWProxyImpl
    implements _$PurchaseUnitsAttributeCWProxy {
  const _$PurchaseUnitsAttributeCWProxyImpl(this._value);

  final PurchaseUnitsAttribute _value;

  @override
  PurchaseUnitsAttribute estimate(bool estimate) => this(estimate: estimate);

  @override
  PurchaseUnitsAttribute source_(String source_) => this(source_: source_);

  @override
  PurchaseUnitsAttribute status(AttributeStatus status) => this(status: status);

  @override
  PurchaseUnitsAttribute value(List<PurchaseUnit> value) => this(value: value);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PurchaseUnitsAttribute(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PurchaseUnitsAttribute(...).copyWith(id: 12, name: "My name")
  /// ````
  PurchaseUnitsAttribute call({
    Object? estimate = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return PurchaseUnitsAttribute(
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
          : value as List<PurchaseUnit>,
    );
  }
}

extension $PurchaseUnitsAttributeCopyWith on PurchaseUnitsAttribute {
  /// Returns a callable class that can be used as follows: `instanceOfPurchaseUnitsAttribute.copyWith(...)` or like so:`instanceOfPurchaseUnitsAttribute.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PurchaseUnitsAttributeCWProxy get copyWith =>
      _$PurchaseUnitsAttributeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseUnitsAttribute _$PurchaseUnitsAttributeFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PurchaseUnitsAttribute', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['estimate', 'source', 'status', 'value'],
  );
  final val = PurchaseUnitsAttribute(
    estimate: $checkedConvert('estimate', (v) => v as bool),
    source_: $checkedConvert('source', (v) => v as String),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$AttributeStatusEnumMap, v),
    ),
    value: $checkedConvert(
      'value',
      (v) => (v as List<dynamic>)
          .map((e) => PurchaseUnit.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$PurchaseUnitsAttributeToJson(
  PurchaseUnitsAttribute instance,
) => <String, dynamic>{
  'estimate': instance.estimate,
  'source': instance.source_,
  'status': _$AttributeStatusEnumMap[instance.status]!,
  'value': instance.value.map((e) => e.toJson()).toList(),
};

const _$AttributeStatusEnumMap = {
  AttributeStatus.aiDraft: 'ai_draft',
  AttributeStatus.verified: 'verified',
};
