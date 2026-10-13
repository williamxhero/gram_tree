import 'package:flutter/services.dart';

import 'system_share.dart';

SystemShare createPlatformSystemShare() => const _MobileSystemShare();

class _MobileSystemShare implements SystemShare {
  const _MobileSystemShare();

  static const _channel = MethodChannel('app.gramtree/share');

  @override
  Future<void> shareText(String text) =>
      _channel.invokeMethod<void>('shareText', text);
}
