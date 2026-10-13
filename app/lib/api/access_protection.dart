import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../auth/session.dart';
import '../l10n/app_localizations.dart';

class CaptchaChallenge {
  const CaptchaChallenge({
    required this.id,
    required this.prompt,
    required this.image,
  });
  final String id;
  final String prompt;
  final Uint8List image;
}

abstract interface class CaptchaAdapter {
  Future<String?> solve(CaptchaChallenge challenge);
}

class AccessNotice {
  const AccessNotice({
    this.retryAt,
    this.challenge,
    this.paginationLimited = false,
  });
  final DateTime? retryAt;
  final CaptchaChallenge? challenge;
  final bool paginationLimited;
}

class AccessProtection extends Notifier<AccessNotice>
    implements CaptchaAdapter {
  Completer<String?>? _answer;

  @override
  AccessNotice build() {
    final session = ref.watch(sessionStoreProvider);
    var epoch = session.identityEpoch;
    void identityChanged() {
      if (epoch == session.identityEpoch) return;
      epoch = session.identityEpoch;
      answer(null);
      state = const AccessNotice();
    }

    session.addListener(identityChanged);
    ref.onDispose(() {
      session.removeListener(identityChanged);
      _answer?.complete(null);
    });
    return const AccessNotice();
  }

  void paginationLimit(bool limited) {
    state = AccessNotice(
      retryAt: state.retryAt,
      challenge: state.challenge,
      paginationLimited: limited,
    );
  }

  void rateLimited(int seconds) {
    state = AccessNotice(
      retryAt: DateTime.now().add(Duration(seconds: seconds)),
      challenge: state.challenge,
      paginationLimited: state.paginationLimited,
    );
  }

  @override
  Future<String?> solve(CaptchaChallenge challenge) {
    if (_answer != null) {
      return state.challenge?.id == challenge.id
          ? _answer!.future
          : Future.value(null);
    }
    _answer = Completer<String?>();
    state = AccessNotice(
      retryAt: state.retryAt,
      challenge: challenge,
      paginationLimited: state.paginationLimited,
    );
    return _answer!.future;
  }

  void answer(String? value) {
    final pending = _answer;
    _answer = null;
    state = AccessNotice(
      retryAt: state.retryAt,
      paginationLimited: state.paginationLimited,
    );
    pending?.complete(value);
  }
}

final accessProtectionProvider =
    NotifierProvider<AccessProtection, AccessNotice>(AccessProtection.new);
final captchaAdapterProvider = Provider<CaptchaAdapter>(
  (ref) => ref.watch(accessProtectionProvider.notifier),
);

/// A single notice for every API caller, including background requests.
class AccessProtectionHost extends ConsumerStatefulWidget {
  const AccessProtectionHost({
    super.key,
    required this.child,
    required this.navigatorKey,
  });
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  ConsumerState<AccessProtectionHost> createState() =>
      _AccessProtectionHostState();
}

class _AccessProtectionHostState extends ConsumerState<AccessProtectionHost> {
  DialogRoute<String>? _captchaRoute;

  @override
  void initState() {
    super.initState();
    ref.listenManual(accessProtectionProvider, (previous, next) {
      final challenge = next.challenge;
      if (challenge == null) {
        final route = _captchaRoute;
        // An identity reset cancels the pending solve and closes only its own modal.
        if (route != null && route.isActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && route.isActive) route.navigator?.removeRoute(route);
          });
        }
        return;
      }
      if (previous?.challenge?.id == challenge.id) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final context = widget.navigatorKey.currentContext;
        if (!mounted) return;
        if (ref.read(accessProtectionProvider).challenge?.id != challenge.id) {
          return;
        }
        if (context == null) {
          ref.read(accessProtectionProvider.notifier).answer(null);
          return;
        }
        final route = DialogRoute<String>(
          context: context,
          builder: (_) => _CaptchaDialog(challenge: challenge),
        );
        _captchaRoute = route;
        final answer = await Navigator.of(context).push(route);
        if (identical(_captchaRoute, route)) _captchaRoute = null;
        if (mounted &&
            ref.read(accessProtectionProvider).challenge?.id == challenge.id) {
          ref.read(accessProtectionProvider.notifier).answer(answer);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final notice = ref.watch(accessProtectionProvider);
    final seconds =
        ((notice.retryAt?.difference(DateTime.now()).inMilliseconds ?? 0) /
                1000)
            .ceil();
    // The host lives above MaterialApp's Navigator, whose dialog context supplies
    // the same localized resources as routed pages.
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        if (notice.paginationLimited)
          Material(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.paginationLimitNotice,
                        key: const ValueKey('pagination-limit-notice'),
                      ),
                    ),
                    // This banner sits above Navigator's Overlay; a Tooltip
                    // cannot be presented here. Keep an accessible button label.
                    Semantics(
                      label: l10n.dismissNotice,
                      child: IconButton(
                        onPressed: () => ref
                            .read(accessProtectionProvider.notifier)
                            .paginationLimit(false),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (seconds > 0)
          TweenAnimationBuilder<int>(
            key: ValueKey(notice.retryAt),
            tween: IntTween(begin: seconds, end: 0),
            duration: Duration(seconds: seconds),
            builder: (context, remaining, _) => remaining == 0
                ? const SizedBox.shrink()
                : SafeArea(
                    bottom: false,
                    child: Material(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          l10n.accessRetryCountdown(remaining),
                          key: const ValueKey('access-retry-countdown'),
                          style: GramTreeColors.of(context).numberStyle(
                            Theme.of(context).textTheme.bodyMedium!,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

class _CaptchaDialog extends StatefulWidget {
  const _CaptchaDialog({required this.challenge});
  final CaptchaChallenge challenge;
  @override
  State<_CaptchaDialog> createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<_CaptchaDialog> {
  final _response = TextEditingController();
  @override
  void dispose() {
    _response.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.captchaTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.challenge.prompt),
          const SizedBox(height: 12),
          Image.memory(
            widget.challenge.image,
            key: const ValueKey('captcha-image'),
            excludeFromSemantics: true,
            width: 240,
            height: 96,
          ),
          TextField(
            key: const ValueKey('captcha-response'),
            controller: _response,
            decoration: InputDecoration(labelText: l10n.captchaResponse),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _response.text.trim()),
          child: Text(l10n.captchaContinue),
        ),
      ],
    );
  }
}
