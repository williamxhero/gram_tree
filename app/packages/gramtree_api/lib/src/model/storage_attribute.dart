//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/storage_advice.dart';
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/attribute_status.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'storage_attribute.g.dart';

/// StorageAttribute
///
/// Properties:
/// * [source_] - 这项数据的来源
/// * [status] - ai_draft：AI 起草；verified：人工校对过
/// * [value] 
/// * [estimate] - 没经人工校对的字段按估算处理
@BuiltValue()
abstract class StorageAttribute implements Built<StorageAttribute, StorageAttributeBuilder> {
  /// 这项数据的来源
  @BuiltValueField(wireName: r'source')
  String get source_;

  /// ai_draft：AI 起草；verified：人工校对过
  @BuiltValueField(wireName: r'status')
  AttributeStatus get status;
  // enum statusEnum {  ai_draft,  verified,  };

  @BuiltValueField(wireName: r'value')
  BuiltList<StorageAdvice> get value;

  /// 没经人工校对的字段按估算处理
  @BuiltValueField(wireName: r'estimate')
  bool get estimate;

  StorageAttribute._();

  factory StorageAttribute([void updates(StorageAttributeBuilder b)]) = _$StorageAttribute;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(StorageAttributeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<StorageAttribute> get serializer => _$StorageAttributeSerializer();
}

class _$StorageAttributeSerializer implements PrimitiveSerializer<StorageAttribute> {
  @override
  final Iterable<Type> types = const [StorageAttribute, _$StorageAttribute];

  @override
  final String wireName = r'StorageAttribute';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    StorageAttribute object, {
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
      specifiedType: const FullType(BuiltList, [FullType(StorageAdvice)]),
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
    StorageAttribute object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required StorageAttributeBuilder result,
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
            specifiedType: const FullType(BuiltList, [FullType(StorageAdvice)]),
          ) as BuiltList<StorageAdvice>;
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
  StorageAttribute deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = StorageAttributeBuilder();
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

