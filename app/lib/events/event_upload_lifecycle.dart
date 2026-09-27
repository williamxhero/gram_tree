import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'event_uploader.dart';

/// 挂在 App 根部：冷启动、回到前台时各触发一次事件上传尝试
/// （登录成功的触发在 auth/auth_controller.dart）。不渲染任何东西，只包一层。
class EventUploadTrigger extends ConsumerStatefulWidget {
  const EventUploadTrigger({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<EventUploadTrigger> createState() => _EventUploadTriggerState();
}

class _EventUploadTriggerState extends ConsumerState<EventUploadTrigger>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 冷启动（含上次没传完事件后被杀掉进程）也试一次。
    unawaited(ref.read(eventUploaderProvider).triggerUpload());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(eventUploaderProvider).triggerUpload());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
