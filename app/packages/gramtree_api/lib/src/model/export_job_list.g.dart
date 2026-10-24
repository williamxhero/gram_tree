// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_job_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExportJobListCWProxy {
  ExportJobList items(List<ExportJobView> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExportJobList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExportJobList(...).copyWith(id: 12, name: "My name")
  /// ````
  ExportJobList call({List<ExportJobView> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfExportJobList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfExportJobList.copyWith.fieldName(...)`
class _$ExportJobListCWProxyImpl implements _$ExportJobListCWProxy {
  const _$ExportJobListCWProxyImpl(this._value);

  final ExportJobList _value;

  @override
  ExportJobList items(List<ExportJobView> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExportJobList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExportJobList(...).copyWith(id: 12, name: "My name")
  /// ````
  ExportJobList call({Object? items = const $CopyWithPlaceholder()}) {
    return ExportJobList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ExportJobView>,
    );
  }
}

extension $ExportJobListCopyWith on ExportJobList {
  /// Returns a callable class that can be used as follows: `instanceOfExportJobList.copyWith(...)` or like so:`instanceOfExportJobList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExportJobListCWProxy get copyWith => _$ExportJobListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExportJobList _$ExportJobListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ExportJobList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ExportJobList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ExportJobView.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ExportJobListToJson(ExportJobList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
