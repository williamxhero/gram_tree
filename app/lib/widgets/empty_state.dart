import 'package:flutter/material.dart';

/// Standard empty-state block: an icon, a title, one explanatory line and an
/// optional action. Scrolls instead of overflowing at large text sizes.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// 放在说明和按钮下面的额外内容，例如受能力开关控制的入口。
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 64).clamp(0, double.infinity),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: colors.primary),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 24),
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel!, textAlign: TextAlign.center),
                  ),
                ],
                ?footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
