// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_job_view.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExportJobViewCWProxy {
  ExportJobView completedAt(DateTime? completedAt);

  ExportJobView createdAt(DateTime createdAt);

  ExportJobView downloadUrl(String? downloadUrl);

  ExportJobView errorCode(String? errorCode);

  ExportJobView expiresAt(DateTime? expiresAt);

  ExportJobView id(String id);

  ExportJobView status(ExportJobViewStatusEnum status);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExportJobView(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExportJobView(...).copyWith(id: 12, name: "My name")
  /// ````
  ExportJobView call({
    DateTime? completedAt,
    DateTime createdAt,
    String? downloadUrl,
    String? errorCode,
    DateTime? expiresAt,
    String id,
    ExportJobViewStatusEnum status,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfExportJobView.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfExportJobView.copyWith.fieldName(...)`
class _$ExportJobViewCWProxyImpl implements _$ExportJobViewCWProxy {
  const _$ExportJobViewCWProxyImpl(this._value);

  final ExportJobView _value;

  @override
  ExportJobView completedAt(DateTime? completedAt) =>
      this(completedAt: completedAt);

  @override
  ExportJobView createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  ExportJobView downloadUrl(String? downloadUrl) =>
      this(downloadUrl: downloadUrl);

  @override
  ExportJobView errorCode(String? errorCode) => this(errorCode: errorCode);

  @override
  ExportJobView expiresAt(DateTime? expiresAt) => this(expiresAt: expiresAt);

  @override
  ExportJobView id(String id) => this(id: id);

  @override
  ExportJobView status(ExportJobViewStatusEnum status) => this(status: status);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ExportJobView(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ExportJobView(...).copyWith(id: 12, name: "My name")
  /// ````
  ExportJobView call({
    Object? completedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? downloadUrl = const $CopyWithPlaceholder(),
    Object? errorCode = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return ExportJobView(
      completedAt: completedAt == const $CopyWithPlaceholder()
          ? _value.completedAt
          // ignore: cast_nullable_to_non_nullable
          : completedAt as DateTime?,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      downloadUrl: downloadUrl == const $CopyWithPlaceholder()
          ? _value.downloadUrl
          // ignore: cast_nullable_to_non_nullable
          : downloadUrl as String?,
      errorCode: errorCode == const $CopyWithPlaceholder()
          ? _value.errorCode
          // ignore: cast_nullable_to_non_nullable
          : errorCode as String?,
      expiresAt: expiresAt == const $CopyWithPlaceholder()
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime?,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ExportJobViewStatusEnum,
    );
  }
}

extension $ExportJobViewCopyWith on ExportJobView {
  /// Returns a callable class that can be used as follows: `instanceOfExportJobView.copyWith(...)` or like so:`instanceOfExportJobView.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExportJobViewCWProxy get copyWith => _$ExportJobViewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExportJobView _$ExportJobViewFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ExportJobView',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['created_at', 'id', 'status']);
        final val = ExportJobView(
          completedAt: $checkedConvert(
            'completed_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          downloadUrl: $checkedConvert('download_url', (v) => v as String?),
          errorCode: $checkedConvert('error_code', (v) => v as String?),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          id: $checkedConvert('id', (v) => v as String),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$ExportJobViewStatusEnumEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'completedAt': 'completed_at',
        'createdAt': 'created_at',
        'downloadUrl': 'download_url',
        'errorCode': 'error_code',
        'expiresAt': 'expires_at',
      },
    );

Map<String, dynamic> _$ExportJobViewToJson(ExportJobView instance) =>
    <String, dynamic>{
      'completed_at': ?instance.completedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'download_url': ?instance.downloadUrl,
      'error_code': ?instance.errorCode,
      'expires_at': ?instance.expiresAt?.toIso8601String(),
      'id': instance.id,
      'status': _$ExportJobViewStatusEnumEnumMap[instance.status]!,
    };

const _$ExportJobViewStatusEnumEnumMap = {
  ExportJobViewStatusEnum.pending: 'pending',
  ExportJobViewStatusEnum.processing: 'processing',
  ExportJobViewStatusEnum.completed: 'completed',
  ExportJobViewStatusEnum.failed: 'failed',
  ExportJobViewStatusEnum.expired: 'expired',
};
