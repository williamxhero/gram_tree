//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'sample_create.g.dart';

/// SampleCreate
///
/// Properties:
/// * [id] - 客户端生成的 UUID v4
/// * [title] 
@BuiltValue()
abstract class SampleCreate implements Built<SampleCreate, SampleCreateBuilder> {
  /// 客户端生成的 UUID v4
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'title')
  String get title;

  SampleCreate._();

  factory SampleCreate([void updates(SampleCreateBuilder b)]) = _$SampleCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SampleCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SampleCreate> get serializer => _$SampleCreateSerializer();
}

class _$SampleCreateSerializer implements PrimitiveSerializer<SampleCreate> {
  @override
  final Iterable<Type> types = const [SampleCreate, _$SampleCreate];

  @override
  final String wireName = r'SampleCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SampleCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SampleCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SampleCreateBuilder result,
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
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SampleCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SampleCreateBuilder();
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

