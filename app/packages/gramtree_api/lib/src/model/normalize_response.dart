//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/normalize_result_item.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'normalize_response.g.dart';

/// NormalizeResponse
///
/// Properties:
/// * [results] 
@BuiltValue()
abstract class NormalizeResponse implements Built<NormalizeResponse, NormalizeResponseBuilder> {
  @BuiltValueField(wireName: r'results')
  BuiltList<NormalizeResultItem> get results;

  NormalizeResponse._();

  factory NormalizeResponse([void updates(NormalizeResponseBuilder b)]) = _$NormalizeResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NormalizeResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NormalizeResponse> get serializer => _$NormalizeResponseSerializer();
}

class _$NormalizeResponseSerializer implements PrimitiveSerializer<NormalizeResponse> {
  @override
  final Iterable<Type> types = const [NormalizeResponse, _$NormalizeResponse];

  @override
  final String wireName = r'NormalizeResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NormalizeResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'results';
    yield serializers.serialize(
      object.results,
      specifiedType: const FullType(BuiltList, [FullType(NormalizeResultItem)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NormalizeResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NormalizeResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'results':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(NormalizeResultItem)]),
          ) as BuiltList<NormalizeResultItem>;
          result.results.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NormalizeResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NormalizeResponseBuilder();
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

