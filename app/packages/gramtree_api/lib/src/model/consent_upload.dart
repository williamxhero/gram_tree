//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/consent_record_input.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'consent_upload.g.dart';

/// ConsentUpload
///
/// Properties:
/// * [records] 
@BuiltValue()
abstract class ConsentUpload implements Built<ConsentUpload, ConsentUploadBuilder> {
  @BuiltValueField(wireName: r'records')
  BuiltList<ConsentRecordInput> get records;

  ConsentUpload._();

  factory ConsentUpload([void updates(ConsentUploadBuilder b)]) = _$ConsentUpload;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConsentUploadBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ConsentUpload> get serializer => _$ConsentUploadSerializer();
}

class _$ConsentUploadSerializer implements PrimitiveSerializer<ConsentUpload> {
  @override
  final Iterable<Type> types = const [ConsentUpload, _$ConsentUpload];

  @override
  final String wireName = r'ConsentUpload';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ConsentUpload object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'records';
    yield serializers.serialize(
      object.records,
      specifiedType: const FullType(BuiltList, [FullType(ConsentRecordInput)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ConsentUpload object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ConsentUploadBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'records':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ConsentRecordInput)]),
          ) as BuiltList<ConsentRecordInput>;
          result.records.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ConsentUpload deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConsentUploadBuilder();
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

