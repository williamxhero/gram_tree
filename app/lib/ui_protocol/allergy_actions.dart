import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart' show ActionDescriptor;

import 'intent_dispatcher.dart';
import 'intent_registry.dart';

/// Only action names cross the intent/event boundary. Values, query text and
/// authorization receipts stay in account/generation-guarded page handlers.
class AllergyActionScope extends InheritedWidget {
  const AllergyActionScope({
    super.key,
    required this.intent,
    required this.run,
    required super.child,
  });
  final String intent;
  final FutureOr<void> Function() run;
  @override
  bool updateShouldNotify(AllergyActionScope oldWidget) => true;
}

const _names = [
  'edit',
  'agree',
  'refuse',
  'save',
  'cancel',
  'search',
  'pick',
  'remove',
  'toggle',
  'why',
  'withdraw',
  'confirm_withdraw',
];
final allergyIntentSpecs = [
  for (final name in _names)
    IntentSpec(
      name: 'allergies_$name',
      defaultLabel: 'allergies_$name',
      validateParams: (params) => params.isEmpty,
      handler: (context, ref, params) async {
        final scope = context
            .getInheritedWidgetOfExactType<AllergyActionScope>();
        if (scope?.intent == 'allergies_$name') await scope!.run();
      },
    ),
];

Widget allergyAction(
  WidgetRef ref,
  String name,
  FutureOr<void> Function() run,
  Widget Function(VoidCallback dispatch) builder,
) {
  final intent = 'allergies_$name';
  return AllergyActionScope(
    intent: intent,
    run: run,
    child: Builder(
      builder: (context) => builder(() {
        ref
            .read(intentDispatcherProvider)
            .dispatch(
              context,
              componentId: intent,
              action: ActionDescriptor(intent: intent, params: const {}),
            );
      }),
    ),
  );
}
