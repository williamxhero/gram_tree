//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:gramtree_api/src/model/personalization_request.dart';
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
    this.beforeChangeId,

    this.detailOverride,

    required this.pageType,

    this.personalization,

    required this.personalizationView,

    required this.protocolVersion,

    this.recipeId,

    this.screenWidth = 400,

    this.skippedComponents,

    this.supportedComponents,

    this.versionId,
  });

  @JsonKey(name: r'before_change_id', required: false, includeIfNull: false)
  final String? beforeChangeId;

  /// 仅当前页面的详略切换；auto 恢复用户默认或自动决定
  @JsonKey(name: r'detail_override', required: false, includeIfNull: false)
  final ComposeRequestDetailOverrideEnum? detailOverride;

  /// 要哪个页面类型的组合，例如 today
  @JsonKey(name: r'page_type', required: true, includeIfNull: false)
  final String pageType;

  @JsonKey(name: r'personalization', required: false, includeIfNull: false)
  final PersonalizationRequest? personalization;

  @JsonKey(name: r'personalization_view', required: true, includeIfNull: false)
  final ComposeRequestPersonalizationViewEnum personalizationView;

  /// App 自己实现的协议版本，例如 1.0
  @JsonKey(name: r'protocol_version', required: true, includeIfNull: false)
  final String protocolVersion;

  /// 菜谱详情/工作台要展示的私有菜谱；不填表示尚未保存的编辑草稿
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

  @JsonKey(name: r'skipped_components', required: false, includeIfNull: false)
  final List<String>? skippedComponents;

  /// App 已登记、认识的组件类型清单；服务端只会下发这里面的类型
  @JsonKey(name: r'supported_components', required: false, includeIfNull: false)
  final List<String>? supportedComponents;

  /// 可选的不可变菜谱版本；不填使用当前版本
  @JsonKey(name: r'version_id', required: false, includeIfNull: false)
  final String? versionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComposeRequest &&
          other.beforeChangeId == beforeChangeId &&
          other.detailOverride == detailOverride &&
          other.pageType == pageType &&
          other.personalization == personalization &&
          other.personalizationView == personalizationView &&
          other.protocolVersion == protocolVersion &&
          other.recipeId == recipeId &&
          other.screenWidth == screenWidth &&
          other.skippedComponents == skippedComponents &&
          other.supportedComponents == supportedComponents &&
          other.versionId == versionId;

  @override
  int get hashCode =>
      (beforeChangeId == null ? 0 : beforeChangeId.hashCode) +
      (detailOverride == null ? 0 : detailOverride.hashCode) +
      pageType.hashCode +
      personalization.hashCode +
      personalizationView.hashCode +
      protocolVersion.hashCode +
      (recipeId == null ? 0 : recipeId.hashCode) +
      screenWidth.hashCode +
      skippedComponents.hashCode +
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

/// 仅当前页面的详略切换；auto 恢复用户默认或自动决定
enum ComposeRequestDetailOverrideEnum {
  /// 仅当前页面的详略切换；auto 恢复用户默认或自动决定
  @JsonValue(r'auto')
  auto(r'auto'),

  /// 仅当前页面的详略切换；auto 恢复用户默认或自动决定
  @JsonValue(r'brief')
  brief(r'brief'),

  /// 仅当前页面的详略切换；auto 恢复用户默认或自动决定
  @JsonValue(r'detailed')
  detailed(r'detailed');

  const ComposeRequestDetailOverrideEnum(this.value);

  final String value;

  @override
  String toString() => value;
}

enum ComposeRequestPersonalizationViewEnum {
  @JsonValue(r'personalized')
  personalized(r'personalized'),
  @JsonValue(r'original')
  original(r'original');

  const ComposeRequestPersonalizationViewEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
