import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../recipes/batch_advice.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/source_mark.dart';
import '../../ui_protocol/source_types.dart';

class BatchAdviceSection extends ConsumerStatefulWidget {
  const BatchAdviceSection({
    super.key,
    required this.recipeId,
    required this.versionId,
    required this.targetServings,
    required this.snapshot,
  });

  final String recipeId;
  final String versionId;
  final int targetServings;
  final RecipeSnapshot snapshot;

  @override
  ConsumerState<BatchAdviceSection> createState() => _BatchAdviceSectionState();
}

class _BatchAdviceSectionState extends ConsumerState<BatchAdviceSection>
    with AutomaticKeepAliveClientMixin {
  // Scrolling past this card must not throw away the already requested advice.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final recipeId = widget.recipeId;
    final versionId = widget.versionId;
    final targetServings = widget.targetServings;
    final snapshot = widget.snapshot;
    final target = (
      recipeId: recipeId,
      versionId: versionId,
      servings: targetServings,
    );
    final request = ref.watch(batchAdviceProvider(target));
    final result = request?.value;
    // Even a valid response may not describe the selection currently on screen.
    final matching =
        result?.recipeId == recipeId &&
        result?.versionId == versionId &&
        result?.targetServings == targetServings;
    final advice = matching ? result?.advice : null;
    final steps = {
      for (final step in snapshot.steps ?? const []) step.id: step,
    };
    final reason = matching ? result?.error ?? result?.status.reason : null;
    final retryable =
        (reason == 'invalid_model_output' || reason == 'model_unavailable') &&
        (result?.status.remaining ?? 0) > 0;
    final unavailable =
        matching && result?.status.available == false && !retryable;
    final busy = request?.isLoading == true;
    final compositionId = 'batch-advice-$versionId-$targetServings';
    return CompositionIdScope(
      compositionId: compositionId,
      child: ComponentCard(
        key: const ValueKey('recipe-batch-advice'),
        detail: ComponentDescriptorDetailEnum.detailed,
        conclusion: Text(
          advice == null ? '大份量时间建议' : 'AI 建议 · 只读，不修改菜谱',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        conclusionSemanticsText: '大份量 AI 时间建议，仅供参考，不修改菜谱',
        basisText: advice?.basis ?? '根据当前版本和目标份数建议；原时长、温度和用量换算仍保留。',
        standardExtra: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前版本 · $targetServings 人份'),
            const Text('以实际成熟判断为准，不能只看建议时间。'),
            if (matching) Text('AI 今日剩余 ${result!.status.remaining} 次'),
            if (busy) const Text('正在请求 AI 建议…'),
            if (request?.hasError == true)
              const Text('网络或服务暂不可用，请重试。原用量换算和步骤仍可使用。'),
            if (reason != null) Text(_reasonText(reason)),
            if (advice != null) ...[
              Text('风险 / 不确定性：${advice.risk}'),
              for (final item in advice.steps) ...[
                const SizedBox(height: 12),
                Text('步骤：${steps[item.stepId]?.instruction ?? item.stepId}'),
                Text('原时长：${steps[item.stepId]?.durationSeconds ?? 0} 秒'),
                Text(
                  '建议时长：${item.suggestedDurationSeconds} 秒',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontFamily: 'DM Mono'),
                ),
                Text('分 ${item.batchCount} 批：${item.batchGuidance}'),
                Text('成熟判断：${item.doneness}'),
                Text('风险 / 不确定性：${item.risk}'),
                Text(
                  '把握程度：${item.confidence >= 0.8
                      ? '高'
                      : item.confidence >= 0.5
                      ? '中'
                      : '低'}',
                ),
                SourceMark(
                  sourceType: sourceTypeAiEstimated,
                  componentId: 'batch-advice-${item.stepId}',
                  value:
                      '${item.suggestedDurationSeconds} 秒，分 ${item.batchCount} 批',
                  originalValue:
                      '${steps[item.stepId]?.durationSeconds ?? 0} 秒',
                  basisText: item.basis,
                  required: false,
                  feedbackEnabled: false,
                  valueChanged: false,
                  onAction: null,
                ),
              ],
            ],
          ],
        ),
        primaryActionLabel: busy ? '正在请求…' : 'AI 建议时间',
        onPrimaryAction: busy || unavailable
            ? null
            : () => ref
                  .read(intentDispatcherProvider)
                  .dispatch(
                    context,
                    compositionId: compositionId,
                    componentId: 'recipe-batch-advice',
                    action: ActionDescriptor(
                      intent: 'request_batch_advice',
                      params: {
                        'recipe_id': recipeId,
                        'version_id': versionId,
                        'target_servings': targetServings,
                      },
                    ),
                  ),
      ),
    );
  }
}

String _reasonText(String reason) => switch (reason) {
  'daily_quota' => '今日 AI 额度已用完，原用量换算和步骤仍可使用。',
  'monthly_budget' => 'AI 预算暂不可用，原用量换算和步骤仍可使用。',
  'model_unavailable' => 'AI 模型暂不可用，原用量换算和步骤仍可使用。',
  'below_batch_threshold' => '当前份数未达到大份量建议阈值。',
  'invalid_model_output' => 'AI 未能给出可靠建议，请重试；原步骤不变。',
  _ => 'AI 暂不可用（$reason），原用量换算和步骤仍可使用。',
};
