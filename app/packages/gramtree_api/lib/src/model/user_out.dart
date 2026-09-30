//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'user_out.g.dart';

/// UserOut
///
/// Properties:
/// * [id] 
/// * [nickname] 
/// * [timezone] 
/// * [status] 
/// * [phone] 
/// * [realNameStatus] - 预留：发布内容实名状态（SPEC-011）
/// * [createdAt] 
@BuiltValue()
abstract class UserOut implements Built<UserOut, UserOutBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'nickname')
  String get nickname;

  @BuiltValueField(wireName: r'timezone')
  String get timezone;

  @BuiltValueField(wireName: r'status')
  UserOutStatusEnum get status;
  // enum statusEnum {  active,  deleting,  deleted,  };

  @BuiltValueField(wireName: r'phone')
  String? get phone;

  /// 预留：发布内容实名状态（SPEC-011）
  @BuiltValueField(wireName: r'real_name_status')
  UserOutRealNameStatusEnum get realNameStatus;
  // enum realNameStatusEnum {  none,  pending,  verified,  };

  @BuiltValueField(wireName: r'created_at')
  String get createdAt;

  UserOut._();

  factory UserOut([void updates(UserOutBuilder b)]) = _$UserOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UserOutBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UserOut> get serializer => _$UserOutSerializer();
}

class _$UserOutSerializer implements PrimitiveSerializer<UserOut> {
  @override
  final Iterable<Type> types = const [UserOut, _$UserOut];

  @override
  final String wireName = r'UserOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UserOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'nickname';
    yield serializers.serialize(
      object.nickname,
      specifiedType: const FullType(String),
    );
    yield r'timezone';
    yield serializers.serialize(
      object.timezone,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(UserOutStatusEnum),
    );
    yield r'phone';
    yield object.phone == null ? null : serializers.serialize(
      object.phone,
      specifiedType: const FullType.nullable(String),
    );
    yield r'real_name_status';
    yield serializers.serialize(
      object.realNameStatus,
      specifiedType: const FullType(UserOutRealNameStatusEnum),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UserOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UserOutBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'nickname':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nickname = valueDes;
          break;
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.timezone = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UserOutStatusEnum),
          ) as UserOutStatusEnum;
          result.status = valueDes;
          break;
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.phone = valueDes;
          break;
        case r'real_name_status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UserOutRealNameStatusEnum),
          ) as UserOutRealNameStatusEnum;
          result.realNameStatus = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UserOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UserOutBuilder();
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

class UserOutStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'active')
  static const UserOutStatusEnum active = _$userOutStatusEnum_active;
  @BuiltValueEnumConst(wireName: r'deleting')
  static const UserOutStatusEnum deleting = _$userOutStatusEnum_deleting;
  @BuiltValueEnumConst(wireName: r'deleted')
  static const UserOutStatusEnum deleted = _$userOutStatusEnum_deleted;

  static Serializer<UserOutStatusEnum> get serializer => _$userOutStatusEnumSerializer;

  const UserOutStatusEnum._(String name): super(name);

  static BuiltSet<UserOutStatusEnum> get values => _$userOutStatusEnumValues;
  static UserOutStatusEnum valueOf(String name) => _$userOutStatusEnumValueOf(name);
}

class UserOutRealNameStatusEnum extends EnumClass {

  /// 预留：发布内容实名状态（SPEC-011）
  @BuiltValueEnumConst(wireName: r'none')
  static const UserOutRealNameStatusEnum none = _$userOutRealNameStatusEnum_none;
  /// 预留：发布内容实名状态（SPEC-011）
  @BuiltValueEnumConst(wireName: r'pending')
  static const UserOutRealNameStatusEnum pending = _$userOutRealNameStatusEnum_pending;
  /// 预留：发布内容实名状态（SPEC-011）
  @BuiltValueEnumConst(wireName: r'verified')
  static const UserOutRealNameStatusEnum verified = _$userOutRealNameStatusEnum_verified;

  static Serializer<UserOutRealNameStatusEnum> get serializer => _$userOutRealNameStatusEnumSerializer;

  const UserOutRealNameStatusEnum._(String name): super(name);

  static BuiltSet<UserOutRealNameStatusEnum> get values => _$userOutRealNameStatusEnumValues;
  static UserOutRealNameStatusEnum valueOf(String name) => _$userOutRealNameStatusEnumValueOf(name);
}

