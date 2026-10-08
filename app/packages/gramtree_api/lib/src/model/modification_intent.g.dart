// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modification_intent.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModificationIntentCWProxy {
  ModificationIntent category(ModificationIntentCategoryEnum category);

  ModificationIntent confidence(num confidence);

  ModificationIntent parameters(Object? parameters);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationIntent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationIntent(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationIntent call({
    ModificationIntentCategoryEnum category,
    num confidence,
    Object? parameters,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfModificationIntent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfModificationIntent.copyWith.fieldName(...)`
class _$ModificationIntentCWProxyImpl implements _$ModificationIntentCWProxy {
  const _$ModificationIntentCWProxyImpl(this._value);

  final ModificationIntent _value;

  @override
  ModificationIntent category(ModificationIntentCategoryEnum category) =>
      this(category: category);

  @override
  ModificationIntent confidence(num confidence) => this(confidence: confidence);

  @override
  ModificationIntent parameters(Object? parameters) =>
      this(parameters: parameters);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModificationIntent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModificationIntent(...).copyWith(id: 12, name: "My name")
  /// ````
  ModificationIntent call({
    Object? category = const $CopyWithPlaceholder(),
    Object? confidence = const $CopyWithPlaceholder(),
    Object? parameters = const $CopyWithPlaceholder(),
  }) {
    return ModificationIntent(
      category: category == const $CopyWithPlaceholder()
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as ModificationIntentCategoryEnum,
      confidence: confidence == const $CopyWithPlaceholder()
          ? _value.confidence
          // ignore: cast_nullable_to_non_nullable
          : confidence as num,
      parameters: parameters == const $CopyWithPlaceholder()
          ? _value.parameters
          // ignore: cast_nullable_to_non_nullable
          : parameters as Object?,
    );
  }
}

extension $ModificationIntentCopyWith on ModificationIntent {
  /// Returns a callable class that can be used as follows: `instanceOfModificationIntent.copyWith(...)` or like so:`instanceOfModificationIntent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModificationIntentCWProxy get copyWith =>
      _$ModificationIntentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModificationIntent _$ModificationIntentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ModificationIntent', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['category', 'confidence']);
      final val = ModificationIntent(
        category: $checkedConvert(
          'category',
          (v) => $enumDecode(_$ModificationIntentCategoryEnumEnumMap, v),
        ),
        confidence: $checkedConvert('confidence', (v) => v as num),
        parameters: $checkedConvert('parameters', (v) => v),
      );
      return val;
    });

Map<String, dynamic> _$ModificationIntentToJson(ModificationIntent instance) =>
    <String, dynamic>{
      'category': _$ModificationIntentCategoryEnumEnumMap[instance.category]!,
      'confidence': instance.confidence,
      'parameters': ?instance.parameters,
    };

const _$ModificationIntentCategoryEnumEnumMap = {
  ModificationIntentCategoryEnum.taste: 'taste',
  ModificationIntentCategoryEnum.cookware: 'cookware',
  ModificationIntentCategoryEnum.substitution: 'substitution',
  ModificationIntentCategoryEnum.timeDifficulty: 'time_difficulty',
  ModificationIntentCategoryEnum.method: 'method',
  ModificationIntentCategoryEnum.text: 'text',
  ModificationIntentCategoryEnum.unknown: 'unknown',
};
