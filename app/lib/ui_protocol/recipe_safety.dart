import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../l10n/app_localizations.dart';
import 'components/component_scaffold.dart';

/// The mandatory safety card used by recipe detail and authoring surfaces.
///
/// [legacyDerived] is intentionally accepted while older saved versions are
/// being migrated: it keeps the allergen fallback visible, but never invents a
/// safety finding that the server did not return.
class FoodSafetyCard extends StatelessWidget {
  const FoodSafetyCard({
    super.key,
    this.result,
    this.legacyDerived,
    this.errorMessage,
    this.statusMessage,
    this.loading = false,
    this.awaitingCheck = false,
  });

  final RecipeSafetyResult? result;
  final RecipeDerived? legacyDerived;
  final String? errorMessage;
  final String? statusMessage;
  final bool loading;
  final bool awaitingCheck;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final findings = result?.findings ?? const <RecipeSafetyFinding>[];
    final status = _safetyStatus(
      l10n,
      loading: loading,
      awaitingCheck: awaitingCheck,
      errorMessage: errorMessage,
      statusMessage: statusMessage,
      result: result,
    );
    final highRisk =
        result?.highRisk == true ||
        findings.any((finding) => _severity(finding) == 'high_risk');

    return ComponentCard(
      key: const ValueKey('recipe-food-safety-card'),
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Row(
        children: [
          Icon(
            highRisk ? Icons.warning_amber_rounded : Icons.health_and_safety,
            color: highRisk
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            semanticLabel: highRisk ? l10n.recipeSafetyHighRisk : null,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.recipeSafetyTitle)),
        ],
      ),
      conclusionSemanticsText: l10n.recipeSafetyTitle,
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status != null)
            _SafetyNotice(
              key: const ValueKey('recipe-safety-status'),
              icon: loading ? Icons.hourglass_top : Icons.info_outline,
              text: status,
            ),
          if (highRisk)
            _SafetyNotice(
              key: const ValueKey('recipe-safety-high-risk'),
              icon: Icons.warning_amber_rounded,
              text: l10n.recipeSafetyHighRisk,
              emphasis: true,
            ),
          if (findings.isEmpty && status == null)
            Text(l10n.recipeSafetyNoFindings),
          for (final finding in findings) _FindingView(finding: finding),
          if ((result?.prohibitedClaims ?? const []).isNotEmpty)
            _SafetyNotice(
              key: const ValueKey('recipe-safety-prohibited-claims'),
              icon: Icons.edit_note,
              text: l10n.recipeSafetyClaims(
                (result!.prohibitedClaims ?? const <String>[]).join('、'),
                result!.claimBasis ?? l10n.recipeSafetyClaimRewrite,
              ),
              emphasis: true,
            ),
        ],
      ),
      basisText: result?.rulesVersion == null
          ? null
          : l10n.recipeSafetyRulesVersion(result!.rulesVersion),
    );
  }
}

/// The mandatory allergen card. It uses a saved safety result when available,
/// and falls back to the immutable derived fields for legacy versions.
class AllergenCard extends StatelessWidget {
  const AllergenCard({
    super.key,
    this.result,
    this.legacyDerived,
    this.errorMessage,
    this.statusMessage,
    this.loading = false,
    this.awaitingCheck = false,
    this.personalSafety,
  });

  final RecipeSafetyResult? result;
  final RecipeDerived? legacyDerived;
  final String? errorMessage;
  final String? statusMessage;
  final bool loading;
  final bool awaitingCheck;
  final Map<String, dynamic>? personalSafety;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasAllergenData = result != null || legacyDerived != null;
    final allergens =
        result?.allergens ?? legacyDerived?.allergens ?? const <String>[];
    final incomplete =
        result?.allergensIncomplete == true ||
        (result == null && legacyDerived?.allergensIncomplete == true);
    final replacements =
        result?.replacementAllergens ?? const <RecipeReplacementAllergens>[];
    final status = _safetyStatus(
      l10n,
      loading: loading,
      awaitingCheck: awaitingCheck,
      errorMessage: errorMessage,
      statusMessage: statusMessage,
      result: result,
    );
    final allergenText = allergens.isEmpty
        ? l10n.recipeAllergenNone
        : allergens.join('、');

    return ComponentCard(
      key: const ValueKey('recipe-allergen-card'),
      detail: ComponentDescriptorDetailEnum.standard,
      conclusion: Row(
        children: [
          Icon(
            Icons.no_food_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.recipeAllergenTitle)),
        ],
      ),
      conclusionSemanticsText: l10n.recipeAllergenTitle,
      standardExtra: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status != null)
            _SafetyNotice(
              key: const ValueKey('recipe-allergen-status'),
              icon: loading ? Icons.hourglass_top : Icons.info_outline,
              text: status,
            ),
          if (hasAllergenData)
            Text(
              l10n.recipeAllergens(
                allergenText,
                incomplete ? l10n.recipeIncomplete : '',
              ),
              key: const ValueKey('recipe-allergen-list'),
            ),
          for (final replacement in replacements)
            _ReplacementAllergenView(replacement: replacement),
          if (personalSafety != null)
            _PersonalSafetyNotices(data: personalSafety!),
        ],
      ),
      basisText: incomplete ? l10n.recipeAllergenIncompleteBasis : null,
    );
  }
}

