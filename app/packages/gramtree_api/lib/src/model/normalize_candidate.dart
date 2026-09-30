//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'normalize_candidate.g.dart';

/// NormalizeCandidate
///
/// Properties:
/// * [ingredientId] 
/// * [standardName] 
@BuiltValue()
abstract class NormalizeCandidate implements Built<NormalizeCandidate, NormalizeCandidateBuilder> {
  @BuiltValueField(wireName: r'ingredient_id')
  String get ingredientId;

  @BuiltValueField(wireName: r'standard_name')
  String get standardName;

  NormalizeCandidate._();

  factory NormalizeCandidate([void updates(NormalizeCandidateBuilder b)]) = _$NormalizeCandidate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NormalizeCandidateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NormalizeCandidate> get serializer => _$NormalizeCandidateSerializer();
}

class _$NormalizeCandidateSerializer implements PrimitiveSerializer<NormalizeCandidate> {
  @override
  final Iterable<Type> types = const [NormalizeCandidate, _$NormalizeCandidate];

  @override
  final String wireName = r'NormalizeCandidate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NormalizeCandidate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'ingredient_id';
    yield serializers.serialize(
      object.ingredientId,
      specifiedType: const FullType(String),
    );
    yield r'standard_name';
    yield serializers.serialize(
      object.standardName,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NormalizeCandidate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NormalizeCandidateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'ingredient_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.ingredientId = valueDes;
          break;
        case r'standard_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.standardName = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NormalizeCandidate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NormalizeCandidateBuilder();
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

