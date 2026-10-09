import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart' show ActionDescriptor;

import 'intent_dispatcher.dart';
import 'intent_registry.dart';

class FamilyActionScope extends InheritedWidget {
  const FamilyActionScope({
    super.key,
    required this.intent,
    required this.run,
    required super.child,
  });

  final String intent;
  final FutureOr<void> Function() run;

  @override
  bool updateShouldNotify(FamilyActionScope oldWidget) => true;
}

const _names = [
  'add',
  'view',
  'edit',
  'delete',
  'confirm_delete',
  'retry_delete',
  'agree',
  'refuse',
  'close',
  'why',
  'age',
  'flavor',
  'avoidance_add',
  'avoidance_remove',
  'allergy_toggle',
  'allergy_add',
  'allergy_remove',
  'cancel',
  'save',
];

final familyIntentSpecs = [
  for (final name in _names)
    IntentSpec(
      name: 'family_$name',
      defaultLabel: 'family_$name',
      validateParams: (params) => params.isEmpty,
      handler: (context, ref, params) async {
        final scope = context
            .getInheritedWidgetOfExactType<FamilyActionScope>();
        if (scope?.intent == 'family_$name') await scope!.run();
      },
    ),
];

/// Sensitive values stay in guarded native callbacks, never action parameters
/// or event IDs. Keep each captured choice paired with its dispatch across
/// rebuilds while optional telemetry completes, as in ingredient preferences.
class FamilyAction extends ConsumerStatefulWidget {
  const FamilyAction({super.key, required this.name, required this.builder});

  final String name;
  final Widget Function(void Function(FutureOr<void> Function() run) dispatch)
  builder;

  @override
  ConsumerState<FamilyAction> createState() => _FamilyActionState();
}

class _FamilyActionState extends ConsumerState<FamilyAction> {
  Future<void> _queued = Future<void>.value();
  FutureOr<void> Function()? _active;

  void _dispatch(BuildContext context, FutureOr<void> Function() run) {
    Future<void> execute() async {
      if (!mounted || !context.mounted) return;
      _active = run;
      try {
        await ref
            .read(intentDispatcherProvider)
            .dispatch(
              context,
              componentId: 'family-members',
              action: ActionDescriptor(
                intent: 'family_${widget.name}',
                params: const {},
              ),
            );
      } finally {
        _active = null;
      }
    }

    _queued = _queued.then(
      (_) => execute(),
      onError: (Object _, StackTrace _) => execute(),
    );
  }

  @override
  Widget build(BuildContext context) => FamilyActionScope(
    intent: 'family_${widget.name}',
    run: () => _active?.call(),
    child: Builder(
      builder: (context) => widget.builder((run) => _dispatch(context, run)),
    ),
  );
}
