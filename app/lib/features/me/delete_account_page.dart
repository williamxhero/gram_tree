import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gramtree_api/gramtree_api.dart';

import '../../api/api_client.dart';
import '../../auth/auth_controller.dart';
import '../../auth/logout_confirmation.dart';
import '../../auth/session.dart';
import '../../events/event_uploader.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/apple_sign_in.dart';
import '../../recipes/recipe_snapshot_provider.dart';
import '../../recipes/personal_measure_repository.dart';
import '../../recipes/recipe_draft.dart';
import '../../storage/local_store.dart';
import '../../widgets/page_frame.dart';
import '../auth/code_page.dart';
import 'account_data.dart';

/// 服务端配置项的默认值，只用于说明文字；实际期限以服务端为准。
const _reauthWindowMinutes = 10;
const _deletionBusinessDays = 15;

/// App 内注销账号：重新验证身份 → 看清删什么 → 确认。
class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  bool _verified = false;
  bool _checked = false;
  bool _busy = false;
  bool _uncertain = false;
  EmailCodeSent? _sent;
  String? _error;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionStoreProvider);
    final identity = session.identity;
    _uncertain = identity != null && !session.canUpload(identity);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = ApiFailure.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode(String email) => _run(() async {
    final sent = await ref
        .read(authProvider.notifier)
        .sendEmailCode(email, purpose: EmailCodeRequestPurposeEnum.reauth);
    setState(() => _sent = sent);
  });

  Future<void> _verifyEmail(String email, String code) async {
    await ref
        .read(apiClientProvider)
        .getAuthApi()
        .reauthEmail(
          emailReauthRequest: EmailReauthRequest(email: email, code: code),
        );
    setState(() => _verified = true);
  }

  Future<void> _verifyApple() => _run(() async {
    final AppleCredential c;
    try {
      c = await ref.read(appleSignInProvider).signIn();
    } on AppleSignInCancelled {
      return;
    }
    await ref
        .read(apiClientProvider)
        .getAuthApi()
        .reauthApple(
          appleReauthRequest: AppleReauthRequest(
            identityToken: c.identityToken,
          ),
        );
    setState(() => _verified = true);
  });

  Future<void> _delete() => _run(() async {
    final messenger = ScaffoldMessenger.of(context);
    final done = AppLocalizations.of(context).deleteDone;
    final session = ref.read(sessionStoreProvider);
    final identity = session.identity;
    if (identity == null) return;
    final pausing = session.pauseAccountUploads(identity);
    final auth = ref.read(authProvider.notifier);
    final snapshots = ref.read(recipeSnapshotStoreProvider);
    final measures = ref.read(personalMeasureRepositoryProvider);
    final drafts = RecipeDraftStore(ref.read(localStoreProvider));
    final uploader = ref.read(eventUploaderProvider);
    await pausing;
    if (!session.matches(identity)) return;
    final wasUncertain = _uncertain;
    try {
      await ref
          .read(apiClientProvider)
          .getAccountApi()
          .requestDeletion(
            extra: {
              'auth_owner_id': identity.ownerId,
              'auth_identity_epoch': identity.epoch,
            },
          );
    } catch (error) {
      final status = error is DioException ? error.response?.statusCode : null;
      final rejected =
          !wasUncertain &&
          status != null &&
          status >= 400 &&
          status < 500 &&
          status != 408 &&
          ApiFailure.from(error).code != 'account_unavailable';
      if (rejected && await session.resumeAccountUploads(identity)) {
        unawaited(uploader.networkRestored());
      }
      if (mounted && session.matches(identity)) {
        // A missing response may follow a committed deletion. Never resume
        // private uploads merely because the confirmation could not be read.
        if (!rejected) _uncertain = true;
        // Reauthentication remains actionable even when an earlier deletion
        // outcome is unknown; verifying again must not release its upload fence.
        if (rejected || ApiFailure.from(error).code == 'reauth_required') {
          _verified = false;
          _checked = false;
          _sent = null;
        }
      }
      rethrow;
    }
    // Once accepted, even a local cleanup failure must never authorize uploads.
    if (mounted && session.matches(identity)) _uncertain = true;
    // Capture before auth reset; clear invalidates any late owner cache writes.
    // Kept at the page boundary to avoid auth -> snapshot -> auth dependency.
    await snapshots?.clear();
    await measures.clearAccount();
    await drafts.clearAccount(identity.ownerId);
    final showResult = session.matches(identity);
    await auth.clearLocalSession(deleteAccountData: true, identity: identity);
    if (showResult && messenger.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(done)));
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageFrame(
      title: l10n.deleteAccount,
      content: [
        _Steps(done: _verified ? 3 : 1),
        if (!_verified) ..._verifyStep(l10n) else ..._confirmStep(l10n),
        if (_error != null) ErrorText(_error!),
        if (_uncertain) BodyText(l10n.deletionUncertainBody),
      ],
      actions: [
        if (_verified)
          FilledButton(
            key: const ValueKey('delete-confirm'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              // 不可撤回的操作用错误色；酱红只留给“系统替你改了”
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: _checked && !_busy ? _delete : null,
            child: Text(_uncertain ? l10n.deletionRetry : l10n.deleteAccount),
          ),
        if (_uncertain)
          SecondaryButton(
            label: l10n.deletionExit,
            onPressed: _busy ? null : () => confirmLogout(context, ref),
          ),
      ],
    );
  }

  List<Widget> _verifyStep(AppLocalizations l10n) {
    final list = ref.watch(identitiesProvider);
    final ids = list.value;
    if (ids == null) {
      if (!list.hasError) {
        return const [Center(child: CircularProgressIndicator())];
      }
      return [
        ErrorText(ApiFailure.from(list.error!).message),
        SecondaryButton(
          label: l10n.retry,
          onPressed: () => ref.invalidate(identitiesProvider),
        ),
      ];
    }
    final email = ids
        .where((i) => i.kind == IdentityOutKindEnum.email)
        .map((i) => i.email)
        .whereType<String>()
        .firstOrNull;
    final hasApple = ids.any((i) => i.kind == IdentityOutKindEnum.apple);
    final canApple = ref.watch(appleSignInProvider).isAvailable;
    final sent = _sent;
    return [
      PageTitle(l10n.deleteStepVerify),
      if (email != null && sent != null)
        CodeEntry(
          email: email,
          resendAfter: sent.resendAfterSeconds,
          expiresIn: sent.expiresInSeconds,
          purpose: EmailCodeRequestPurposeEnum.reauth,
          onSubmit: (code) => _verifyEmail(email, code),
        )
      else if (email != null) ...[
        BodyText(l10n.deleteVerifyEmail(email)),
        BodyText(l10n.deleteVerifyWindow(_reauthWindowMinutes), muted: true),
        PrimaryButton(
          label: l10n.sendCode,
          busy: _busy,
          onPressed: () => _sendCode(email),
        ),
      ],
      if (hasApple && canApple && sent == null)
        SecondaryButton(
          label: l10n.deleteVerifyApple,
          onPressed: _busy ? null : _verifyApple,
        ),
    ];
  }

  List<Widget> _confirmStep(AppLocalizations l10n) => [
    PageTitle(l10n.deleteWhatTitle),
    InfoCard(lines: [l10n.deleteWhat1, l10n.deleteWhat2, l10n.deleteWhat3]),
    BodyText(l10n.deleteWhatTail(_deletionBusinessDays)),
    CheckboxListTile(
      key: const ValueKey('delete-check'),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: _checked,
      onChanged: (v) => setState(() => _checked = v ?? false),
      title: Text(l10n.deleteCheck),
    ),
  ];
}

/// 三步进度条。
class _Steps extends StatelessWidget {
  const _Steps({required this.done});

  final int done;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: i < done ? colors.primary : colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
