// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$QuestionCWProxy {
  Question default_(String default_);

  Question key(QuestionKeyEnum key);

  Question text(String text);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Question(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Question(...).copyWith(id: 12, name: "My name")
  /// ````
  Question call({String default_, QuestionKeyEnum key, String text});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfQuestion.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfQuestion.copyWith.fieldName(...)`
class _$QuestionCWProxyImpl implements _$QuestionCWProxy {
  const _$QuestionCWProxyImpl(this._value);

  final Question _value;

  @override
  Question default_(String default_) => this(default_: default_);

  @override
  Question key(QuestionKeyEnum key) => this(key: key);

  @override
  Question text(String text) => this(text: text);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Question(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Question(...).copyWith(id: 12, name: "My name")
  /// ````
  Question call({
    Object? default_ = const $CopyWithPlaceholder(),
    Object? key = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return Question(
      default_: default_ == const $CopyWithPlaceholder()
          ? _value.default_
          // ignore: cast_nullable_to_non_nullable
          : default_ as String,
      key: key == const $CopyWithPlaceholder()
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as QuestionKeyEnum,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $QuestionCopyWith on Question {
  /// Returns a callable class that can be used as follows: `instanceOfQuestion.copyWith(...)` or like so:`instanceOfQuestion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$QuestionCWProxy get copyWith => _$QuestionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Question _$QuestionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Question', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['default', 'key', 'text']);
      final val = Question(
        default_: $checkedConvert('default', (v) => v as String),
        key: $checkedConvert(
          'key',
          (v) => $enumDecode(_$QuestionKeyEnumEnumMap, v),
        ),
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'default_': 'default'});

Map<String, dynamic> _$QuestionToJson(Question instance) => <String, dynamic>{
  'default': instance.default_,
  'key': _$QuestionKeyEnumEnumMap[instance.key]!,
  'text': instance.text,
};

const _$QuestionKeyEnumEnumMap = {
  QuestionKeyEnum.servings: 'servings',
  QuestionKeyEnum.cookware: 'cookware',
};
