//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/sample_out.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'page_sample_out.g.dart';

/// PageSampleOut
///
/// Properties:
/// * [items] 
/// * [nextCursor] 
@BuiltValue()
abstract class PageSampleOut implements Built<PageSampleOut, PageSampleOutBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<SampleOut> get items;

  @BuiltValueField(wireName: r'next_cursor')
  String? get nextCursor;

  PageSampleOut._();

  factory PageSampleOut([void updates(PageSampleOutBuilder b)]) = _$PageSampleOut;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PageSampleOutBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PageSampleOut> get serializer => _$PageSampleOutSerializer();
}

class _$PageSampleOutSerializer implements PrimitiveSerializer<PageSampleOut> {
  @override
  final Iterable<Type> types = const [PageSampleOut, _$PageSampleOut];

  @override
  final String wireName = r'PageSampleOut';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PageSampleOut object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(SampleOut)]),
    );
    if (object.nextCursor != null) {
      yield r'next_cursor';
      yield serializers.serialize(
        object.nextCursor,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PageSampleOut object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PageSampleOutBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(SampleOut)]),
          ) as BuiltList<SampleOut>;
          result.items.replace(valueDes);
          break;
        case r'next_cursor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.nextCursor = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PageSampleOut deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PageSampleOutBuilder();
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

