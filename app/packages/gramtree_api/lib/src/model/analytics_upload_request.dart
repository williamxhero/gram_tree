//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/analytics_event_in.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'analytics_upload_request.g.dart';

/// AnalyticsUploadRequest
///
/// Properties:
/// * [events] 
@BuiltValue()
abstract class AnalyticsUploadRequest implements Built<AnalyticsUploadRequest, AnalyticsUploadRequestBuilder> {
  @BuiltValueField(wireName: r'events')
  BuiltList<AnalyticsEventIn> get events;

  AnalyticsUploadRequest._();

  factory AnalyticsUploadRequest([void updates(AnalyticsUploadRequestBuilder b)]) = _$AnalyticsUploadRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AnalyticsUploadRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AnalyticsUploadRequest> get serializer => _$AnalyticsUploadRequestSerializer();
}

class _$AnalyticsUploadRequestSerializer implements PrimitiveSerializer<AnalyticsUploadRequest> {
  @override
  final Iterable<Type> types = const [AnalyticsUploadRequest, _$AnalyticsUploadRequest];

  @override
  final String wireName = r'AnalyticsUploadRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AnalyticsUploadRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'events';
    yield serializers.serialize(
      object.events,
      specifiedType: const FullType(BuiltList, [FullType(AnalyticsEventIn)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AnalyticsUploadRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AnalyticsUploadRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'events':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(AnalyticsEventIn)]),
          ) as BuiltList<AnalyticsEventIn>;
          result.events.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AnalyticsUploadRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AnalyticsUploadRequestBuilder();
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

