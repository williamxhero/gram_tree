//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'health_checks.g.dart';

/// HealthChecks
///
/// Properties:
/// * [api] 
/// * [database] 
/// * [redis] 
@BuiltValue()
abstract class HealthChecks implements Built<HealthChecks, HealthChecksBuilder> {
  @BuiltValueField(wireName: r'api')
  HealthChecksApiEnum get api;
  // enum apiEnum {  ok,  fail,  };

  @BuiltValueField(wireName: r'database')
  HealthChecksDatabaseEnum get database;
  // enum databaseEnum {  ok,  fail,  };

  @BuiltValueField(wireName: r'redis')
  HealthChecksRedisEnum get redis;
  // enum redisEnum {  ok,  fail,  };

  HealthChecks._();

  factory HealthChecks([void updates(HealthChecksBuilder b)]) = _$HealthChecks;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(HealthChecksBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<HealthChecks> get serializer => _$HealthChecksSerializer();
}

class _$HealthChecksSerializer implements PrimitiveSerializer<HealthChecks> {
  @override
  final Iterable<Type> types = const [HealthChecks, _$HealthChecks];

  @override
  final String wireName = r'HealthChecks';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    HealthChecks object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'api';
    yield serializers.serialize(
      object.api,
      specifiedType: const FullType(HealthChecksApiEnum),
    );
    yield r'database';
    yield serializers.serialize(
      object.database,
      specifiedType: const FullType(HealthChecksDatabaseEnum),
    );
    yield r'redis';
    yield serializers.serialize(
      object.redis,
      specifiedType: const FullType(HealthChecksRedisEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    HealthChecks object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required HealthChecksBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'api':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(HealthChecksApiEnum),
          ) as HealthChecksApiEnum;
          result.api = valueDes;
          break;
        case r'database':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(HealthChecksDatabaseEnum),
          ) as HealthChecksDatabaseEnum;
          result.database = valueDes;
          break;
        case r'redis':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(HealthChecksRedisEnum),
          ) as HealthChecksRedisEnum;
          result.redis = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  HealthChecks deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = HealthChecksBuilder();
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

class HealthChecksApiEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ok')
  static const HealthChecksApiEnum ok = _$healthChecksApiEnum_ok;
  @BuiltValueEnumConst(wireName: r'fail')
  static const HealthChecksApiEnum fail = _$healthChecksApiEnum_fail;

  static Serializer<HealthChecksApiEnum> get serializer => _$healthChecksApiEnumSerializer;

  const HealthChecksApiEnum._(String name): super(name);

  static BuiltSet<HealthChecksApiEnum> get values => _$healthChecksApiEnumValues;
  static HealthChecksApiEnum valueOf(String name) => _$healthChecksApiEnumValueOf(name);
}

class HealthChecksDatabaseEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ok')
  static const HealthChecksDatabaseEnum ok = _$healthChecksDatabaseEnum_ok;
  @BuiltValueEnumConst(wireName: r'fail')
  static const HealthChecksDatabaseEnum fail = _$healthChecksDatabaseEnum_fail;

  static Serializer<HealthChecksDatabaseEnum> get serializer => _$healthChecksDatabaseEnumSerializer;

  const HealthChecksDatabaseEnum._(String name): super(name);

  static BuiltSet<HealthChecksDatabaseEnum> get values => _$healthChecksDatabaseEnumValues;
  static HealthChecksDatabaseEnum valueOf(String name) => _$healthChecksDatabaseEnumValueOf(name);
}

class HealthChecksRedisEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ok')
  static const HealthChecksRedisEnum ok = _$healthChecksRedisEnum_ok;
  @BuiltValueEnumConst(wireName: r'fail')
  static const HealthChecksRedisEnum fail = _$healthChecksRedisEnum_fail;

  static Serializer<HealthChecksRedisEnum> get serializer => _$healthChecksRedisEnumSerializer;

  const HealthChecksRedisEnum._(String name): super(name);

  static BuiltSet<HealthChecksRedisEnum> get values => _$healthChecksRedisEnumValues;
  static HealthChecksRedisEnum valueOf(String name) => _$healthChecksRedisEnumValueOf(name);
}

