//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/allergens_attribute.dart';
import 'package:gramtree_api/src/model/flavor_attribute.dart';
import 'package:gramtree_api/src/model/text_attribute.dart';
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/count_units_attribute.dart';
import 'package:gramtree_api/src/model/nutrition_attribute.dart';
import 'package:gramtree_api/src/model/purchase_units_attribute.dart';
import 'package:gramtree_api/src/model/storage_attribute.dart';
import 'package:gramtree_api/src/model/bool_attribute.dart';
import 'package:gramtree_api/src/model/density_attribute.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ingredient_attributes.g.dart';

/// 一种食材的全部详细属性，每项都可选；没有数据的项为 null。
///
/// Properties:
/// * [flavor] 
/// * [functional] 
/// * [scaling] 
/// * [baseUnit] 
/// * [density] 
/// * [countUnits] 
/// * [allergens] 
/// * [nutrition] 
/// * [purchaseUnits] 
/// * [marketZone] 
/// * [storage] 
/// * [pantryStaple] 
@BuiltValue()
abstract class IngredientAttributes implements Built<IngredientAttributes, IngredientAttributesBuilder> {
  @BuiltValueField(wireName: r'flavor')
  FlavorAttribute? get flavor;

  @BuiltValueField(wireName: r'functional')
  BoolAttribute? get functional;

  @BuiltValueField(wireName: r'scaling')
  TextAttribute? get scaling;

  @BuiltValueField(wireName: r'base_unit')
  TextAttribute? get baseUnit;

  @BuiltValueField(wireName: r'density')
  DensityAttribute? get density;

  @BuiltValueField(wireName: r'count_units')
  CountUnitsAttribute? get countUnits;

  @BuiltValueField(wireName: r'allergens')
  AllergensAttribute? get allergens;

  @BuiltValueField(wireName: r'nutrition')
  NutritionAttribute? get nutrition;

  @BuiltValueField(wireName: r'purchase_units')
  PurchaseUnitsAttribute? get purchaseUnits;

  @BuiltValueField(wireName: r'market_zone')
  TextAttribute? get marketZone;

  @BuiltValueField(wireName: r'storage')
  StorageAttribute? get storage;

  @BuiltValueField(wireName: r'pantry_staple')
  BoolAttribute? get pantryStaple;

  IngredientAttributes._();

  factory IngredientAttributes([void updates(IngredientAttributesBuilder b)]) = _$IngredientAttributes;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(IngredientAttributesBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<IngredientAttributes> get serializer => _$IngredientAttributesSerializer();
}

class _$IngredientAttributesSerializer implements PrimitiveSerializer<IngredientAttributes> {
  @override
  final Iterable<Type> types = const [IngredientAttributes, _$IngredientAttributes];

  @override
  final String wireName = r'IngredientAttributes';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    IngredientAttributes object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.flavor != null) {
      yield r'flavor';
      yield serializers.serialize(
        object.flavor,
        specifiedType: const FullType.nullable(FlavorAttribute),
      );
    }
    if (object.functional != null) {
      yield r'functional';
      yield serializers.serialize(
        object.functional,
        specifiedType: const FullType.nullable(BoolAttribute),
      );
    }
    if (object.scaling != null) {
      yield r'scaling';
      yield serializers.serialize(
        object.scaling,
        specifiedType: const FullType.nullable(TextAttribute),
      );
    }
    if (object.baseUnit != null) {
      yield r'base_unit';
      yield serializers.serialize(
        object.baseUnit,
        specifiedType: const FullType.nullable(TextAttribute),
      );
    }
    if (object.density != null) {
      yield r'density';
      yield serializers.serialize(
        object.density,
        specifiedType: const FullType.nullable(DensityAttribute),
      );
    }
    if (object.countUnits != null) {
      yield r'count_units';
      yield serializers.serialize(
        object.countUnits,
        specifiedType: const FullType.nullable(CountUnitsAttribute),
      );
    }
    if (object.allergens != null) {
      yield r'allergens';
      yield serializers.serialize(
        object.allergens,
        specifiedType: const FullType.nullable(AllergensAttribute),
      );
    }
    if (object.nutrition != null) {
      yield r'nutrition';
      yield serializers.serialize(
        object.nutrition,
        specifiedType: const FullType.nullable(NutritionAttribute),
      );
    }
    if (object.purchaseUnits != null) {
      yield r'purchase_units';
      yield serializers.serialize(
        object.purchaseUnits,
        specifiedType: const FullType.nullable(PurchaseUnitsAttribute),
      );
    }
    if (object.marketZone != null) {
      yield r'market_zone';
      yield serializers.serialize(
        object.marketZone,
        specifiedType: const FullType.nullable(TextAttribute),
      );
    }
    if (object.storage != null) {
      yield r'storage';
      yield serializers.serialize(
        object.storage,
        specifiedType: const FullType.nullable(StorageAttribute),
      );
    }
    if (object.pantryStaple != null) {
      yield r'pantry_staple';
      yield serializers.serialize(
        object.pantryStaple,
        specifiedType: const FullType.nullable(BoolAttribute),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    IngredientAttributes object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required IngredientAttributesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'flavor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(FlavorAttribute),
          ) as FlavorAttribute?;
          if (valueDes == null) continue;
          result.flavor.replace(valueDes);
          break;
        case r'functional':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BoolAttribute),
          ) as BoolAttribute?;
          if (valueDes == null) continue;
          result.functional.replace(valueDes);
          break;
        case r'scaling':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(TextAttribute),
          ) as TextAttribute?;
          if (valueDes == null) continue;
          result.scaling.replace(valueDes);
          break;
        case r'base_unit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(TextAttribute),
          ) as TextAttribute?;
          if (valueDes == null) continue;
          result.baseUnit.replace(valueDes);
          break;
        case r'density':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DensityAttribute),
          ) as DensityAttribute?;
          if (valueDes == null) continue;
          result.density.replace(valueDes);
          break;
        case r'count_units':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(CountUnitsAttribute),
          ) as CountUnitsAttribute?;
          if (valueDes == null) continue;
          result.countUnits.replace(valueDes);
          break;
        case r'allergens':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(AllergensAttribute),
          ) as AllergensAttribute?;
          if (valueDes == null) continue;
          result.allergens.replace(valueDes);
          break;
        case r'nutrition':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(NutritionAttribute),
          ) as NutritionAttribute?;
          if (valueDes == null) continue;
          result.nutrition.replace(valueDes);
          break;
        case r'purchase_units':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(PurchaseUnitsAttribute),
          ) as PurchaseUnitsAttribute?;
          if (valueDes == null) continue;
          result.purchaseUnits.replace(valueDes);
          break;
        case r'market_zone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(TextAttribute),
          ) as TextAttribute?;
          if (valueDes == null) continue;
          result.marketZone.replace(valueDes);
          break;
        case r'storage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(StorageAttribute),
          ) as StorageAttribute?;
          if (valueDes == null) continue;
          result.storage.replace(valueDes);
          break;
        case r'pantry_staple':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BoolAttribute),
          ) as BoolAttribute?;
          if (valueDes == null) continue;
          result.pantryStaple.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  IngredientAttributes deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = IngredientAttributesBuilder();
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

