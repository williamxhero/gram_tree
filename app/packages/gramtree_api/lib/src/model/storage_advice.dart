//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'storage_advice.g.dart';

/// StorageAdvice
///
/// Properties:
/// * [method] - 常温、冷藏或冷冻
/// * [days] - 建议存放天数
@BuiltValue()
abstract class StorageAdvice implements Built<StorageAdvice, StorageAdviceBuilder> {
  /// 常温、冷藏或冷冻
  @BuiltValueField(wireName: r'method')
  String get method;

  /// 建议存放天数
  @BuiltValueField(wireName: r'days')
  int get days;

  StorageAdvice._();

  factory StorageAdvice([void updates(StorageAdviceBuilder b)]) = _$StorageAdvice;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(StorageAdviceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<StorageAdvice> get serializer => _$StorageAdviceSerializer();
}

class _$StorageAdviceSerializer implements PrimitiveSerializer<StorageAdvice> {
  @override
  final Iterable<Type> types = const [StorageAdvice, _$StorageAdvice];

  @override
  final String wireName = r'StorageAdvice';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    StorageAdvice object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'method';
    yield serializers.serialize(
      object.method,
      specifiedType: const FullType(String),
    );
    yield r'days';
    yield serializers.serialize(
      object.days,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    StorageAdvice object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required StorageAdviceBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'method':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.method = valueDes;
          break;
        case r'days':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.days = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  StorageAdvice deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = StorageAdviceBuilder();
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

