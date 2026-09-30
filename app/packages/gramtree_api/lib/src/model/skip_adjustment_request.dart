//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'skip_adjustment_request.g.dart';

/// SkipAdjustmentRequest
///
/// Properties:
/// * [componentId] - 要去掉来源调整的组件实例 ID
@BuiltValue()
abstract class SkipAdjustmentRequest implements Built<SkipAdjustmentRequest, SkipAdjustmentRequestBuilder> {
  /// 要去掉来源调整的组件实例 ID
  @BuiltValueField(wireName: r'component_id')
  String get componentId;

  SkipAdjustmentRequest._();

  factory SkipAdjustmentRequest([void updates(SkipAdjustmentRequestBuilder b)]) = _$SkipAdjustmentRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SkipAdjustmentRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SkipAdjustmentRequest> get serializer => _$SkipAdjustmentRequestSerializer();
}

class _$SkipAdjustmentRequestSerializer implements PrimitiveSerializer<SkipAdjustmentRequest> {
  @override
  final Iterable<Type> types = const [SkipAdjustmentRequest, _$SkipAdjustmentRequest];

  @override
  final String wireName = r'SkipAdjustmentRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SkipAdjustmentRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'component_id';
    yield serializers.serialize(
      object.componentId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SkipAdjustmentRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SkipAdjustmentRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'component_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.componentId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SkipAdjustmentRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SkipAdjustmentRequestBuilder();
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

