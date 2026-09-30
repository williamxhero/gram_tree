//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/event_upload_result_item.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'event_upload_response.g.dart';

/// EventUploadResponse
///
/// Properties:
/// * [results] 
@BuiltValue()
abstract class EventUploadResponse implements Built<EventUploadResponse, EventUploadResponseBuilder> {
  @BuiltValueField(wireName: r'results')
  BuiltList<EventUploadResultItem> get results;

  EventUploadResponse._();

  factory EventUploadResponse([void updates(EventUploadResponseBuilder b)]) = _$EventUploadResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EventUploadResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EventUploadResponse> get serializer => _$EventUploadResponseSerializer();
}

class _$EventUploadResponseSerializer implements PrimitiveSerializer<EventUploadResponse> {
  @override
  final Iterable<Type> types = const [EventUploadResponse, _$EventUploadResponse];

  @override
  final String wireName = r'EventUploadResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EventUploadResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'results';
    yield serializers.serialize(
      object.results,
      specifiedType: const FullType(BuiltList, [FullType(EventUploadResultItem)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EventUploadResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EventUploadResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'results':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(EventUploadResultItem)]),
          ) as BuiltList<EventUploadResultItem>;
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
  EventUploadResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EventUploadResponseBuilder();
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

