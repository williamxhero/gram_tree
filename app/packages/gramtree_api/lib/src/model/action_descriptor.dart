//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'action_descriptor.g.dart';

/// ActionDescriptor
///
/// Properties:
/// * [intent] - 已登记的意图名（SPEC-009.1 #81）
/// * [params] 
@BuiltValue()
abstract class ActionDescriptor implements Built<ActionDescriptor, ActionDescriptorBuilder> {
  /// 已登记的意图名（SPEC-009.1 #81）
  @BuiltValueField(wireName: r'intent')
  String get intent;

  @BuiltValueField(wireName: r'params')
  BuiltMap<String, JsonObject?>? get params;

  ActionDescriptor._();

  factory ActionDescriptor([void updates(ActionDescriptorBuilder b)]) = _$ActionDescriptor;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ActionDescriptorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ActionDescriptor> get serializer => _$ActionDescriptorSerializer();
}

class _$ActionDescriptorSerializer implements PrimitiveSerializer<ActionDescriptor> {
  @override
  final Iterable<Type> types = const [ActionDescriptor, _$ActionDescriptor];

  @override
  final String wireName = r'ActionDescriptor';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ActionDescriptor object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'intent';
    yield serializers.serialize(
      object.intent,
      specifiedType: const FullType(String),
    );
    if (object.params != null) {
      yield r'params';
      yield serializers.serialize(
        object.params,
        specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ActionDescriptor object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ActionDescriptorBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'intent':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.intent = valueDes;
          break;
        case r'params':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>;
          result.params.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ActionDescriptor deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ActionDescriptorBuilder();
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

