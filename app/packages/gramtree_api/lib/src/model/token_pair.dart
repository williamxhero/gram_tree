//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/user_out.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'token_pair.g.dart';

/// TokenPair
///
/// Properties:
/// * [accessToken] 
/// * [accessExpiresIn] - 访问令牌多少秒后过期
/// * [refreshToken] - 续期用；每次续期都会换发新的，旧的立即作废
/// * [user] 
@BuiltValue()
abstract class TokenPair implements Built<TokenPair, TokenPairBuilder> {
  @BuiltValueField(wireName: r'access_token')
  String get accessToken;

  /// 访问令牌多少秒后过期
  @BuiltValueField(wireName: r'access_expires_in')
  int get accessExpiresIn;

  /// 续期用；每次续期都会换发新的，旧的立即作废
  @BuiltValueField(wireName: r'refresh_token')
  String get refreshToken;

  @BuiltValueField(wireName: r'user')
  UserOut get user;

  TokenPair._();

  factory TokenPair([void updates(TokenPairBuilder b)]) = _$TokenPair;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TokenPairBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TokenPair> get serializer => _$TokenPairSerializer();
}

class _$TokenPairSerializer implements PrimitiveSerializer<TokenPair> {
  @override
  final Iterable<Type> types = const [TokenPair, _$TokenPair];

  @override
  final String wireName = r'TokenPair';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TokenPair object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'access_token';
    yield serializers.serialize(
      object.accessToken,
      specifiedType: const FullType(String),
    );
    yield r'access_expires_in';
    yield serializers.serialize(
      object.accessExpiresIn,
      specifiedType: const FullType(int),
    );
    yield r'refresh_token';
    yield serializers.serialize(
      object.refreshToken,
      specifiedType: const FullType(String),
    );
    yield r'user';
    yield serializers.serialize(
      object.user,
      specifiedType: const FullType(UserOut),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TokenPair object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TokenPairBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'access_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.accessToken = valueDes;
          break;
        case r'access_expires_in':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.accessExpiresIn = valueDes;
          break;
        case r'refresh_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.refreshToken = valueDes;
          break;
        case r'user':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UserOut),
          ) as UserOut;
          result.user.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TokenPair deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TokenPairBuilder();
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

