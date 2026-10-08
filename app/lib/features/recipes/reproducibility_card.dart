import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../../ui_protocol/components/component_scaffold.dart';

/// Presents server-owned checks; completeness is not a verification or publish gate.
class ReproducibilityCard extends StatelessWidget {
  const ReproducibilityCard({super.key, required this.result, this.onLocate});

  final RecipeReproducibilityResult? result;
  final VoidCallback? onLocate;

  @override
  Widget build(BuildContext context) {
    final value = result;
    final conclusion = value == null
        ? '尚未检查可复刻性'
        : value.remainingCount == 0
        ? '所有执行字段已具体化 · 可复刻'
        : '还有 ${value.remainingCount} 处需要确定';
    return ComponentCard(
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Text(
        conclusion,
        key: const ValueKey('recipe-reproducibility-status'),
      ),
      conclusionSemanticsText: conclusion,
      standardExtra: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('可以先保存私有版本。可复刻不代表已验证；这里不执行公开门槛。'),
            if (value != null) ...[
              Text(
                '执行字段完整度：${(value.fieldCompleteness * 100).round()}%（${value.concreteFieldCount} / ${value.requiredFieldCount}）',
                style: GramTreeColors.of(context).numberStyle(
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                ),
              ),
              if (value.remainingCount > 0 && onLocate != null)
                OutlinedButton.icon(
                  key: const ValueKey('recipe-reproducibility-locate'),
                  onPressed: onLocate,
                  icon: const Icon(Icons.my_location),
                  label: const Text('定位下一处'),
                ),
              Material(
                color: Colors.transparent,
                child: ExpansionTile(
                  title: const Text('检查明细'),
                  children: [
                    Text('规则版本：${value.rulesVersion}'),
                    for (final problem
                        in value.problems ?? const <ReproducibilityProblem>[])
                      ListTile(
                        title: Text(problem.message),
                        subtitle: Text(
                          '${problem.position.itemId ?? '菜谱'} · ${problem.position.field}',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
