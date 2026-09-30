//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/ingredient_out.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'search_result.g.dart';

/// SearchResult
///
/// Properties:
/// * [items] 
@BuiltValue()
abstract class SearchResult implements Built<SearchResult, SearchResultBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<IngredientOut> get items;

  SearchResult._();

  factory SearchResult([void updates(SearchResultBuilder b)]) = _$SearchResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SearchResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SearchResult> get serializer => _$SearchResultSerializer();
}

class _$SearchResultSerializer implements PrimitiveSerializer<SearchResult> {
  @override
  final Iterable<Type> types = const [SearchResult, _$SearchResult];

  @override
  final String wireName = r'SearchResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SearchResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(IngredientOut)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SearchResult object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SearchResultBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(IngredientOut)]),
          ) as BuiltList<IngredientOut>;
          result.items.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SearchResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SearchResultBuilder();
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

