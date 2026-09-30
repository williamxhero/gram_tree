//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/count_unit.dart';
import 'package:gramtree_api/src/model/attribute_status.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'count_units_attribute.g.dart';

/// CountUnitsAttribute
///
/// Properties:
/// * [source_] - 这项数据的来源
/// * [status] - ai_draft：AI 起草；verified：人工校对过
/// * [value] 
/// * [estimate] - 没经人工校对的字段按估算处理
@BuiltValue()
abstract class CountUnitsAttribute implements Built<CountUnitsAttribute, CountUnitsAttributeBuilder> {
  /// 这项数据的来源
  @BuiltValueField(wireName: r'source')
  String get source_;

  /// ai_draft：AI 起草；verified：人工校对过
  @BuiltValueField(wireName: r'status')
  AttributeStatus get status;
  // enum statusEnum {  ai_draft,  verified,  };

  @BuiltValueField(wireName: r'value')
  BuiltList<CountUnit> get value;

  /// 没经人工校对的字段按估算处理
  @BuiltValueField(wireName: r'estimate')
  bool get estimate;

  CountUnitsAttribute._();

  factory CountUnitsAttribute([void updates(CountUnitsAttributeBuilder b)]) = _$CountUnitsAttribute;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CountUnitsAttributeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CountUnitsAttribute> get serializer => _$CountUnitsAttributeSerializer();
}

class _$CountUnitsAttributeSerializer implements PrimitiveSerializer<CountUnitsAttribute> {
  @override
  final Iterable<Type> types = const [CountUnitsAttribute, _$CountUnitsAttribute];

  @override
  final String wireName = r'CountUnitsAttribute';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CountUnitsAttribute object, {
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
      specifiedType: const FullType(BuiltList, [FullType(CountUnit)]),
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
    CountUnitsAttribute object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CountUnitsAttributeBuilder result,
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
            specifiedType: const FullType(BuiltList, [FullType(CountUnit)]),
          ) as BuiltList<CountUnit>;
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
  CountUnitsAttribute deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CountUnitsAttributeBuilder();
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

