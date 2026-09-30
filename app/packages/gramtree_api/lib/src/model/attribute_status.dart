//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'attribute_status.g.dart';

class AttributeStatus extends EnumClass {

  /// 字段的校对状态。
  @BuiltValueEnumConst(wireName: r'ai_draft')
  static const AttributeStatus aiDraft = _$aiDraft;
  /// 字段的校对状态。
  @BuiltValueEnumConst(wireName: r'verified')
  static const AttributeStatus verified = _$verified;

  static Serializer<AttributeStatus> get serializer => _$attributeStatusSerializer;

  const AttributeStatus._(String name): super(name);

  static BuiltSet<AttributeStatus> get values => _$values;
  static AttributeStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class AttributeStatusMixin = Object with _$AttributeStatusMixin;

