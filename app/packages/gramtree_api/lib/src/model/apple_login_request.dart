//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'apple_login_request.g.dart';

/// AppleLoginRequest
///
/// Properties:
/// * [identityToken] 
/// * [authorizationCode] 
/// * [givenName] 
/// * [familyName] 
@BuiltValue()
abstract class AppleLoginRequest implements Built<AppleLoginRequest, AppleLoginRequestBuilder> {
  @BuiltValueField(wireName: r'identity_token')
  String get identityToken;

  @BuiltValueField(wireName: r'authorization_code')
  String? get authorizationCode;

  @BuiltValueField(wireName: r'given_name')
  String? get givenName;

  @BuiltValueField(wireName: r'family_name')
  String? get familyName;

  AppleLoginRequest._();

  factory AppleLoginRequest([void updates(AppleLoginRequestBuilder b)]) = _$AppleLoginRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AppleLoginRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AppleLoginRequest> get serializer => _$AppleLoginRequestSerializer();
}

class _$AppleLoginRequestSerializer implements PrimitiveSerializer<AppleLoginRequest> {
  @override
  final Iterable<Type> types = const [AppleLoginRequest, _$AppleLoginRequest];

  @override
  final String wireName = r'AppleLoginRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AppleLoginRequest object, {
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
    if (object.givenName != null) {
      yield r'given_name';
      yield serializers.serialize(
        object.givenName,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.familyName != null) {
      yield r'family_name';
      yield serializers.serialize(
        object.familyName,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AppleLoginRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AppleLoginRequestBuilder result,
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
        case r'given_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.givenName = valueDes;
          break;
        case r'family_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.familyName = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AppleLoginRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AppleLoginRequestBuilder();
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