class _PersonalSafetyNotices extends StatelessWidget {
  const _PersonalSafetyNotices({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final alerts = (data['alerts'] as List? ?? const []).whereType<Map>().map(
      (item) => Map<String, dynamic>.from(item),
    );
    final unknown = (data['unknown_ingredients'] as List? ?? const [])
        .whereType<String>()
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final alert in alerts)
          _SafetyNotice(
            key: ValueKey(
              'personal-safety-${alert['person']}-${alert['kind']}-${alert['ingredient']}',
            ),
            icon: alert['kind'] == 'allergy'
                ? Icons.warning_amber_rounded
                : Icons.info_outline,
            text:
                '${alert['kind'] == 'allergy' ? '过敏提醒' : '忌口提醒'}：${alert['person']}，${alert['target']}（${alert['ingredient']}${alert['replacement'] == true ? '，替代食材' : ''}）',
            emphasis: alert['kind'] == 'allergy',
          ),
        if (unknown.isNotEmpty)
          _SafetyNotice(
            key: const ValueKey('personal-safety-unknown'),
            icon: Icons.help_outline,
            text: '以下食材未标准化，无法确认个人过敏或忌口风险：${unknown.join('、')}',
          ),
      ],
    );
  }
}

class _FindingView extends StatelessWidget {
  const _FindingView({required this.finding});

  final RecipeSafetyFinding finding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final severity = _severity(finding);
    final color = severity == 'high_risk'
        ? Theme.of(context).colorScheme.error
        : severity == 'warning'
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final threshold = finding.thresholdCelsius;
    final rest = finding.restMinutes;
    final details = <String>[
      if (threshold != null) l10n.recipeSafetyThreshold(threshold.toString()),
      if (rest != null) l10n.recipeSafetyRest(rest),
      if (finding.stepIds?.isNotEmpty == true)
        l10n.recipeSafetySteps(finding.stepIds!.join('、')),
    ];
    return Semantics(
      container: true,
      label: [
        _severityLabel(severity, l10n),
        finding.message,
        finding.basis,
        ...details,
      ].join('，'),
      child: Container(
        key: ValueKey('recipe-safety-finding-${finding.ruleId}'),
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              severity == 'high_risk'
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline,
              color: color,
              semanticLabel: _severityLabel(severity, l10n),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    finding.message,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (finding.basis.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(finding.basis),
                  ],
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(details.join(' · ')),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplacementAllergenView extends StatelessWidget {
  const _ReplacementAllergenView({required this.replacement});

  final RecipeReplacementAllergens replacement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allergens =
        replacement.allergens == null || replacement.allergens!.isEmpty
        ? l10n.recipeAllergenNone
        : replacement.allergens!.join('、');
    return Container(
      key: ValueKey('recipe-replacement-allergens-${replacement.ingredientId}'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        l10n.recipeReplacementAllergens(
          replacement.displayName,
          allergens,
          replacement.incomplete == true ? l10n.recipeIncomplete : '',
        ),
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice({
    super.key,
    required this.icon,
    required this.text,
    this.emphasis = false,
  });

  final IconData icon;
  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final color = emphasis
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        liveRegion: true,
        container: true,
        label: text,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: emphasis ? FontWeight.w700 : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _safetyStatus(
  AppLocalizations l10n, {
  required bool loading,
  required bool awaitingCheck,
  required String? errorMessage,
  required String? statusMessage,
  required RecipeSafetyResult? result,
}) {
  if (loading) return l10n.recipeSafetyLoading;
  if (errorMessage != null && errorMessage.isNotEmpty) {
    return l10n.recipeSafetyError(errorMessage);
  }
  if (statusMessage != null && statusMessage.isNotEmpty) return statusMessage;
  if (awaitingCheck) return l10n.recipeSafetyAwaitingCheck;
  if (result == null) return l10n.recipeSafetyUnavailable;
  if (result.stale == true) return l10n.recipeSafetyStale;
  return null;
}

String _severity(RecipeSafetyFinding finding) => finding.severity.toString();

String _severityLabel(String severity, AppLocalizations l10n) =>
    switch (severity) {
      'high_risk' => l10n.recipeSafetyHighRisk,
      'warning' => l10n.recipeSafetyWarning,
      _ => l10n.recipeSafetyInfo,
    };
