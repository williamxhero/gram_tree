import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart'
    show ActionDescriptor, EventCorrelationIds;

import '../app/theme.dart';
import '../events/event_recorder.dart';
import '../l10n/app_localizations.dart';
import 'source_types.dart';

/// 这次组合的 `composition_id`，通过 [BuildContext] 往下传给任何组件（SPEC-009.1
/// #82）：来源标记打开"为什么"面板时要在事件里带上它，但渲染每个组件的
/// `ComponentBuilder`（`component_registry.dart`）签名不带这个字段——改那个签名会
/// 牵动全部五个已有组件和它们的测试，这里改用一个更小的口子：`CompositionView`
/// （`composition_view.dart`）渲染时把 `compositionId` 包进这个 InheritedWidget，
/// 任何组件的 `build(context, ...)` 里都能读到。读不到（比如组件单独在测试里渲染，
/// 没有外层 `CompositionView`）时 [of] 返回 `null`，打开面板的事件就不带
/// `ui_composition_id`——不崩溃，只是这条事件的关联 ID 留空。
class CompositionIdScope extends InheritedWidget {
  const CompositionIdScope({
    super.key,
    required this.compositionId,
    required super.child,
  });

  final String compositionId;

  static String? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<CompositionIdScope>()
      ?.compositionId;

  @override
  bool updateShouldNotify(CompositionIdScope oldWidget) =>
      compositionId != oldWidget.compositionId;
}

/// 通用组件：来源标记（SPEC-009.1 #82，CLAUDE.md 第 6 节 UI 规范）。全 App 同一套
/// 样式：
/// * 作者填写（[sourceTypeAuthorFilled]）：不显示标记（[build] 直接返回空 widget）。
/// * 按你的口味换算/按场景调整：酱红（[GramTreeColors.accent]，"系统替你改了"）。
/// * 已验证：绿（[GramTreeColors.verified]）。
/// * AI 估算：中性色、虚线（表示"还没人确认"），颜色取
///   `Theme.of(context).colorScheme.onSurfaceVariant`（和 `component_scaffold.dart`
///   依据文字用的中性色是同一个取色点，不另外写死一个颜色）。
///
/// 点标记打开同一个"为什么"面板（[WhyPanel]），打开前先记一条 `ui.why_panel_opened`
/// 事件（组合 ID、组件实例、来源类型）。
class SourceMark extends ConsumerWidget {
  const SourceMark({
    super.key,
    required this.sourceType,
    required this.componentId,
    required this.value,
    this.originalValue,
    required this.basisText,
    this.citation,
    required this.required,
    this.feedbackEnabled = true,
    this.neutral = false,
    this.valueChanged,
    this.showWhenAuthorFilled = false,
    this.labelOverride,
    this.whyTitleOverride,
    required this.onAction,
  });

  final String sourceType;
  final String componentId;
  final String value;
  final String? originalValue;
  final String basisText;
  final String? citation;

  /// 这个组件是不是必显组件（食品安全、过敏等）——是的话面板不提供"这次不用"/
  /// "以后别这样"两个动作。
  final bool required;

  /// Whether this source can be adjusted from this surface. Immutable recipe
  /// details expose provenance read-only until a real adjustment contract exists.
  final bool feedbackEnabled;

  /// Keep provenance visible without implying that the system changed the value.
  final bool neutral;

  /// Whether the current value is actually different from the original value.
  /// When omitted, the WhyPanel derives this from [value] and [originalValue].
  final bool? valueChanged;

  /// Display-only provenance can retain author-filled data while still
  /// explaining a unit or utensil expression.
  final bool showWhenAuthorFilled;

  /// Optional neutral label for display provenance; source type remains real.
  final String? labelOverride;

  /// Optional neutral WhyPanel title for display provenance.
  final String? whyTitleOverride;

