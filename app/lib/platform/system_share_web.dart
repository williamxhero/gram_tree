import 'package:flutter/services.dart';

import 'system_share.dart';

SystemShare createPlatformSystemShare() => const _WebSystemShare();

class _WebSystemShare implements SystemShare {
  const _WebSystemShare();

  @override
  Future<void> shareText(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } on PlatformException {
      rethrow;
    }
  }
}
