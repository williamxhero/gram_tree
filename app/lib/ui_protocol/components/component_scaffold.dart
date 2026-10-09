import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../../network/online_features.dart';
import '../component_registry.dart';
import '../intent_registry.dart';

/// SPEC-009.1 #80：通用组件共用的"结论/依据/明细"三层骨架。业务组件以后按同一份
/// 骨架接数据；来源标记和真正的"为什么"面板在 #82 做——这里的依据在"标准"档只是
/// 一个占位/简单展示（灰底文字加图标），不是可点开的入口。
///
/// 三档详略统一规则：
/// * 简略（brief）：只有结论和一个主要动作（`primaryActionLabel`/`onTapConclusion`）。
/// * 标准（standard）：结论 + `standardExtra`（如果给了）+ 依据占位（如果给了 basisText）。
/// * 详细（detailed）：标准的内容 + `detailedExtra` + 依据摊开成完整文字 + 明细入口
///   （`detailLabel`/`onDetail`，打开一个已登记页面）。
///
/// 无障碍：整张卡片是一个 Semantics 节点，读出结论、（当前档位下显示的）依据、
/// 主要动作文案和明细文案，跟随视觉上实际显示的内容变化，不多读、不少读。
class ComponentCard extends StatelessWidget {
  const ComponentCard({
    super.key,
    required this.detail,
    required this.conclusion,
    required this.conclusionSemanticsText,
    this.standardExtra,
    this.detailedExtra,
    this.basisText,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.showPrimaryButton = true,
    this.onTapConclusion,
    this.detailLabel,
    this.onDetail,
  });

  final ComponentDescriptorDetailEnum detail;

  /// 结论层的视觉内容（可能带图标、可能是标题行），必须始终显示。
  final Widget conclusion;

  /// 结论层的纯文字版本，只用于拼读屏标注。
  final String conclusionSemanticsText;

  /// 标准档和详细档都会显示的额外内容（比如列表容器的行、分区标题的计数）。
  final Widget? standardExtra;

  /// 只在详细档追加显示的内容（比如列表容器每行的附注），排在 [standardExtra] 之后、
  /// 依据之前。
  final Widget? detailedExtra;

  /// 依据层的一句说明；标准档只显示一行占位，详细档摊开显示全文。
  final String? basisText;

  /// 主要动作的文案。为 null 时不显示按钮（比如提示条整条可点，不需要单独按钮）。
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  /// 是否把主要动作画成一个按钮。为 false 时只用于读屏文案，视觉上改用
  /// [onTapConclusion] 让整张卡片可点。
  final bool showPrimaryButton;

  /// 整张卡片的点击动作（提示条这类"点整条"的组件用这个，不单独画按钮）。
  final VoidCallback? onTapConclusion;

  /// 明细层入口文案，只在详细档显示。
  final String? detailLabel;
  final VoidCallback? onDetail;

  bool get _showStandardExtra => detail != ComponentDescriptorDetailEnum.brief;
  bool get _showDetailed => detail == ComponentDescriptorDetailEnum.detailed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = GramTreeColors.of(context);
    final basis = basisText != null && basisText!.isNotEmpty ? basisText : null;

