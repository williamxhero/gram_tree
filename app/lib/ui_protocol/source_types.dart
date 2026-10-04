library;

import '../l10n/app_localizations.dart';

/// 来源标记的五种取值（CLAUDE.md 第 6 节 UI 规范 / SPEC-009.1 #82），和服务端
/// `gramtree.events.registry.SourceType`、生成客户端的 `SourcedValueSourceTypeEnum`
/// 保持一致的取值集合——这里只用普通字符串常量（不是生成的枚举），因为协议里组件
/// `data` 字段的来源类型是先按 Schema 校验成普通字符串，再交给通用组件渲染，不是
/// 每个业务组件都必然反序列化成生成客户端的强类型模型（见 `source_demo_component.dart`
/// 直接读 `component.data` 这个 `Map`，和其它通用组件的写法一致）。

const sourceTypeAuthorFilled = 'author_filled';
const sourceTypeTasteAdjusted = 'taste_adjusted';
const sourceTypeScenarioAdjusted = 'scenario_adjusted';
const sourceTypeAiEstimated = 'ai_estimated';
const sourceTypeVerified = 'verified';

/// 已登记的来源类型集合，`intent_registry.dart` 校验 `skip_this_time`/
/// `dont_do_again` 的 `source_type` 参数时用（和服务端
/// `gramtree.ui_protocol.actions._SOURCE_TYPES` 保持一致）。
const sourceTypes = <String>{
  sourceTypeAuthorFilled,
  sourceTypeTasteAdjusted,
  sourceTypeScenarioAdjusted,
  sourceTypeAiEstimated,
  sourceTypeVerified,
};

/// 来源类型的中文标签，来源标记和"为什么"面板共用。
String sourceTypeLabel(String sourceType, AppLocalizations l10n) =>
    switch (sourceType) {
      sourceTypeAuthorFilled => l10n.sourceAuthorFilled,
      sourceTypeTasteAdjusted => l10n.sourceTasteAdjusted,
      sourceTypeScenarioAdjusted => l10n.sourceScenarioAdjusted,
      sourceTypeAiEstimated => l10n.sourceAiEstimated,
      sourceTypeVerified => l10n.sourceVerified,
      _ => l10n.sourceUnknown,
    };
