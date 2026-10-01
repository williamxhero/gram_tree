import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/tab_page.dart';
import '../recipes/personal_measures_page.dart';
import '../recipes/recipe_pages.dart';
import 'account_data.dart';
import 'settings_page.dart';

/// “我的”：第一眼只有昵称；账号、登录方式和隐私入口都在设置里。
class MePage extends ConsumerWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).value;
    final email = ref
        .watch(identitiesProvider)
        .value
        ?.map((i) => i.email)
        .whereType<String>()
        .firstOrNull;
    return TabPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  user?.nickname ?? '',
                  key: const ValueKey('me-nickname'),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: l10n.meEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _editNickname(context, ref),
              ),
            ],
          ),
          if (email != null)
            Text(
              email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            l10n.meEmptyBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            key: const ValueKey('my-recipes-list-entry'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.myRecipes),
            subtitle: Text(l10n.myRecipesSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RecipeListPage.path),
          ),
          ListTile(
            key: const ValueKey('personal-measures-entry'),
            contentPadding: EdgeInsets.zero,
            title: const Text('自家量具'),
            subtitle: const Text('登记勺、碗、杯的满水容量'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(PersonalMeasuresPage.path),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(SettingsPage.path),
          ),
        ],
      ),
    );
  }

  Future<void> _editNickname(BuildContext context, WidgetRef ref) async {
    final current = ref.read(authProvider).value?.nickname ?? '';
    await showDialog<void>(
      context: context,
      builder: (_) => _NicknameDialog(initial: current),
    );
  }
}

class _NicknameDialog extends ConsumerStatefulWidget {
  const _NicknameDialog({required this.initial});

  final String initial;

  @override
  ConsumerState<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends ConsumerState<_NicknameDialog> {
  late final _text = TextEditingController(text: widget.initial);
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _text.text.trim();
    if (name.isEmpty || name.characters.length > nicknameMaxLength) {
      setState(() => _error = l10n.meNicknameHint(nicknameMaxLength));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(nickname: name);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = ApiFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.meNicknameTitle),
      content: TextField(
        key: const ValueKey('nickname-input'),
        controller: _text,
        autofocus: true,
        decoration: InputDecoration(
          helperText: l10n.meNicknameHint(nicknameMaxLength),
          errorText: _error,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _busy ? null : _save, child: Text(l10n.save)),
      ],
    );
  }
}
