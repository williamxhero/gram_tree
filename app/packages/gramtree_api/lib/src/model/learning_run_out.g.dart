// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_run_out.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LearningRunOutCWProxy {
  LearningRunOut appliedChanges(List<TasteProfileChangeOut> appliedChanges);

  LearningRunOut pendingSuggestions(
    List<TasteProfileChangeOut> pendingSuggestions,
  );

  LearningRunOut signalsConsidered(int signalsConsidered);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LearningRunOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LearningRunOut(...).copyWith(id: 12, name: "My name")
  /// ````
  LearningRunOut call({
    List<TasteProfileChangeOut> appliedChanges,
    List<TasteProfileChangeOut> pendingSuggestions,
    int signalsConsidered,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLearningRunOut.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLearningRunOut.copyWith.fieldName(...)`
class _$LearningRunOutCWProxyImpl implements _$LearningRunOutCWProxy {
  const _$LearningRunOutCWProxyImpl(this._value);

  final LearningRunOut _value;

  @override
  LearningRunOut appliedChanges(List<TasteProfileChangeOut> appliedChanges) =>
      this(appliedChanges: appliedChanges);

  @override
  LearningRunOut pendingSuggestions(
    List<TasteProfileChangeOut> pendingSuggestions,
  ) => this(pendingSuggestions: pendingSuggestions);

  @override
  LearningRunOut signalsConsidered(int signalsConsidered) =>
      this(signalsConsidered: signalsConsidered);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LearningRunOut(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LearningRunOut(...).copyWith(id: 12, name: "My name")
  /// ````
  LearningRunOut call({
    Object? appliedChanges = const $CopyWithPlaceholder(),
    Object? pendingSuggestions = const $CopyWithPlaceholder(),
    Object? signalsConsidered = const $CopyWithPlaceholder(),
  }) {
    return LearningRunOut(
      appliedChanges: appliedChanges == const $CopyWithPlaceholder()
          ? _value.appliedChanges
          // ignore: cast_nullable_to_non_nullable
          : appliedChanges as List<TasteProfileChangeOut>,
      pendingSuggestions: pendingSuggestions == const $CopyWithPlaceholder()
          ? _value.pendingSuggestions
          // ignore: cast_nullable_to_non_nullable
          : pendingSuggestions as List<TasteProfileChangeOut>,
      signalsConsidered: signalsConsidered == const $CopyWithPlaceholder()
          ? _value.signalsConsidered
          // ignore: cast_nullable_to_non_nullable
          : signalsConsidered as int,
    );
  }
}

extension $LearningRunOutCopyWith on LearningRunOut {
  /// Returns a callable class that can be used as follows: `instanceOfLearningRunOut.copyWith(...)` or like so:`instanceOfLearningRunOut.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LearningRunOutCWProxy get copyWith => _$LearningRunOutCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LearningRunOut _$LearningRunOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LearningRunOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'applied_changes',
            'pending_suggestions',
            'signals_considered',
          ],
        );
        final val = LearningRunOut(
          appliedChanges: $checkedConvert(
            'applied_changes',
            (v) => (v as List<dynamic>)
                .map(
                  (e) =>
                      TasteProfileChangeOut.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          ),
          pendingSuggestions: $checkedConvert(
            'pending_suggestions',
            (v) => (v as List<dynamic>)
                .map(
                  (e) =>
                      TasteProfileChangeOut.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          ),
          signalsConsidered: $checkedConvert(
            'signals_considered',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'appliedChanges': 'applied_changes',
        'pendingSuggestions': 'pending_suggestions',
        'signalsConsidered': 'signals_considered',
      },
    );

Map<String, dynamic> _$LearningRunOutToJson(
  LearningRunOut instance,
) => <String, dynamic>{
  'applied_changes': instance.appliedChanges.map((e) => e.toJson()).toList(),
  'pending_suggestions': instance.pendingSuggestions
      .map((e) => e.toJson())
      .toList(),
  'signals_considered': instance.signalsConsidered,
};
