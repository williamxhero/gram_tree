import 'dart:typed_data';

import 'system_share.dart';

SystemShare createPlatformSystemShare() => _UnavailableSystemShare();

class _UnavailableSystemShare implements SystemShare {
  @override
  Future<void> shareText(
    String text, {
    Uint8List? imageBytes,
    String? imageContentType,
  }) async {
    throw UnsupportedError('System sharing is unavailable on this platform');
  }
}
