//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'search_query.g.dart';

/// SearchQuery
///
/// Properties:
/// * [query] 
@BuiltValue()
abstract class SearchQuery implements Built<SearchQuery, SearchQueryBuilder> {
  @BuiltValueField(wireName: r'query')
  String get query;

  SearchQuery._();

  factory SearchQuery([void updates(SearchQueryBuilder b)]) = _$SearchQuery;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SearchQueryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SearchQuery> get serializer => _$SearchQuerySerializer();
}

class _$SearchQuerySerializer implements PrimitiveSerializer<SearchQuery> {
  @override
  final Iterable<Type> types = const [SearchQuery, _$SearchQuery];

  @override
  final String wireName = r'SearchQuery';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SearchQuery object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'query';
    yield serializers.serialize(
      object.query,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SearchQuery object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SearchQueryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'query':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.query = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SearchQuery deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SearchQueryBuilder();
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

