import 'system_share.dart';

SystemShare createPlatformSystemShare() => _UnavailableSystemShare();

class _UnavailableSystemShare implements SystemShare {
  @override
  Future<void> shareText(String text) async {
    throw UnsupportedError('System sharing is unavailable on this platform');
  }
}
