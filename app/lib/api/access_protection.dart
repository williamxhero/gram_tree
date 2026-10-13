import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';

abstract interface class CaptchaAdapter {
  Future<String?> solve(String challengeId);
}

class AccessNotice {
  const AccessNotice({
    this.retryAt,
    this.challengeId,
    this.paginationLimited = false,
  });
  final DateTime? retryAt;
  final String? challengeId;
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
      challengeId: state.challengeId,
      paginationLimited: limited,
    );
  }

  void rateLimited(int seconds) {
    state = AccessNotice(
      retryAt: DateTime.now().add(Duration(seconds: seconds)),
      challengeId: state.challengeId,
    );
  }

  @override
  Future<String?> solve(String challengeId) {
    if (_answer != null) {
      return state.challengeId == challengeId
          ? _answer!.future
          : Future.value(null);
    }
    _answer = Completer<String?>();
    state = AccessNotice(retryAt: state.retryAt, challengeId: challengeId);
    return _answer!.future;
  }

  void answer(String? value) {
    final pending = _answer;
    _answer = null;
    state = AccessNotice(retryAt: state.retryAt);
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
  @override
  void initState() {
    super.initState();
    ref.listenManual(accessProtectionProvider, (previous, next) {
      if (next.challengeId == null ||
          previous?.challengeId == next.challengeId) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final context = widget.navigatorKey.currentContext;
        if (context == null || !mounted) {
          ref.read(accessProtectionProvider.notifier).answer(null);
          return;
        }
        final answer = await showDialog<String>(
          context: context,
          builder: (_) => const _CaptchaDialog(),
        );
        if (mounted) ref.read(accessProtectionProvider.notifier).answer(answer);
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
                    const Expanded(
                      child: Text(
                        '已到翻页上限，请换搜索条件',
                        key: ValueKey('pagination-limit-notice'),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭提示',
                      onPressed: () => ref
                          .read(accessProtectionProvider.notifier)
                          .paginationLimit(false),
                      icon: const Icon(Icons.close),
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
                          '操作太频繁，请稍后再试 · $remaining 秒后可重试',
                          key: const ValueKey('access-retry-countdown'),
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
  const _CaptchaDialog();
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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('安全验证'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('请完成验证码后继续。验证码服务由平台配置。'),
        TextField(
          controller: _response,
          decoration: const InputDecoration(labelText: '验证结果'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _response.text.trim()),
        child: const Text('验证并继续'),
      ),
    ],
  );
}
