import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:gramtree_api/gramtree_api.dart';

/// Concrete SPEC-002.4 actions. The registry validates serializable parameters;
/// the mounted editor supplies state adapters, never callbacks in action data.
const recipeOperations = {
  'check',
  'quantify',
  'locate',
  'cancel',
  'choose',
  'decide',
  'text_preview',
  'text_choose',
  'text_confirm',
  'text_cancel',
  'text_retry_status',
  'text_retry_checks',
};

bool validateRecipeOperation(Map<String, dynamic> params) {
  final operation = params['operation'];
  if (!recipeOperations.contains(operation)) return false;
  if (operation == 'text_preview') {
    return params.keys.every({'operation', 'text'}.contains) &&
        params['text'] is String &&
        (params['text'] as String).trim().isNotEmpty &&
        (params['text'] as String).length <= 1000;
  }
  if (operation == 'text_choose') {
    return params.keys.every(
          {'operation', 'operation_id', 'decision', 'after'}.contains,
        ) &&
        params['operation_id'] is String &&
        (params['operation_id'] as String).isNotEmpty &&
        {'accept', 'reject', 'modify'}.contains(params['decision']) &&
        (params['decision'] == 'modify'
            ? params.containsKey('after') &&
                  _boundedModificationValue(params['after'])
            : !params.containsKey('after'));
  }
  if (operation == 'choose') {
    return params.keys.every(
          {'operation', 'problem_id', 'decision'}.contains,
        ) &&
        params['problem_id'] is String &&
        (params['problem_id'] as String).trim().isNotEmpty &&
        {'accept', 'modify', 'ignore'}.contains(params['decision']);
  }
  if (operation != 'decide') return params.length == 1;
  if (!params.keys.every({'operation', 'accept_all', 'decisions'}.contains)) {
    return false;
  }
  final decisions = params['decisions'];
  if (params['accept_all'] == true) {
    return decisions is List && decisions.isEmpty;
  }
  if (params['accept_all'] != false ||
      decisions is! List ||
      decisions.isEmpty) {
    return false;
  }
  final ids = <String>{};
  for (final decision in decisions) {
    if (decision is! Map ||
        !decision.keys.every(
          {'problem_id', 'decision', 'value', 'unit'}.contains,
        )) {
      return false;
    }
    final id = decision['problem_id'];
    if (id is! String || id.trim().isEmpty || !ids.add(id)) return false;
    if (!{'accept', 'modify', 'ignore'}.contains(decision['decision'])) {
      return false;
    }
    final value = decision['value'];
    final unit = decision['unit'];
    if (decision['decision'] == 'modify') {
      if (value is! String ||
          value.trim().isEmpty ||
          (unit != null && (unit is! String || unit.trim().isEmpty))) {
        return false;
      }
    } else if (value != null || unit != null) {
      return false;
    }
  }
  return true;
}

bool _boundedModificationValue(Object? value) {
  bool valid(Object? value, int depth) {
    if (depth > 8) return false;
    if (value == null || value is bool) return true;
    if (value is num) return value.isFinite;
    if (value is String) return value.length <= 4000;
    if (value is List) {
      return value.length <= 100 &&
          value.every((item) => valid(item, depth + 1));
    }
    if (value is Map) {
      return value.length <= 100 &&
          value.entries.every(
            (entry) =>
                entry.key is String &&
                valid(entry.key, depth + 1) &&
                valid(entry.value, depth + 1),
          );
    }
    return false;
  }

  if (!valid(value, 0)) return false;
  return value is String || jsonEncode(value).length <= 4000;
}

Map<String, dynamic> recipeDecisionParams(
  List<QuantificationDecision> decisions,
  bool acceptAll,
) => {
  'operation': 'decide',
  'accept_all': acceptAll,
  'decisions': decisions.map((d) => d.toJson()).toList(),
};

List<QuantificationDecision> recipeDecisions(Map<String, dynamic> params) =>
    (params['decisions'] as List)
        .map(
          (d) => QuantificationDecision.fromJson(
            Map<String, dynamic>.from(d as Map),
          ),
        )
        .toList();

/// Both buttons and the fixed one-line commands produce the same action.
ActionDescriptor? recipeCommand(String text) => switch (text.trim()) {
  '检查可复刻性' => ActionDescriptor(
    intent: 'recipe_operation',
    params: {'operation': 'check'},
  ),
  '保存并请求 AI 量化' || '请求量化' => ActionDescriptor(
    intent: 'recipe_operation',
    params: {'operation': 'quantify'},
  ),
  '定位下一处' => ActionDescriptor(
    intent: 'recipe_operation',
    params: {'operation': 'locate'},
  ),
  '全部接受' => ActionDescriptor(
    intent: 'recipe_operation',
    params: recipeDecisionParams(const [], true),
  ),
  '暂不处理' => ActionDescriptor(
    intent: 'recipe_operation',
    params: {'operation': 'cancel'},
  ),
  _ => null,
};

typedef RecipeOperationHandler = FutureOr<void> Function(
  Map<String, dynamic> params,
);

class RecipeOperationScope extends InheritedWidget {
  const RecipeOperationScope({
    super.key,
    required this.handlers,
    required super.child,
  });
  final Map<String, RecipeOperationHandler> handlers;

  static Future<void> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    RecipeOperationHandler? handler;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is RecipeOperationScope) {
        handler = widget.handlers[params['operation']];
      }
      return handler == null;
    });
    if (handler != null) await handler!(params);
  }

  @override
  bool updateShouldNotify(RecipeOperationScope oldWidget) =>
      handlers != oldWidget.handlers;
}
