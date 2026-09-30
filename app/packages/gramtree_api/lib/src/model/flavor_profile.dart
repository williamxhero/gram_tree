//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'flavor_profile.g.dart';

/// 味型贡献：单位用量下的相对强度，0～3，没写的项是 0。
///
/// Properties:
/// * [salty] - 咸
/// * [sweet] - 甜
/// * [sour] - 酸
/// * [spicy] - 辣
/// * [umami] - 鲜
/// * [numbing] - 麻
/// * [oily] - 油
@BuiltValue()
abstract class FlavorProfile implements Built<FlavorProfile, FlavorProfileBuilder> {
  /// 咸
  @BuiltValueField(wireName: r'salty')
  int? get salty;

  /// 甜
  @BuiltValueField(wireName: r'sweet')
  int? get sweet;

  /// 酸
  @BuiltValueField(wireName: r'sour')
  int? get sour;

  /// 辣
  @BuiltValueField(wireName: r'spicy')
  int? get spicy;

  /// 鲜
  @BuiltValueField(wireName: r'umami')
  int? get umami;

  /// 麻
  @BuiltValueField(wireName: r'numbing')
  int? get numbing;

  /// 油
  @BuiltValueField(wireName: r'oily')
  int? get oily;

  FlavorProfile._();

  factory FlavorProfile([void updates(FlavorProfileBuilder b)]) = _$FlavorProfile;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FlavorProfileBuilder b) => b
      ..salty = 0
      ..sweet = 0
      ..sour = 0
      ..spicy = 0
      ..umami = 0
      ..numbing = 0
      ..oily = 0;

  @BuiltValueSerializer(custom: true)
  static Serializer<FlavorProfile> get serializer => _$FlavorProfileSerializer();
}

class _$FlavorProfileSerializer implements PrimitiveSerializer<FlavorProfile> {
  @override
  final Iterable<Type> types = const [FlavorProfile, _$FlavorProfile];

  @override
  final String wireName = r'FlavorProfile';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FlavorProfile object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.salty != null) {
      yield r'salty';
      yield serializers.serialize(
        object.salty,
        specifiedType: const FullType(int),
      );
    }
    if (object.sweet != null) {
      yield r'sweet';
      yield serializers.serialize(
        object.sweet,
        specifiedType: const FullType(int),
      );
    }
    if (object.sour != null) {
      yield r'sour';
      yield serializers.serialize(
        object.sour,
        specifiedType: const FullType(int),
      );
    }
    if (object.spicy != null) {
      yield r'spicy';
      yield serializers.serialize(
        object.spicy,
        specifiedType: const FullType(int),
      );
    }
    if (object.umami != null) {
      yield r'umami';
      yield serializers.serialize(
        object.umami,
        specifiedType: const FullType(int),
      );
    }
    if (object.numbing != null) {
      yield r'numbing';
      yield serializers.serialize(
        object.numbing,
        specifiedType: const FullType(int),
      );
    }
    if (object.oily != null) {
      yield r'oily';
      yield serializers.serialize(
        object.oily,
        specifiedType: const FullType(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    FlavorProfile object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FlavorProfileBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'salty':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.salty = valueDes;
          break;
        case r'sweet':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.sweet = valueDes;
          break;
        case r'sour':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.sour = valueDes;
          break;
        case r'spicy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.spicy = valueDes;
          break;
        case r'umami':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.umami = valueDes;
          break;
        case r'numbing':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.numbing = valueDes;
          break;
        case r'oily':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.oily = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FlavorProfile deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FlavorProfileBuilder();
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

