//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/sourced_value.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'skip_adjustment_result.g.dart';

/// \"这次不用\"的返回：去掉这条调整后的来源字段，只影响这次查看，不写口味档案。
///
/// Properties:
/// * [componentId] 
/// * [source_] 
@BuiltValue()
abstract class SkipAdjustmentResult implements Built<SkipAdjustmentResult, SkipAdjustmentResultBuilder> {
  @BuiltValueField(wireName: r'component_id')
  String get componentId;

  @BuiltValueField(wireName: r'source')
  SourcedValue get source_;

  SkipAdjustmentResult._();

  factory SkipAdjustmentResult([void updates(SkipAdjustmentResultBuilder b)]) = _$SkipAdjustmentResult;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SkipAdjustmentResultBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SkipAdjustmentResult> get serializer => _$SkipAdjustmentResultSerializer();
}

class _$SkipAdjustmentResultSerializer implements PrimitiveSerializer<SkipAdjustmentResult> {
  @override
  final Iterable<Type> types = const [SkipAdjustmentResult, _$SkipAdjustmentResult];

  @override
  final String wireName = r'SkipAdjustmentResult';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SkipAdjustmentResult object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'component_id';
    yield serializers.serialize(
      object.componentId,
      specifiedType: const FullType(String),
    );
    yield r'source';
    yield serializers.serialize(
      object.source_,
      specifiedType: const FullType(SourcedValue),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SkipAdjustmentResult object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SkipAdjustmentResultBuilder result,
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
        case r'source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SourcedValue),
          ) as SourcedValue;
          result.source_.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SkipAdjustmentResult deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SkipAdjustmentResultBuilder();
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

