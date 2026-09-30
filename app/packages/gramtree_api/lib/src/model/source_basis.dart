//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'source_basis.g.dart';

/// 依据：只用等级、日期这类用户看得懂的信息，不含内部分数或精确统计 （SPEC-010 开放边界，#82 明确要求）。
///
/// Properties:
/// * [reasonCode] - 理由代码，供程序判断用
/// * [text] - 一句大白话说明
/// * [citation] 
@BuiltValue()
abstract class SourceBasis implements Built<SourceBasis, SourceBasisBuilder> {
  /// 理由代码，供程序判断用
  @BuiltValueField(wireName: r'reason_code')
  String get reasonCode;

  /// 一句大白话说明
  @BuiltValueField(wireName: r'text')
  String get text;

  @BuiltValueField(wireName: r'citation')
  String? get citation;

  SourceBasis._();

  factory SourceBasis([void updates(SourceBasisBuilder b)]) = _$SourceBasis;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SourceBasisBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SourceBasis> get serializer => _$SourceBasisSerializer();
}

class _$SourceBasisSerializer implements PrimitiveSerializer<SourceBasis> {
  @override
  final Iterable<Type> types = const [SourceBasis, _$SourceBasis];

  @override
  final String wireName = r'SourceBasis';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SourceBasis object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'reason_code';
    yield serializers.serialize(
      object.reasonCode,
      specifiedType: const FullType(String),
    );
    yield r'text';
    yield serializers.serialize(
      object.text,
      specifiedType: const FullType(String),
    );
    if (object.citation != null) {
      yield r'citation';
      yield serializers.serialize(
        object.citation,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SourceBasis object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SourceBasisBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reasonCode = valueDes;
          break;
        case r'text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.text = valueDes;
          break;
        case r'citation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.citation = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SourceBasis deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SourceBasisBuilder();
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

