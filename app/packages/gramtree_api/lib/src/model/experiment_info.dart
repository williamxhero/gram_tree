//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'experiment_info.g.dart';

/// ExperimentInfo
///
/// Properties:
/// * [experiment] 
/// * [variant] 
@BuiltValue()
abstract class ExperimentInfo implements Built<ExperimentInfo, ExperimentInfoBuilder> {
  @BuiltValueField(wireName: r'experiment')
  String get experiment;

  @BuiltValueField(wireName: r'variant')
  String get variant;

  ExperimentInfo._();

  factory ExperimentInfo([void updates(ExperimentInfoBuilder b)]) = _$ExperimentInfo;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ExperimentInfoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ExperimentInfo> get serializer => _$ExperimentInfoSerializer();
}

class _$ExperimentInfoSerializer implements PrimitiveSerializer<ExperimentInfo> {
  @override
  final Iterable<Type> types = const [ExperimentInfo, _$ExperimentInfo];

  @override
  final String wireName = r'ExperimentInfo';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ExperimentInfo object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'experiment';
    yield serializers.serialize(
      object.experiment,
      specifiedType: const FullType(String),
    );
    yield r'variant';
    yield serializers.serialize(
      object.variant,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ExperimentInfo object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ExperimentInfoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'experiment':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.experiment = valueDes;
          break;
        case r'variant':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.variant = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ExperimentInfo deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ExperimentInfoBuilder();
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

