import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_controller.dart';
import '../../recipes/recipe_sharing.dart';

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

  Future<void> _resolve() async {
    try {
      final path = await ref
          .read(recipeSharingProvider)
          .resolve(widget.shareId);
      if (mounted) setState(() => _target = path);
    } catch (_) {
      if (mounted) setState(() => _unavailable = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (_target != null && auth.value != null && !_opening) {
      _opening = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(_target!);
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('分享的菜谱')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_unavailable) ...[
                const Text('菜谱不存在或已下架', key: ValueKey('share-unavailable')),
                const SizedBox(height: 12),
                const Text('请确认分享链接，或稍后重新打开。'),
              ] else if (_target == null || auth.isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                const Text('正在打开分享的菜谱'),
              ] else ...[
                const Text('完整菜谱需要登录后查看'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('登录后查看完整菜谱'),
                ),
              ],
              const SizedBox(height: 20),
              const Text('未安装 App？可向分享人索取测试版；当前尚未公开发布下载。'),
            ],
          ),
        ),
      ),
    );
  }
}
