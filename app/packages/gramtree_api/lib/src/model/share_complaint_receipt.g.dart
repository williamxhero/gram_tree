// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_complaint_receipt.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ShareComplaintReceiptCWProxy {
  ShareComplaintReceipt accepted(bool? accepted);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ShareComplaintReceipt(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ShareComplaintReceipt(...).copyWith(id: 12, name: "My name")
  /// ````
  ShareComplaintReceipt call({bool? accepted});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfShareComplaintReceipt.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfShareComplaintReceipt.copyWith.fieldName(...)`
class _$ShareComplaintReceiptCWProxyImpl
    implements _$ShareComplaintReceiptCWProxy {
  const _$ShareComplaintReceiptCWProxyImpl(this._value);

  final ShareComplaintReceipt _value;

  @override
  ShareComplaintReceipt accepted(bool? accepted) => this(accepted: accepted);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ShareComplaintReceipt(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ShareComplaintReceipt(...).copyWith(id: 12, name: "My name")
  /// ````
  ShareComplaintReceipt call({
    Object? accepted = const $CopyWithPlaceholder(),
  }) {
    return ShareComplaintReceipt(
      accepted: accepted == const $CopyWithPlaceholder()
          ? _value.accepted
          // ignore: cast_nullable_to_non_nullable
          : accepted as bool?,
    );
  }
}

extension $ShareComplaintReceiptCopyWith on ShareComplaintReceipt {
  /// Returns a callable class that can be used as follows: `instanceOfShareComplaintReceipt.copyWith(...)` or like so:`instanceOfShareComplaintReceipt.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ShareComplaintReceiptCWProxy get copyWith =>
      _$ShareComplaintReceiptCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShareComplaintReceipt _$ShareComplaintReceiptFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ShareComplaintReceipt', json, ($checkedConvert) {
  final val = ShareComplaintReceipt(
    accepted: $checkedConvert('accepted', (v) => v as bool? ?? true),
  );
  return val;
});

Map<String, dynamic> _$ShareComplaintReceiptToJson(
  ShareComplaintReceipt instance,
) => <String, dynamic>{'accepted': ?instance.accepted};
