import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'system_share_stub.dart'
    if (dart.library.io) 'system_share_mobile.dart'
    if (dart.library.js_interop) 'system_share_web.dart';

abstract interface class SystemShare {
  Future<void> shareText(String text);
}

final systemShareProvider = Provider<SystemShare>((ref) => createSystemShare());

SystemShare createSystemShare() => createPlatformSystemShare();
