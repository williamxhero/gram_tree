//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'heartbeat_out.g.dart';

/// HeartbeatOut
///
/// Properties:
/// * [id] 
/// * [source_] 
/// * [createdAt] 
@BuiltValue()
abstract class HeartbeatOut implements Built<HeartbeatOut, HeartbeatOutBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'source')
  String get source_;

  @BuiltValueField(wireName: r'created_at')
  String get createdAt;

  HeartbeatOut._();

  factory HeartbeatOut([void updates(HeartbeatOutBuilder b)]) = _$HeartbeatOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(HeartbeatOutBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<HeartbeatOut> get serializer => _$HeartbeatOutSerializer();
}

class _$HeartbeatOutSerializer implements PrimitiveSerializer<HeartbeatOut> {
  @override
  final Iterable<Type> types = const [HeartbeatOut, _$HeartbeatOut];

  @override
  final String wireName = r'HeartbeatOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    HeartbeatOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'source';
    yield serializers.serialize(
      object.source_,
      specifiedType: const FullType(String),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    HeartbeatOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required HeartbeatOutBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.source_ = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  HeartbeatOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = HeartbeatOutBuilder();
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

