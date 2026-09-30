//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'client_config.g.dart';

/// App 启动时拉取的服务端配置。
///
/// Properties:
/// * [features] 
/// * [params] 
@BuiltValue()
abstract class ClientConfig implements Built<ClientConfig, ClientConfigBuilder> {
  @BuiltValueField(wireName: r'features')
  BuiltMap<bool> get features;

  @BuiltValueField(wireName: r'params')
  BuiltMap<String, JsonObject?> get params;

  ClientConfig._();

  factory ClientConfig([void updates(ClientConfigBuilder b)]) = _$ClientConfig;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ClientConfigBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ClientConfig> get serializer => _$ClientConfigSerializer();
}

class _$ClientConfigSerializer implements PrimitiveSerializer<ClientConfig> {
  @override
  final Iterable<Type> types = const [ClientConfig, _$ClientConfig];

  @override
  final String wireName = r'ClientConfig';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ClientConfig object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'features';
    yield serializers.serialize(
      object.features,
      specifiedType: const FullType(BuiltMap, [FullType(bool)]),
    );
    yield r'params';
    yield serializers.serialize(
      object.params,
      specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ClientConfig object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ClientConfigBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'features':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(bool)]),
          ) as BuiltMap<bool>;
          result.features.replace(valueDes);
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
  ClientConfig deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ClientConfigBuilder();
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

