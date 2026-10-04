import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../component_registry.dart';
import '../../l10n/app_localizations.dart';
import '../source_mark.dart';
import '../source_overrides.dart';
import '../source_types.dart';
import 'component_scaffold.dart';

/// 仅测试用的示例组件（SPEC-009.1 #82）：验证"来源标记 -> 为什么面板 -> 反馈"这条
/// 链路，不是真实业务组件——本子 SPEC 还没有真实的换算内容（真实换算是
/// SPEC-005.3 的事），`data.source` 的形状见
/// `contracts/ui_protocol/schema/1.0/components/source_demo.schema.json`。
///
/// 来源标记（[SourceMark]）画在结论行右侧，任何详略档都显示（"让用户一眼分清"不该
/// 只在展开后才看得到）；标准/详细档另外把依据摊开显示，和其它通用组件的"三层"
/// 规则（`component_scaffold.dart` 的 [ComponentCard]）保持一致。
///
/// "这次不用"（[SourceOverrides]）：点了之后服务端退回的值只在本机内存里存一份
/// 覆盖，这里渲染时按组件实例 ID 查一下有没有覆盖值，有就显示覆盖后的（用
/// `Consumer` 包一层来 watch 这个 provider，不改 `ComponentBuilder` 的签名）。
Widget buildSourceDemoComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = component.data as Map<String, dynamic>;
  final conclusion = data['conclusion'] as String?;
  final source = data['source'] as Map<String, dynamic>?;
  if (conclusion == null || conclusion.isEmpty || source == null) {
    return ComponentEmptyCard(emptyState: emptyState);
  }

  final protocolSourceType =
      source['source_type'] as String? ?? sourceTypeAuthorFilled;
  final protocolValue = source['value'] as String? ?? '';
  final protocolOriginalValue = source['original_value'] as String?;
  final basis = source['basis'] as Map<String, dynamic>? ?? const {};
  final protocolBasisText = basis['text'] as String? ?? '';
  final protocolCitation = basis['citation'] as String?;
  final isRequired = component.required_ ?? false;

  return Consumer(
    builder: (context, ref, _) {
      final theme = Theme.of(context);
      final l10n = AppLocalizations.of(context);
      final override = ref.watch(sourceOverridesProvider)[component.id];
      // 有覆盖值时整组字段都从覆盖值来（哪怕 originalValue/citation 是 null，也是
      // "退回原值后就没有原值/引用了"这个合法状态，不该退回协议原始数据里的旧值）；
      // 没有覆盖值时才用协议原始数据。
      final sourceType = override?.sourceType ?? protocolSourceType;
      final value = override?.value ?? protocolValue;
      final basisText = override?.basisText ?? protocolBasisText;
      final originalValue = override != null
          ? override.originalValue
          : protocolOriginalValue;
      final citation = override != null ? override.citation : protocolCitation;
      final showMark = sourceType != sourceTypeAuthorFilled;

      final conclusionRow = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(conclusion, style: theme.textTheme.bodyMedium)),
          if (showMark)
            SourceMark(
              sourceType: sourceType,
              componentId: component.id,
              value: value,
              originalValue: originalValue,
              basisText: basisText,
              citation: citation,
              required: isRequired,
              onAction: onAction,
            ),
        ],
      );

      // 依据/原值/来源引用的完整说明只在点开来源标记后的"为什么"面板里显示（见
      // `source_mark.dart` 的 `WhyPanel`），卡片本身不重复显示一遍基础文字——避免
      // 同一句依据在卡片和面板里同时出现两份。
      return ComponentCard(
        detail: component.detail,
        conclusion: conclusionRow,
        conclusionSemanticsText: showMark
            ? '$conclusion，来源：${sourceTypeLabel(sourceType, l10n)}'
            : conclusion,
        showPrimaryButton: false,
      );
    },
  );
}
