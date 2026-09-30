//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cache_info.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CacheInfo {
  /// Returns a new [CacheInfo] instance.
  CacheInfo({this.dependsOn, required this.ttlS});

  /// 依赖的内容版本
  @JsonKey(name: r'depends_on', required: false, includeIfNull: false)
  final Map<String, String>? dependsOn;

  /// 缓存有效期（秒）
  // minimum: 0
  @JsonKey(name: r'ttl_s', required: true, includeIfNull: false)
  final int ttlS;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheInfo && other.dependsOn == dependsOn && other.ttlS == ttlS;

  @override
  int get hashCode => dependsOn.hashCode + ttlS.hashCode;

  factory CacheInfo.fromJson(Map<String, dynamic> json) =>
      _$CacheInfoFromJson(json);

  Map<String, dynamic> toJson() => _$CacheInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
