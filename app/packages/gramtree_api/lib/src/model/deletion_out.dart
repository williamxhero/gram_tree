//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'deletion_out.g.dart';

/// DeletionOut
///
/// Properties:
/// * [status] 
/// * [deletionDueAt] 
@BuiltValue()
abstract class DeletionOut implements Built<DeletionOut, DeletionOutBuilder> {
  @BuiltValueField(wireName: r'status')
  DeletionOutStatusEnum get status;
  // enum statusEnum {  active,  deleting,  deleted,  };

  @BuiltValueField(wireName: r'deletion_due_at')
  String? get deletionDueAt;

  DeletionOut._();

  factory DeletionOut([void updates(DeletionOutBuilder b)]) = _$DeletionOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeletionOutBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeletionOut> get serializer => _$DeletionOutSerializer();
}

class _$DeletionOutSerializer implements PrimitiveSerializer<DeletionOut> {
  @override
  final Iterable<Type> types = const [DeletionOut, _$DeletionOut];

  @override
  final String wireName = r'DeletionOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeletionOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(DeletionOutStatusEnum),
    );
    yield r'deletion_due_at';
    yield object.deletionDueAt == null ? null : serializers.serialize(
      object.deletionDueAt,
      specifiedType: const FullType.nullable(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DeletionOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DeletionOutBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DeletionOutStatusEnum),
          ) as DeletionOutStatusEnum;
          result.status = valueDes;
          break;
        case r'deletion_due_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.deletionDueAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeletionOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeletionOutBuilder();
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

class DeletionOutStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'active')
  static const DeletionOutStatusEnum active = _$deletionOutStatusEnum_active;
  @BuiltValueEnumConst(wireName: r'deleting')
  static const DeletionOutStatusEnum deleting = _$deletionOutStatusEnum_deleting;
  @BuiltValueEnumConst(wireName: r'deleted')
  static const DeletionOutStatusEnum deleted = _$deletionOutStatusEnum_deleted;

  static Serializer<DeletionOutStatusEnum> get serializer => _$deletionOutStatusEnumSerializer;

  const DeletionOutStatusEnum._(String name): super(name);

  static BuiltSet<DeletionOutStatusEnum> get values => _$deletionOutStatusEnumValues;
  static DeletionOutStatusEnum valueOf(String name) => _$deletionOutStatusEnumValueOf(name);
}

