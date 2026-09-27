import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// The fixed five-entry bottom bar: 今天、发现、＋、记录、我的.
///
/// The center entry is the primary "＋" button. Label text scaling is capped so
/// that the bar stays usable at the largest system font sizes; every entry
/// keeps its full semantics label for screen readers.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  /// Index of the center primary button.
  static const createIndex = 2;

  /// Largest text scale applied to the bar's labels.
  static const maxLabelScale = 1.4;

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final items = [
      (Icons.wb_sunny_outlined, Icons.wb_sunny, l10n.tabToday),
      (Icons.explore_outlined, Icons.explore, l10n.tabDiscover),
      (Icons.add, Icons.add, l10n.tabCreate),
      (Icons.menu_book_outlined, Icons.menu_book, l10n.tabRecords),
      (Icons.person_outline, Icons.person, l10n.tabMe),
    ];

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxLabelScale,
      child: Material(
        color: colors.surfaceContainer,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: i == createIndex
                        ? _CreateButton(
                            label: items[i].$3,
                            selected: currentIndex == i,
                            onTap: () => onSelected(i),
                          )
                        : _NavItem(
                            icon: items[i].$1,
                            selectedIcon: items[i].$2,
                            label: items[i].$3,
                            selected: currentIndex == i,
                            onTap: () => onSelected(i),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Center(
        heightFactor: 1,
        child: Material(
          key: const ValueKey('primary-create-button'),
          color: colors.primary,
          shape: CircleBorder(
            side: selected
                ? BorderSide(color: colors.primaryContainer, width: 3)
                : BorderSide.none,
          ),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 56,
              child: Icon(Icons.add, size: 32, color: colors.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
