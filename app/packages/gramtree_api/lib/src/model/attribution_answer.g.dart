// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attribution_answer.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttributionAnswerCWProxy {
  AttributionAnswer answer(AttributionAnswerAnswerEnum answer);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttributionAnswer(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttributionAnswer(...).copyWith(id: 12, name: "My name")
  /// ````
  AttributionAnswer call({AttributionAnswerAnswerEnum answer});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAttributionAnswer.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAttributionAnswer.copyWith.fieldName(...)`
class _$AttributionAnswerCWProxyImpl implements _$AttributionAnswerCWProxy {
  const _$AttributionAnswerCWProxyImpl(this._value);

  final AttributionAnswer _value;

  @override
  AttributionAnswer answer(AttributionAnswerAnswerEnum answer) =>
      this(answer: answer);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AttributionAnswer(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AttributionAnswer(...).copyWith(id: 12, name: "My name")
  /// ````
  AttributionAnswer call({Object? answer = const $CopyWithPlaceholder()}) {
    return AttributionAnswer(
      answer: answer == const $CopyWithPlaceholder()
          ? _value.answer
          // ignore: cast_nullable_to_non_nullable
          : answer as AttributionAnswerAnswerEnum,
    );
  }
}

extension $AttributionAnswerCopyWith on AttributionAnswer {
  /// Returns a callable class that can be used as follows: `instanceOfAttributionAnswer.copyWith(...)` or like so:`instanceOfAttributionAnswer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttributionAnswerCWProxy get copyWith =>
      _$AttributionAnswerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttributionAnswer _$AttributionAnswerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AttributionAnswer', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['answer']);
      final val = AttributionAnswer(
        answer: $checkedConvert(
          'answer',
          (v) => $enumDecode(_$AttributionAnswerAnswerEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AttributionAnswerToJson(AttributionAnswer instance) =>
    <String, dynamic>{
      'answer': _$AttributionAnswerAnswerEnumEnumMap[instance.answer]!,
    };

const _$AttributionAnswerAnswerEnumEnumMap = {
  AttributionAnswerAnswerEnum.personal: 'personal',
  AttributionAnswerAnswerEnum.recipe: 'recipe',
  AttributionAnswerAnswerEnum.unanswered: 'unanswered',
};
