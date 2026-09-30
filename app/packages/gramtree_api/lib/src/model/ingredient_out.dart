//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ingredient_out.g.dart';

/// IngredientOut
///
/// Properties:
/// * [id] 
/// * [standardName] 
/// * [aliases] 
/// * [pinyin] 
/// * [pinyinInitials] 
/// * [category] 
/// * [version] 
@BuiltValue()
abstract class IngredientOut implements Built<IngredientOut, IngredientOutBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'standard_name')
  String get standardName;

  @BuiltValueField(wireName: r'aliases')
  BuiltList<String> get aliases;

  @BuiltValueField(wireName: r'pinyin')
  String get pinyin;

  @BuiltValueField(wireName: r'pinyin_initials')
  String get pinyinInitials;

  @BuiltValueField(wireName: r'category')
  String get category;

  @BuiltValueField(wireName: r'version')
  String get version;

  IngredientOut._();

  factory IngredientOut([void updates(IngredientOutBuilder b)]) = _$IngredientOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(IngredientOutBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<IngredientOut> get serializer => _$IngredientOutSerializer();
}

class _$IngredientOutSerializer implements PrimitiveSerializer<IngredientOut> {
  @override
  final Iterable<Type> types = const [IngredientOut, _$IngredientOut];

  @override
  final String wireName = r'IngredientOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    IngredientOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'standard_name';
    yield serializers.serialize(
      object.standardName,
      specifiedType: const FullType(String),
    );
    yield r'aliases';
    yield serializers.serialize(
      object.aliases,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'pinyin';
    yield serializers.serialize(
      object.pinyin,
      specifiedType: const FullType(String),
    );
    yield r'pinyin_initials';
    yield serializers.serialize(
      object.pinyinInitials,
      specifiedType: const FullType(String),
    );
    yield r'category';
    yield serializers.serialize(
      object.category,
      specifiedType: const FullType(String),
    );
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    IngredientOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required IngredientOutBuilder result,
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
        case r'standard_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.standardName = valueDes;
          break;
        case r'aliases':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.aliases.replace(valueDes);
          break;
        case r'pinyin':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.pinyin = valueDes;
          break;
        case r'pinyin_initials':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.pinyinInitials = valueDes;
          break;
        case r'category':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.category = valueDes;
          break;
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.version = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  IngredientOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = IngredientOutBuilder();
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

