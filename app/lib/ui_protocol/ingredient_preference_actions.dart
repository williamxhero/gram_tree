import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart' show ActionDescriptor;

import 'intent_dispatcher.dart';
import 'intent_registry.dart';

class IngredientPreferenceActionScope extends InheritedWidget {
  const IngredientPreferenceActionScope({
    super.key,
    required this.intent,
    required this.run,
    required super.child,
  });

  final String intent;
  final FutureOr<void> Function() run;

  @override
  bool updateShouldNotify(IngredientPreferenceActionScope oldWidget) => true;
}

const _names = [
  'add',
  'delete',
  'confirm_delete',
  'cancel',
  'search',
  'pick',
  'category',
  'choice',
  'change',
  'save',
];

final ingredientPreferenceIntentSpecs = [
  for (final name in _names)
    IntentSpec(
      name: 'ingredient_preferences_$name',
      defaultLabel: 'ingredient_preferences_$name',
      validateParams: (params) => params.isEmpty,
      handler: (context, ref, params) async {
        final scope = context
            .getInheritedWidgetOfExactType<IngredientPreferenceActionScope>();
        if (scope?.intent == 'ingredient_preferences_$name') await scope!.run();
        return null;
      },
    ),
];

/// Native callbacks retain choice values and search text; only an empty action
/// descriptor and a generic component ID cross the intent/event boundary.
class IngredientPreferenceAction extends ConsumerStatefulWidget {
  const IngredientPreferenceAction({
    super.key,
    required this.name,
    required this.builder,
  });

  final String name;
  final Widget Function(void Function(FutureOr<void> Function() run) dispatch)
  builder;

  @override
  ConsumerState<IngredientPreferenceAction> createState() =>
      _IngredientPreferenceActionState();
}

class _IngredientPreferenceActionState
    extends ConsumerState<IngredientPreferenceAction> {
  Future<void> _queued = Future<void>.value();
  FutureOr<void> Function()? _active;

  void _dispatch(BuildContext context, FutureOr<void> Function() run) {
    Future<void> execute() async {
      if (!mounted || !context.mounted) {
        return;
      }
      _active = run;
      try {
        final intent = 'ingredient_preferences_${widget.name}';
        await ref
            .read(intentDispatcherProvider)
            .dispatch(
              context,
              componentId: 'ingredient-preferences',
              action: ActionDescriptor(intent: intent, params: const {}),
            );
      } finally {
        _active = null;
      }
    }

    // Keep each captured dropdown choice paired with its dispatch, including
    // across rebuilds while the optional event recorder completes.
    _queued = _queued.then(
      (_) => execute(),
      onError: (Object _, StackTrace _) => execute(),
    );
  }

  @override
  Widget build(BuildContext context) => IngredientPreferenceActionScope(
    intent: 'ingredient_preferences_${widget.name}',
    run: () => _active?.call(),
    child: Builder(
      builder: (context) => widget.builder((run) => _dispatch(context, run)),
    ),
  );
}
