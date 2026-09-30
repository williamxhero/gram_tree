//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/purchase_unit.dart';
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/attribute_status.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'purchase_units_attribute.g.dart';

/// PurchaseUnitsAttribute
///
/// Properties:
/// * [source_] - 这项数据的来源
/// * [status] - ai_draft：AI 起草；verified：人工校对过
/// * [value] 
/// * [estimate] - 没经人工校对的字段按估算处理
@BuiltValue()
abstract class PurchaseUnitsAttribute implements Built<PurchaseUnitsAttribute, PurchaseUnitsAttributeBuilder> {
  /// 这项数据的来源
  @BuiltValueField(wireName: r'source')
  String get source_;

  /// ai_draft：AI 起草；verified：人工校对过
  @BuiltValueField(wireName: r'status')
  AttributeStatus get status;
  // enum statusEnum {  ai_draft,  verified,  };

  @BuiltValueField(wireName: r'value')
  BuiltList<PurchaseUnit> get value;

  /// 没经人工校对的字段按估算处理
  @BuiltValueField(wireName: r'estimate')
  bool get estimate;

  PurchaseUnitsAttribute._();

  factory PurchaseUnitsAttribute([void updates(PurchaseUnitsAttributeBuilder b)]) = _$PurchaseUnitsAttribute;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PurchaseUnitsAttributeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PurchaseUnitsAttribute> get serializer => _$PurchaseUnitsAttributeSerializer();
}

class _$PurchaseUnitsAttributeSerializer implements PrimitiveSerializer<PurchaseUnitsAttribute> {
  @override
  final Iterable<Type> types = const [PurchaseUnitsAttribute, _$PurchaseUnitsAttribute];

  @override
  final String wireName = r'PurchaseUnitsAttribute';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PurchaseUnitsAttribute object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'source';
    yield serializers.serialize(
      object.source_,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(AttributeStatus),
    );
    yield r'value';
    yield serializers.serialize(
      object.value,
      specifiedType: const FullType(BuiltList, [FullType(PurchaseUnit)]),
    );
    yield r'estimate';
    yield serializers.serialize(
      object.estimate,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PurchaseUnitsAttribute object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PurchaseUnitsAttributeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.source_ = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AttributeStatus),
          ) as AttributeStatus;
          result.status = valueDes;
          break;
        case r'value':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PurchaseUnit)]),
          ) as BuiltList<PurchaseUnit>;
          result.value.replace(valueDes);
          break;
        case r'estimate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.estimate = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PurchaseUnitsAttribute deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PurchaseUnitsAttributeBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

