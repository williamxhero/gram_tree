//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'purchase_unit.g.dart';

/// PurchaseUnit
///
/// Properties:
/// * [name] - 购买单位，例如 盒、把、瓶
/// * [grams] - 一个购买单位大约多少克
@BuiltValue()
abstract class PurchaseUnit implements Built<PurchaseUnit, PurchaseUnitBuilder> {
  /// 购买单位，例如 盒、把、瓶
  @BuiltValueField(wireName: r'name')
  String get name;

  /// 一个购买单位大约多少克
  @BuiltValueField(wireName: r'grams')
  num get grams;

  PurchaseUnit._();

  factory PurchaseUnit([void updates(PurchaseUnitBuilder b)]) = _$PurchaseUnit;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PurchaseUnitBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PurchaseUnit> get serializer => _$PurchaseUnitSerializer();
}

class _$PurchaseUnitSerializer implements PrimitiveSerializer<PurchaseUnit> {
  @override
  final Iterable<Type> types = const [PurchaseUnit, _$PurchaseUnit];

  @override
  final String wireName = r'PurchaseUnit';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PurchaseUnit object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
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
    PurchaseUnit object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PurchaseUnitBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
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
  PurchaseUnit deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PurchaseUnitBuilder();
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

