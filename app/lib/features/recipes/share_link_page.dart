import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart' show ActionDescriptor;

import '../../auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../recipes/recipe_sharing.dart';
import '../../ui_protocol/intent_dispatcher.dart';
import '../../ui_protocol/source_mark.dart';

/// Opaque public links resolve through a minimal API, never embedded recipe data.
class ShareLinkPage extends ConsumerStatefulWidget {
  const ShareLinkPage({super.key, required this.shareId});
  final String shareId;
  @override
  ConsumerState<ShareLinkPage> createState() => _ShareLinkPageState();
}

class _ShareLinkPageState extends ConsumerState<ShareLinkPage> {
  String? _target;
  bool _unavailable = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(ShareLinkPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shareId == widget.shareId) return;
    _target = null;
    _unavailable = false;
    _opening = false;
    _resolve();
  }

  Future<void> _resolve() async {
    final shareId = widget.shareId;
    try {
      final path = await ref.read(recipeSharingProvider).resolve(shareId);
      if (mounted && widget.shareId == shareId) setState(() => _target = path);
    } catch (_) {
      if (mounted && widget.shareId == shareId) {
        setState(() => _unavailable = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context);
    if (_target != null && auth.value != null && !_opening) {
      _opening = true;
      final target = _target;
      final shareId = widget.shareId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.shareId == shareId && _target == target) {
          context.go(target!);
        }
      });
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sharePageTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_unavailable) ...[
                Text(
                  l10n.shareUnavailable,
                  key: const ValueKey('share-unavailable'),
                ),
                const SizedBox(height: 12),
                Text(l10n.shareUnavailableHelp),
              ] else if (_target == null || auth.isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(l10n.shareOpening),
              ] else ...[
                Text(l10n.shareLoginRequired),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => unawaited(
                    ref
                        .read(intentDispatcherProvider)
                        .dispatch(
                          context,
                          compositionId: CompositionIdScope.of(context),
                          componentId: 'share-login-action',
                          action: ActionDescriptor(
                            intent: 'open_page',
                            params: {'page': 'login'},
                          ),
                        ),
                  ),
                  child: Text(l10n.shareLoginAction),
                ),
              ],
              const SizedBox(height: 20),
              Text(l10n.shareDownloadHelp),
            ],
          ),
        ),
      ),
    );
  }
}
