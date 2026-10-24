import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';

/// The web test target receives the same downloaded bytes without invoking a
/// phone-only sheet or putting a bearer token/signed URL into a browser link.
abstract class ExportFileShare {
  bool get isWebSubstitute;
  Future<void> share(Uint8List bytes, {required String filename});
  Future<void> cancelPendingShare();
}

class SystemExportFileShare implements ExportFileShare {
  static const _channel = MethodChannel('app.gramtree/export_file');

  @override
  bool get isWebSubstitute => false;

  @override
  Future<void> share(Uint8List bytes, {required String filename}) => _channel
      .invokeMethod<void>('shareZip', {'bytes': bytes, 'filename': filename});

  @override
  Future<void> cancelPendingShare() =>
      _channel.invokeMethod<void>('cancelShare');
}

class WebExportFileShare implements ExportFileShare {
  @override
  bool get isWebSubstitute => true;

  @override
  Future<void> share(Uint8List bytes, {required String filename}) async {
    if (bytes.isEmpty) throw StateError('Empty export');
    // Deliberately no persistent copy: the web build is a test target only.
  }

  @override
  Future<void> cancelPendingShare() async {}
}

final exportFileShareProvider = Provider<ExportFileShare>(
  (ref) => kIsWeb ? WebExportFileShare() : SystemExportFileShare(),
);

/// SessionStore notifies before privacy requests or slow credential persistence.
/// Send cancellation immediately, including while native ZIP preparation runs.
final exportShareSessionFenceProvider = Provider<void>((ref) {
  final session = ref.watch(sessionStoreProvider);
  final share = ref.watch(exportFileShareProvider);
  var epoch = session.identityEpoch;
  void fence() {
    final identity = session.identity;
    if (session.identityEpoch != epoch ||
        identity == null ||
        !session.canUpload(identity)) {
      epoch = session.identityEpoch;
      unawaited(share.cancelPendingShare().catchError((Object _) {}));
    }
  }

  session.addListener(fence);
  ref.onDispose(() => session.removeListener(fence));
});