  /// 触发意图的统一入口（就是 `CompositionView` 传给每个组件 builder 的
  /// `onAction`，见 `composition_view.dart`）——"这次不用"/"以后别这样"走的是
  /// 票 5（#81）已有的意图派发，这里不另写处理路径。
  final void Function(ActionDescriptor action)? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sourceType == sourceTypeAuthorFilled && !showWhenAuthorFilled) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colors = GramTreeColors.of(context);
    final color = neutral
        ? theme.colorScheme.onSurfaceVariant
        : _colorFor(sourceType, colors, theme);
    final dashed = sourceType == sourceTypeAiEstimated && !neutral;

    final l10n = AppLocalizations.of(context);
    final label = labelOverride ?? sourceTypeLabel(sourceType, l10n);
    return Semantics(
      button: true,
      label: l10n.sourceSemantics(label),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _open(context, ref),
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: CustomPaint(
            painter: dashed ? _DashedPillBorderPainter(color: color) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: dashed
                  ? null
                  : BoxDecoration(
                      border: Border.all(color: color, width: 1),
                      borderRadius: BorderRadius.circular(999),
                    ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final compositionId = CompositionIdScope.of(context);
    // Feedback actions only appear when a real intent handler receives them;
    // a read-only surface must not offer buttons that do nothing.
    final action = onAction;
    final canFeedback = feedbackEnabled && action != null;
    final currentValueChanged =
        valueChanged ?? (originalValue != null && value != originalValue);

    await ref
        .read(eventRecorderProvider)
        .record(
          eventType: 'ui.why_panel_opened',
          typeVersion: 1,
          correlation: compositionId == null
              ? null
              : EventCorrelationIds(uiCompositionId: compositionId),
          content: {'component_id': componentId, 'source_type': sourceType},
        );
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => WhyPanel(
        key: const ValueKey('why-panel'),
        sourceType: sourceType,
        titleOverride: whyTitleOverride,
        value: value,
        originalValue: originalValue,
        basisText: basisText,
        citation: citation,
        required: required,
        valueChanged: currentValueChanged,
        feedbackEnabled: canFeedback,
        onSkipOnce: required || !canFeedback
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                action(
                  ActionDescriptor(
                    intent: 'skip_this_time',
                    params: _feedbackParams(
                      componentId,
                      sourceType,
                      compositionId,
                    ),
                  ),
                );
              },
        onNeverAgain: required || !canFeedback
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                action(
                  ActionDescriptor(
                    intent: 'dont_do_again',
                    params: _feedbackParams(
                      componentId,
                      sourceType,
                      compositionId,
                    ),
                  ),
                );
              },
      ),
    );
  }
}

Color _colorFor(String sourceType, GramTreeColors colors, ThemeData theme) =>
    switch (sourceType) {
      sourceTypeTasteAdjusted || sourceTypeScenarioAdjusted => colors.accent,
      sourceTypeVerified => colors.verified,
      _ => theme.colorScheme.onSurfaceVariant,
    };

/// `skip_this_time`/`dont_do_again` 的动作参数：`component_id`/`source_type` 两边
/// 登记表都会校验（`intent_registry.dart` 的 `_validateSourceFeedback`），
/// `composition_id` 是可选的（读不到这次组合 ID 时就不带），处理器据此决定要不要
/// 给写的事件带 `ui_composition_id` 关联。
Map<String, dynamic> _feedbackParams(
  String componentId,
  String sourceType,
  String? compositionId,
) => {
  'component_id': componentId,
  'source_type': sourceType,
  'composition_id': ?compositionId,
};

/// 画一个虚线的圆角胶囊边框，只用于 AI 估算的来源标记（"还没人确认"）。Flutter 核心
/// 没有现成的虚线边框，这里手写一个最小够用的 [CustomPainter]，不新增第三方依赖。
class _DashedPillBorderPainter extends CustomPainter {
  const _DashedPillBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dashWidth = 3.0;
    const gapWidth = 2.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPillBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 通用组件："为什么"面板（SPEC-009.1 #82）：点任何来源标记都打开同一个面板，显示
/// 原值（有换算时）、依据说明、来源引用，提供"这次不用"/"以后别这样"两个动作；
/// 必显内容上不提供这两个动作，改显示一句说明。
class WhyPanel extends StatelessWidget {
  const WhyPanel({
    super.key,
    required this.sourceType,
    this.titleOverride,
    required this.value,
    this.originalValue,
    required this.basisText,
    this.citation,
    required this.required,
    this.valueChanged = false,
    this.feedbackEnabled = true,
    this.onSkipOnce,
    this.onNeverAgain,
  });

  final String sourceType;
  final String? titleOverride;
  final String value;
  final String? originalValue;
  final String basisText;
  final String? citation;
  final bool required;
  final bool valueChanged;
  final bool feedbackEnabled;
  final VoidCallback? onSkipOnce;
  final VoidCallback? onNeverAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final explanation = basisText.isEmpty
        ? l10n.sourceBasisUnavailable
        : basisText;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleOverride ?? sourceTypeLabel(sourceType, l10n),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (originalValue != null) ...[
              Text(
                l10n.whyOriginal(originalValue!),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
            ],
            Text(
              l10n.whyCurrent(value),
              style: valueChanged
                  ? theme.textTheme.bodyMedium?.copyWith(
                      color: GramTreeColors.of(context).accent,
                    )
                  : theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(explanation, style: theme.textTheme.bodyMedium),
            if (citation != null) ...[
              const SizedBox(height: 6),
              Text(
                citation!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (!feedbackEnabled)
              const SizedBox.shrink()
            else if (required)
              Text(
                l10n.whyRequired,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSkipOnce,
                      child: Text(l10n.whySkipThisTime),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onNeverAgain,
                      child: Text(l10n.whyDontDoAgain),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
