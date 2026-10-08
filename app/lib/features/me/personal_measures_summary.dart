import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../recipes/personal_measure_repository.dart';
import '../../ui_protocol/components/component_scaffold.dart';
import '../recipes/personal_measures_page.dart';

// Native Dart prints whole doubles as 12.0, while JavaScript prints 12.
// Keep the display stable without rounding fractional calibration values.
String _capacityText(num value) => value == value.truncateToDouble()
    ? value.toStringAsFixed(1)
    : value.toString();

/// Read the existing account-scoped measure repository; calibration stays in its
/// existing manager and never mutates recipe quantities.
class PersonalMeasuresSummary extends ConsumerWidget {
  const PersonalMeasuresSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ComponentCard(
      key: const ValueKey('taste-personal-measures'),
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Text(l10n.personalMeasuresTitle),
      conclusionSemanticsText: l10n.personalMeasuresTitle,
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('你登记的量具，仅用于显示，不改变配方。'),
          ref
              .watch(personalMeasuresProvider)
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(l10n.recipeLoadError),
                data: (items) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (items.isEmpty) Text(l10n.personalMeasuresEmpty),
                    for (final item in items)
                      Text(
                        '${item.name} · ${_capacityText(item.capacityMl)} 毫升',
                        key: ValueKey('taste-measure-${item.id}'),
                        style: GramTreeColors.of(
                          context,
                        ).numberStyle(Theme.of(context).textTheme.bodyMedium!),
                      ),
                  ],
                ),
              ),
          TextButton(
            key: const ValueKey('taste-measures-manage'),
            onPressed: () async {
              await context.push(PersonalMeasuresPage.path);
              if (context.mounted) ref.invalidate(personalMeasuresProvider);
            },
            child: const Text('管理个人量具'),
          ),
        ],
      ),
    );
  }
}
