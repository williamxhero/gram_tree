//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'nutrition.g.dart';

/// 每 100 克的营养，缺失的项留空。
///
/// Properties:
/// * [energyKcal] 
/// * [proteinG] 
/// * [fatG] 
/// * [carbohydrateG] 
/// * [sodiumMg] 
@BuiltValue()
abstract class Nutrition implements Built<Nutrition, NutritionBuilder> {
  @BuiltValueField(wireName: r'energy_kcal')
  num? get energyKcal;

  @BuiltValueField(wireName: r'protein_g')
  num? get proteinG;

  @BuiltValueField(wireName: r'fat_g')
  num? get fatG;

  @BuiltValueField(wireName: r'carbohydrate_g')
  num? get carbohydrateG;

  @BuiltValueField(wireName: r'sodium_mg')
  num? get sodiumMg;

  Nutrition._();

  factory Nutrition([void updates(NutritionBuilder b)]) = _$Nutrition;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NutritionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Nutrition> get serializer => _$NutritionSerializer();
}

class _$NutritionSerializer implements PrimitiveSerializer<Nutrition> {
  @override
  final Iterable<Type> types = const [Nutrition, _$Nutrition];

  @override
  final String wireName = r'Nutrition';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Nutrition object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.energyKcal != null) {
      yield r'energy_kcal';
      yield serializers.serialize(
        object.energyKcal,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.proteinG != null) {
      yield r'protein_g';
      yield serializers.serialize(
        object.proteinG,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.fatG != null) {
      yield r'fat_g';
      yield serializers.serialize(
        object.fatG,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.carbohydrateG != null) {
      yield r'carbohydrate_g';
      yield serializers.serialize(
        object.carbohydrateG,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.sodiumMg != null) {
      yield r'sodium_mg';
      yield serializers.serialize(
        object.sodiumMg,
        specifiedType: const FullType.nullable(num),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    Nutrition object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NutritionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'energy_kcal':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.energyKcal = valueDes;
          break;
        case r'protein_g':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.proteinG = valueDes;
          break;
        case r'fat_g':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.fatG = valueDes;
          break;
        case r'carbohydrate_g':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.carbohydrateG = valueDes;
          break;
        case r'sodium_mg':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.sodiumMg = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Nutrition deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NutritionBuilder();
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