    // 结论、依据是纯文字/图标，没有自己的交互，包一层 ExcludeSemantics，不让它们的
    // 默认读屏文案在语义树里重复出现——它们已经拼进下面卡片自己的 [semanticsLabel]
    // 里了。standardExtra/detailedExtra（比如列表容器的每一行）、明细入口、主按钮
    // 都可能有自己独立的读屏内容（每行读它自己的名称和数值、按钮读它自己的文案），
    // 不放进 ExcludeSemantics，各自留成语义树里单独能查到的节点。
    final children = <Widget>[
      ExcludeSemantics(child: conclusion),
      if (_showStandardExtra && standardExtra != null) ...[
        const SizedBox(height: 8),
        standardExtra!,
      ],
      if (_showDetailed && detailedExtra != null) ...[
        const SizedBox(height: 6),
        detailedExtra!,
      ],
      if (_showStandardExtra && basis != null) ...[
        const SizedBox(height: 8),
        ExcludeSemantics(
          child: _showDetailed
              ? Text(
                  basis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        basis,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
      if (_showDetailed && detailLabel != null) ...[
        const SizedBox(height: 10),
        InkWell(
          onTap: onDetail,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(detailLabel!, style: theme.textTheme.bodyMedium),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
      if (primaryActionLabel != null && showPrimaryButton) ...[
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonal(
            onPressed: onPrimaryAction,
            child: Text(primaryActionLabel!),
          ),
        ),
      ],
    ];

    final showingBasis = _showStandardExtra && basis != null;
    // 主按钮、明细入口在渲染时各自是独立的可点部件，自己的文字就是自己的读屏文案，
    // 不重复拼进卡片这个外层节点；只有"整条可点、没有单独按钮"的情况（hint_bar，
    // `showPrimaryButton == false`）才把主要动作文案带进来，因为那种情况下它没有
    // 别的部件可以承载这段读屏文案。
    final semanticsLabel = [
      conclusionSemanticsText,
      if (showingBasis) basis,
      if (!showPrimaryButton && primaryActionLabel != null) primaryActionLabel,
    ].join('，');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        // container: true，这个节点自己的读屏文案（[semanticsLabel]）单独成一个
        // 语义节点，不会被子级节点的默认文案覆盖或合并掉。
        container: true,
        label: semanticsLabel,
        button: onTapConclusion != null,
        onTap: onTapConclusion,
        child: InkWell(
          onTap: onTapConclusion,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// 登记过的标准空态，用在结论层拿不到内容的时候（比如列表容器一项都没有，
/// 或者——只在测试直接构造组件描述、绕开协议 Schema 校验时才会出现的——结论
/// 缺失）。和 [ComponentCard] 同一种卡片外观，但没有交互，只显示标题和可选说明。
class ComponentEmptyCard extends StatelessWidget {
  const ComponentEmptyCard({super.key, required this.emptyState});

  final ComponentEmptyState emptyState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = GramTreeColors.of(context);
    final message = emptyState.message;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Semantics(
        container: true,
        label: message == null
            ? emptyState.title
            : '${emptyState.title}，$message',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emptyState.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 一个组件实例里，分给"主要动作"和"明细动作"的两个动作（如果协议下发了的话）。
/// 约定：`actions[0]` 是主要动作（各档位都可能用到），`actions[1]`（如果有）是明细
/// 动作——只在详细档显示，点开一个已登记页面。这是应用内部的排列约定，不是协议本身
/// 的字段名，不需要为此改协议信封 Schema。
class ResolvedComponentActions {
  const ResolvedComponentActions({this.primary, this.detail});

  final ActionDescriptor? primary;
  final ActionDescriptor? detail;
}

ResolvedComponentActions resolveComponentActions(
  List<ActionDescriptor>? actions,
) {
  final list = actions ?? const [];
  return ResolvedComponentActions(
    primary: list.isEmpty ? null : list.first,
    detail: list.length > 1 ? list[1] : null,
  );
}

VoidCallback? callbackForAction(
  BuildContext context,
  ActionDescriptor? action,
  void Function(ActionDescriptor) onAction,
) {
  if (action == null) return null;
  final params = action.params is Map
      ? Map<String, dynamic>.from(action.params as Map)
      : <String, dynamic>{};
  return OnlineActionAvailability.allows(context, action.intent, params)
      ? () => onAction(action)
      : null;
}

/// 依据层：`data.basis.text`（和 empty_state 现有的形状一致，SPEC-009.1 #77）。
String? parseBasisText(Map<String, dynamic> data) {
  final basis = data['basis'];
  if (basis is Map) return basis['text'] as String?;
  return null;
}

/// 一个动作对应的按钮/入口文案：数据里显式给了就用数据的，否则退回按意图给的通用
/// 文案（[intentDefaultLabel]）。
String? labelForAction(
  Map<String, dynamic> data,
  String dataKey,
  ActionDescriptor? action,
) {
  final override = data[dataKey] as String?;
  if (override != null) return override;
  if (action == null) return null;
  return intentDefaultLabel(action.intent);
}
