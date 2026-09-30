//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:gramtree_api/src/model/normalize_candidate.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'normalize_result_item.g.dart';

/// NormalizeResultItem
///
/// Properties:
/// * [name] - 原样返回输入的名称
/// * [confidence] - exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
/// * [ingredientId] 
/// * [standardName] 
/// * [candidates] - 只有 ambiguous 时非空
@BuiltValue()
abstract class NormalizeResultItem implements Built<NormalizeResultItem, NormalizeResultItemBuilder> {
  /// 原样返回输入的名称
  @BuiltValueField(wireName: r'name')
  String get name;

  /// exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
  @BuiltValueField(wireName: r'confidence')
  NormalizeResultItemConfidenceEnum get confidence;
  // enum confidenceEnum {  exact,  alias,  fuzzy,  ambiguous,  unrecorded,  };

  @BuiltValueField(wireName: r'ingredient_id')
  String? get ingredientId;

  @BuiltValueField(wireName: r'standard_name')
  String? get standardName;

  /// 只有 ambiguous 时非空
  @BuiltValueField(wireName: r'candidates')
  BuiltList<NormalizeCandidate> get candidates;

  NormalizeResultItem._();

  factory NormalizeResultItem([void updates(NormalizeResultItemBuilder b)]) = _$NormalizeResultItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NormalizeResultItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NormalizeResultItem> get serializer => _$NormalizeResultItemSerializer();
}

class _$NormalizeResultItemSerializer implements PrimitiveSerializer<NormalizeResultItem> {
  @override
  final Iterable<Type> types = const [NormalizeResultItem, _$NormalizeResultItem];

  @override
  final String wireName = r'NormalizeResultItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NormalizeResultItem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'confidence';
    yield serializers.serialize(
      object.confidence,
      specifiedType: const FullType(NormalizeResultItemConfidenceEnum),
    );
    yield r'ingredient_id';
    yield object.ingredientId == null ? null : serializers.serialize(
      object.ingredientId,
      specifiedType: const FullType.nullable(String),
    );
    yield r'standard_name';
    yield object.standardName == null ? null : serializers.serialize(
      object.standardName,
      specifiedType: const FullType.nullable(String),
    );
    yield r'candidates';
    yield serializers.serialize(
      object.candidates,
      specifiedType: const FullType(BuiltList, [FullType(NormalizeCandidate)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NormalizeResultItem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NormalizeResultItemBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'confidence':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(NormalizeResultItemConfidenceEnum),
          ) as NormalizeResultItemConfidenceEnum;
          result.confidence = valueDes;
          break;
        case r'ingredient_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.ingredientId = valueDes;
          break;
        case r'standard_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.standardName = valueDes;
          break;
        case r'candidates':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(NormalizeCandidate)]),
          ) as BuiltList<NormalizeCandidate>;
          result.candidates.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NormalizeResultItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NormalizeResultItemBuilder();
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

class NormalizeResultItemConfidenceEnum extends EnumClass {

  /// exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
  @BuiltValueEnumConst(wireName: r'exact')
  static const NormalizeResultItemConfidenceEnum exact = _$normalizeResultItemConfidenceEnum_exact;
  /// exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
  @BuiltValueEnumConst(wireName: r'alias')
  static const NormalizeResultItemConfidenceEnum alias = _$normalizeResultItemConfidenceEnum_alias;
  /// exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
  @BuiltValueEnumConst(wireName: r'fuzzy')
  static const NormalizeResultItemConfidenceEnum fuzzy = _$normalizeResultItemConfidenceEnum_fuzzy;
  /// exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
  @BuiltValueEnumConst(wireName: r'ambiguous')
  static const NormalizeResultItemConfidenceEnum ambiguous = _$normalizeResultItemConfidenceEnum_ambiguous;
  /// exact 标准名精确匹配；alias 别名匹配（含已合并食材的旧名）；fuzzy 去掉修饰词或按拼音后唯一命中；ambiguous 歧义名，见 candidates；unrecorded 未收录
  @BuiltValueEnumConst(wireName: r'unrecorded')
  static const NormalizeResultItemConfidenceEnum unrecorded = _$normalizeResultItemConfidenceEnum_unrecorded;

  static Serializer<NormalizeResultItemConfidenceEnum> get serializer => _$normalizeResultItemConfidenceEnumSerializer;

  const NormalizeResultItemConfidenceEnum._(String name): super(name);

  static BuiltSet<NormalizeResultItemConfidenceEnum> get values => _$normalizeResultItemConfidenceEnumValues;
  static NormalizeResultItemConfidenceEnum valueOf(String name) => _$normalizeResultItemConfidenceEnumValueOf(name);
}

