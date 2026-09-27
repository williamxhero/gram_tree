import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_capabilities_stub.dart'
    if (dart.library.io) 'device_capabilities_mobile.dart'
    if (dart.library.js_interop) 'device_capabilities_web.dart';

/// Phone-only capabilities live behind this interface so the same code base
/// compiles to web (used for cloud testing), where a fake is used instead.
abstract class DeviceCapabilities {
  /// Whether a cooking timer can keep running and show on the lock screen.
  bool get supportsLockScreenTimer;

  /// Whether the device can vibrate.
  bool get supportsVibration;

  /// Keeps the screen on (e.g. while cooking) or releases the lock.
  Future<void> setKeepScreenOn(bool enabled);

  /// Short haptic / vibration feedback.
  Future<void> vibrate();
}

/// The implementation for the current platform.
final deviceCapabilitiesProvider = Provider<DeviceCapabilities>(
  (ref) => createDeviceCapabilities(),
);
