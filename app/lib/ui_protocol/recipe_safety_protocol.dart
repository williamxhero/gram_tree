import 'package:flutter/material.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'component_registry.dart';
import 'composition_view.dart';
import 'recipe_safety.dart';

/// Fixed recipe safety section used by detail and authoring pages.
///
/// This section is deliberately outside optional composition content: service
/// errors, malformed descriptions, offline mode, and dropped experiments must
/// still leave both cards visible. A draft may have no saved result yet, so its
/// cards show the explicit awaiting/unknown state instead of inventing a result.
class RecipeSafetyProtocolSection extends StatelessWidget {
  const RecipeSafetyProtocolSection({
    super.key,
    required this.result,
    required this.legacyDerived,
    required this.dishName,
    required this.snapshot,
    required this.recipeId,
    required this.versionId,
    required this.authoring,
    required this.loading,
    this.errorMessage,
    this.awaitingCheck = false,
  });

  final RecipeSafetyResult? result;
  final RecipeDerived? legacyDerived;
  final String dishName;
  final RecipeSnapshot snapshot;
  final String? recipeId;
  final String? versionId;
  final bool authoring;
  final bool loading;
  final String? errorMessage;
  final bool awaitingCheck;

  @override
  Widget build(BuildContext context) {
    if (authoring) return _standardCards();
    return CompositionView(
      pageType: 'recipe_detail',
      recipeId: recipeId,
      versionId: versionId,
      standardLayoutBuilder: (_) => _standardCards(),
    );
  }

  Widget _standardCards() => Column(
    key: const ValueKey('recipe-safety-protocol-section'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FoodSafetyCard(
        result: result,
        legacyDerived: legacyDerived,
        errorMessage: errorMessage,
        loading: loading,
        awaitingCheck: awaitingCheck,
      ),
      AllergenCard(
        result: result,
        legacyDerived: legacyDerived,
        errorMessage: errorMessage,
        loading: loading,
        awaitingCheck: awaitingCheck,
      ),
    ],
  );
}

/// Adapter for a protocol descriptor. The protocol data is a deliberately
/// small subset, so it is expanded with safe defaults before feeding the
/// shared cards; a missing/unknown result remains visibly unknown.
Widget buildFoodSafetyProtocolComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = _componentData(component.data);
  final result = _resultFromFoodSafety(data['result']);
  final status = data['status'] as String?;
  return FoodSafetyCard(
    result: result,
    statusMessage: status == 'available' ? null : data['conclusion'] as String?,
    awaitingCheck: status == 'unknown',
  );
}

Widget buildAllergenNoticeProtocolComponent(
  BuildContext context,
  ComponentDescriptor component,
  ComponentEmptyState emptyState,
  void Function(ActionDescriptor action) onAction,
) {
  final data = _componentData(component.data);
  final result = _resultFromAllergenNotice(data['result']);
  final status = data['status'] as String?;
  return AllergenCard(
    result: result,
    statusMessage: status == 'available' ? null : data['conclusion'] as String?,
    awaitingCheck: status == 'unknown',
  );
}

Map<String, dynamic> _componentData(Object raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : const <String, dynamic>{};

RecipeSafetyResult? _resultFromFoodSafety(Object? raw) {
  if (raw is! Map) return null;
  final value = Map<String, dynamic>.from(raw);
  value
    ..putIfAbsent('allergens', () => <String>[])
    ..putIfAbsent('allergens_incomplete', () => false)
    ..putIfAbsent('replacement_allergens', () => <Object?>[])
    ..putIfAbsent('prohibited_claims', () => <String>[])
    ..putIfAbsent('can_save', () => true)
    ..putIfAbsent('checked_at', () => DateTime.now().toUtc().toIso8601String())
    ..putIfAbsent('rules_version', () => 'unknown');
  try {
    return RecipeSafetyResult.fromJson(value);
  } catch (_) {
    return null;
  }
}

RecipeSafetyResult? _resultFromAllergenNotice(Object? raw) {
  if (raw is! Map) return null;
  final value = Map<String, dynamic>.from(raw);
  value
    ..putIfAbsent('findings', () => <Object?>[])
    ..putIfAbsent('high_risk', () => false)
    ..putIfAbsent('prohibited_claims', () => <String>[])
    ..putIfAbsent('can_save', () => true)
    ..putIfAbsent('checked_at', () => DateTime.now().toUtc().toIso8601String())
    ..putIfAbsent('rules_version', () => 'unknown');
  try {
    return RecipeSafetyResult.fromJson(value);
  } catch (_) {
    return null;
  }
}
