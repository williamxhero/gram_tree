//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/source_basis.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'sourced_value.g.dart';

/// SourcedValue
///
/// Properties:
/// * [sourceType] 
/// * [value] 
/// * [originalValue] 
/// * [basis] 
@BuiltValue()
abstract class SourcedValue implements Built<SourcedValue, SourcedValueBuilder> {
  @BuiltValueField(wireName: r'source_type')
  SourcedValueSourceTypeEnum get sourceType;
  // enum sourceTypeEnum {  author_filled,  taste_adjusted,  scenario_adjusted,  ai_estimated,  verified,  };

  @BuiltValueField(wireName: r'value')
  String get value;

  @BuiltValueField(wireName: r'original_value')
  String? get originalValue;

  @BuiltValueField(wireName: r'basis')
  SourceBasis get basis;

  SourcedValue._();

  factory SourcedValue([void updates(SourcedValueBuilder b)]) = _$SourcedValue;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SourcedValueBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SourcedValue> get serializer => _$SourcedValueSerializer();
}

class _$SourcedValueSerializer implements PrimitiveSerializer<SourcedValue> {
  @override
  final Iterable<Type> types = const [SourcedValue, _$SourcedValue];

  @override
  final String wireName = r'SourcedValue';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SourcedValue object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'source_type';
    yield serializers.serialize(
      object.sourceType,
      specifiedType: const FullType(SourcedValueSourceTypeEnum),
    );
    yield r'value';
    yield serializers.serialize(
      object.value,
      specifiedType: const FullType(String),
    );
    if (object.originalValue != null) {
      yield r'original_value';
      yield serializers.serialize(
        object.originalValue,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'basis';
    yield serializers.serialize(
      object.basis,
      specifiedType: const FullType(SourceBasis),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SourcedValue object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SourcedValueBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'source_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SourcedValueSourceTypeEnum),
          ) as SourcedValueSourceTypeEnum;
          result.sourceType = valueDes;
          break;
        case r'value':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.value = valueDes;
          break;
        case r'original_value':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.originalValue = valueDes;
          break;
        case r'basis':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SourceBasis),
          ) as SourceBasis;
          result.basis.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SourcedValue deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SourcedValueBuilder();
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

class SourcedValueSourceTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'author_filled')
  static const SourcedValueSourceTypeEnum authorFilled = _$sourcedValueSourceTypeEnum_authorFilled;
  @BuiltValueEnumConst(wireName: r'taste_adjusted')
  static const SourcedValueSourceTypeEnum tasteAdjusted = _$sourcedValueSourceTypeEnum_tasteAdjusted;
  @BuiltValueEnumConst(wireName: r'scenario_adjusted')
  static const SourcedValueSourceTypeEnum scenarioAdjusted = _$sourcedValueSourceTypeEnum_scenarioAdjusted;
  @BuiltValueEnumConst(wireName: r'ai_estimated')
  static const SourcedValueSourceTypeEnum aiEstimated = _$sourcedValueSourceTypeEnum_aiEstimated;
  @BuiltValueEnumConst(wireName: r'verified')
  static const SourcedValueSourceTypeEnum verified = _$sourcedValueSourceTypeEnum_verified;

  static Serializer<SourcedValueSourceTypeEnum> get serializer => _$sourcedValueSourceTypeEnumSerializer;

  const SourcedValueSourceTypeEnum._(String name): super(name);

  static BuiltSet<SourcedValueSourceTypeEnum> get values => _$sourcedValueSourceTypeEnumValues;
  static SourcedValueSourceTypeEnum valueOf(String name) => _$sourcedValueSourceTypeEnumValueOf(name);
}

