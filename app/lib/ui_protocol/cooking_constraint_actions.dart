import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart' show ActionDescriptor;

import 'intent_dispatcher.dart';
import 'intent_registry.dart';

/// Mounted controllers retain form values; only a named, empty-argument action
/// crosses the shared intent boundary. No household, measure or meal data enters
/// action descriptors or telemetry. Native settings have no server composition,
/// so dispatch without inventing a composition correlation ID.
class CookingConstraintActionScope extends InheritedWidget {
  const CookingConstraintActionScope({
    super.key,
    required this.intent,
    required this.run,
    required super.child,
  });

  final String intent;
  final FutureOr<void> Function() run;

  @override
  bool updateShouldNotify(CookingConstraintActionScope oldWidget) => true;
}

const _intents = [
  'cooking_constraints_edit',
  'cooking_constraints_save',
  'cooking_constraints_clear',
  'cooking_constraints_confirm_clear',
  'cooking_constraints_cancel',
  'cooking_constraints_retry',
  'personal_measures_manage',
];

final cookingConstraintIntentSpecs = [
  for (final intent in _intents)
    IntentSpec(
      name: intent,
      defaultLabel: intent,
      validateParams: (params) => params.isEmpty,
      handler: (context, ref, params) async {
        final scope = context
            .getInheritedWidgetOfExactType<CookingConstraintActionScope>();
        if (scope?.intent == intent) await scope!.run();
        return null;
      },
    ),
];

Widget cookingConstraintAction(
  WidgetRef ref,
  String intent,
  FutureOr<void> Function() run,
  Widget Function(VoidCallback dispatch) builder,
) => CookingConstraintActionScope(
  intent: intent,
  run: run,
  child: Builder(
    builder: (context) => builder(() {
      ref
          .read(intentDispatcherProvider)
          .dispatch(
            context,
            componentId: intent == 'personal_measures_manage'
                ? 'personal-measures'
                : 'cooking-constraints',
            action: ActionDescriptor(intent: intent, params: const {}),
          );
    }),
  ),
);
