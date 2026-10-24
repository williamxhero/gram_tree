// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletionRequestCWProxy {
  DeletionRequest publicRecipeAction(
    DeletionRequestPublicRecipeActionEnum? publicRecipeAction,
  );

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeletionRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeletionRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  DeletionRequest call({
    DeletionRequestPublicRecipeActionEnum? publicRecipeAction,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDeletionRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDeletionRequest.copyWith.fieldName(...)`
class _$DeletionRequestCWProxyImpl implements _$DeletionRequestCWProxy {
  const _$DeletionRequestCWProxyImpl(this._value);

  final DeletionRequest _value;

  @override
  DeletionRequest publicRecipeAction(
    DeletionRequestPublicRecipeActionEnum? publicRecipeAction,
  ) => this(publicRecipeAction: publicRecipeAction);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `DeletionRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// DeletionRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  DeletionRequest call({
    Object? publicRecipeAction = const $CopyWithPlaceholder(),
  }) {
    return DeletionRequest(
      publicRecipeAction: publicRecipeAction == const $CopyWithPlaceholder()
          ? _value.publicRecipeAction
          // ignore: cast_nullable_to_non_nullable
          : publicRecipeAction as DeletionRequestPublicRecipeActionEnum?,
    );
  }
}

extension $DeletionRequestCopyWith on DeletionRequest {
  /// Returns a callable class that can be used as follows: `instanceOfDeletionRequest.copyWith(...)` or like so:`instanceOfDeletionRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletionRequestCWProxy get copyWith => _$DeletionRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletionRequest _$DeletionRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletionRequest', json, ($checkedConvert) {
      final val = DeletionRequest(
        publicRecipeAction: $checkedConvert(
          'public_recipe_action',
          (v) => $enumDecodeNullable(
            _$DeletionRequestPublicRecipeActionEnumEnumMap,
            v,
          ),
        ),
      );
      return val;
    }, fieldKeyMap: const {'publicRecipeAction': 'public_recipe_action'});

Map<String, dynamic> _$DeletionRequestToJson(DeletionRequest instance) =>
    <String, dynamic>{
      'public_recipe_action':
          ?_$DeletionRequestPublicRecipeActionEnumEnumMap[instance
              .publicRecipeAction],
    };

const _$DeletionRequestPublicRecipeActionEnumEnumMap = {
  DeletionRequestPublicRecipeActionEnum.keepAnonymous: 'keep_anonymous',
  DeletionRequestPublicRecipeActionEnum.withdraw: 'withdraw',
};
