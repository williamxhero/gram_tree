//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'count_unit.g.dart';

/// CountUnit
///
/// Properties:
/// * [unit] - 计数单位，例如 个、瓣、根、片
/// * [grams] - 一个这样的单位大约多少克
@BuiltValue()
abstract class CountUnit implements Built<CountUnit, CountUnitBuilder> {
  /// 计数单位，例如 个、瓣、根、片
  @BuiltValueField(wireName: r'unit')
  String get unit;

  /// 一个这样的单位大约多少克
  @BuiltValueField(wireName: r'grams')
  num get grams;

  CountUnit._();

  factory CountUnit([void updates(CountUnitBuilder b)]) = _$CountUnit;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CountUnitBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CountUnit> get serializer => _$CountUnitSerializer();
}

class _$CountUnitSerializer implements PrimitiveSerializer<CountUnit> {
  @override
  final Iterable<Type> types = const [CountUnit, _$CountUnit];

  @override
  final String wireName = r'CountUnit';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CountUnit object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'unit';
    yield serializers.serialize(
      object.unit,
      specifiedType: const FullType(String),
    );
    yield r'grams';
    yield serializers.serialize(
      object.grams,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CountUnit object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CountUnitBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'unit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.unit = valueDes;
          break;
        case r'grams':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.grams = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CountUnit deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CountUnitBuilder();
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

