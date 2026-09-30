//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'normalize_item.g.dart';

/// NormalizeItem
///
/// Properties:
/// * [name] - 菜谱里写的食材名称
/// * [context] 
@BuiltValue()
abstract class NormalizeItem implements Built<NormalizeItem, NormalizeItemBuilder> {
  /// 菜谱里写的食材名称
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'context')
  String? get context;

  NormalizeItem._();

  factory NormalizeItem([void updates(NormalizeItemBuilder b)]) = _$NormalizeItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NormalizeItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NormalizeItem> get serializer => _$NormalizeItemSerializer();
}

class _$NormalizeItemSerializer implements PrimitiveSerializer<NormalizeItem> {
  @override
  final Iterable<Type> types = const [NormalizeItem, _$NormalizeItem];

  @override
  final String wireName = r'NormalizeItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NormalizeItem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    if (object.context != null) {
      yield r'context';
      yield serializers.serialize(
        object.context,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    NormalizeItem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NormalizeItemBuilder result,
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
        case r'context':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.context = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NormalizeItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NormalizeItemBuilder();
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

