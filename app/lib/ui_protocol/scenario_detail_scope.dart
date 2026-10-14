import 'package:flutter/widgets.dart';

/// The registered detail intent changes only the active page's state. It never
/// writes the user's default or shares an override with another route.
class ScenarioDetailScope extends InheritedWidget {
  const ScenarioDetailScope({
    super.key,
    required this.onChanged,
    this.onSkip,
    this.onBeforeTaste,
    this.onTasteReverted,
    required super.child,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSkip;
  final Future<void> Function(String changeId)? onBeforeTaste;
  final VoidCallback? onTasteReverted;

  static ScenarioDetailScope? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ScenarioDetailScope>();

  static void change(BuildContext context, String detail) {
    context.getInheritedWidgetOfExactType<ScenarioDetailScope>()?.onChanged(
      detail,
    );
  }

  @override
  bool updateShouldNotify(ScenarioDetailScope oldWidget) =>
      onChanged != oldWidget.onChanged;
}
