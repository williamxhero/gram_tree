//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/normalize_item.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'normalize_request.g.dart';

/// NormalizeRequest
///
/// Properties:
/// * [items] 
@BuiltValue()
abstract class NormalizeRequest implements Built<NormalizeRequest, NormalizeRequestBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<NormalizeItem> get items;

  NormalizeRequest._();

  factory NormalizeRequest([void updates(NormalizeRequestBuilder b)]) = _$NormalizeRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NormalizeRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NormalizeRequest> get serializer => _$NormalizeRequestSerializer();
}

class _$NormalizeRequestSerializer implements PrimitiveSerializer<NormalizeRequest> {
  @override
  final Iterable<Type> types = const [NormalizeRequest, _$NormalizeRequest];

  @override
  final String wireName = r'NormalizeRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NormalizeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(NormalizeItem)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NormalizeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NormalizeRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(NormalizeItem)]),
          ) as BuiltList<NormalizeItem>;
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
  NormalizeRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NormalizeRequestBuilder();
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

