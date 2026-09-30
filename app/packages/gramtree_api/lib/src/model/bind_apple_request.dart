//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'bind_apple_request.g.dart';

/// BindAppleRequest
///
/// Properties:
/// * [identityToken] 
/// * [authorizationCode] 
@BuiltValue()
abstract class BindAppleRequest implements Built<BindAppleRequest, BindAppleRequestBuilder> {
  @BuiltValueField(wireName: r'identity_token')
  String get identityToken;

  @BuiltValueField(wireName: r'authorization_code')
  String? get authorizationCode;

  BindAppleRequest._();

  factory BindAppleRequest([void updates(BindAppleRequestBuilder b)]) = _$BindAppleRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BindAppleRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BindAppleRequest> get serializer => _$BindAppleRequestSerializer();
}

class _$BindAppleRequestSerializer implements PrimitiveSerializer<BindAppleRequest> {
  @override
  final Iterable<Type> types = const [BindAppleRequest, _$BindAppleRequest];

  @override
  final String wireName = r'BindAppleRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BindAppleRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'identity_token';
    yield serializers.serialize(
      object.identityToken,
      specifiedType: const FullType(String),
    );
    if (object.authorizationCode != null) {
      yield r'authorization_code';
      yield serializers.serialize(
        object.authorizationCode,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    BindAppleRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BindAppleRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'identity_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.identityToken = valueDes;
          break;
        case r'authorization_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.authorizationCode = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BindAppleRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BindAppleRequestBuilder();
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

