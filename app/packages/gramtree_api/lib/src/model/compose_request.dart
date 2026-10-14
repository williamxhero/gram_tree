//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'compose_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComposeRequest {
  /// Returns a new [ComposeRequest] instance.
  ComposeRequest({
    this.detailOverride,

    required this.pageType,

    required this.protocolVersion,

    this.recipeId,

    this.screenWidth = 400,

    this.supportedComponents,

    this.versionId,
  });

  @JsonKey(name: r'detail_override', required: false, includeIfNull: false)
  final ComposeRequestDetailOverrideEnum? detailOverride;

  /// 要哪个页面类型的组合，例如 today
  @JsonKey(name: r'page_type', required: true, includeIfNull: false)
  final String pageType;

  /// App 自己实现的协议版本，例如 1.0
  @JsonKey(name: r'protocol_version', required: true, includeIfNull: false)
  final String protocolVersion;

  @JsonKey(name: r'recipe_id', required: false, includeIfNull: false)
  final String? recipeId;

  /// 逻辑像素视口宽度
  // minimum: 1
  // maximum: 16384
  @JsonKey(
    defaultValue: 400,
    name: r'screen_width',
    required: false,
    includeIfNull: false,
  )
  final int? screenWidth;

  /// App 已登记、认识的组件类型清单；服务端只会下发这里面的类型
  @JsonKey(name: r'supported_components', required: false, includeIfNull: false)
  final List<String>? supportedComponents;

  @JsonKey(name: r'version_id', required: false, includeIfNull: false)
  final String? versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComposeRequest &&
          other.detailOverride == detailOverride &&
          other.pageType == pageType &&
          other.protocolVersion == protocolVersion &&
          other.recipeId == recipeId &&
          other.screenWidth == screenWidth &&
          other.supportedComponents == supportedComponents &&
          other.versionId == versionId;

  @override
  int get hashCode =>
      (detailOverride == null ? 0 : detailOverride.hashCode) +
      pageType.hashCode +
      protocolVersion.hashCode +
      (recipeId == null ? 0 : recipeId.hashCode) +
      screenWidth.hashCode +
      supportedComponents.hashCode +
      (versionId == null ? 0 : versionId.hashCode);

  factory ComposeRequest.fromJson(Map<String, dynamic> json) =>
      _$ComposeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ComposeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ComposeRequestDetailOverrideEnum {
  @JsonValue(r'auto')
  auto(r'auto'),
  @JsonValue(r'brief')
  brief(r'brief'),
  @JsonValue(r'detailed')
  detailed(r'detailed');

  const ComposeRequestDetailOverrideEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
