//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'cache_info.g.dart';

/// CacheInfo
///
/// Properties:
/// * [dependsOn] - 依赖的内容版本
/// * [ttlS] - 缓存有效期（秒）
@BuiltValue()
abstract class CacheInfo implements Built<CacheInfo, CacheInfoBuilder> {
  /// 依赖的内容版本
  @BuiltValueField(wireName: r'depends_on')
  BuiltMap<String>? get dependsOn;

  /// 缓存有效期（秒）
  @BuiltValueField(wireName: r'ttl_s')
  int get ttlS;

  CacheInfo._();

  factory CacheInfo([void updates(CacheInfoBuilder b)]) = _$CacheInfo;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CacheInfoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CacheInfo> get serializer => _$CacheInfoSerializer();
}

class _$CacheInfoSerializer implements PrimitiveSerializer<CacheInfo> {
  @override
  final Iterable<Type> types = const [CacheInfo, _$CacheInfo];

  @override
  final String wireName = r'CacheInfo';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CacheInfo object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.dependsOn != null) {
      yield r'depends_on';
      yield serializers.serialize(
        object.dependsOn,
        specifiedType: const FullType(BuiltMap, [FullType(String)]),
      );
    }
    yield r'ttl_s';
    yield serializers.serialize(
      object.ttlS,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CacheInfo object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CacheInfoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'depends_on':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String)]),
          ) as BuiltMap<String>;
          result.dependsOn.replace(valueDes);
          break;
        case r'ttl_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.ttlS = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CacheInfo deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CacheInfoBuilder();
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

