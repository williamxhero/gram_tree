import 'package:flutter/services.dart';

import 'device_capabilities.dart';

/// iOS / Android implementation.
///
/// Vibration uses Flutter's built-in haptics. Keeping the screen on and the
/// lock-screen timer need native code (added with the cooking-mode SPEC); until
/// then [setKeepScreenOn] only tracks the requested state.
DeviceCapabilities createDeviceCapabilities() => MobileDeviceCapabilities();

class MobileDeviceCapabilities implements DeviceCapabilities {
  bool _keepScreenOn = false;

  bool get keepScreenOn => _keepScreenOn;

  @override
  bool get supportsLockScreenTimer => false;

  @override
  bool get supportsVibration => true;

  @override
  Future<void> setKeepScreenOn(bool enabled) async => _keepScreenOn = enabled;

  @override
  Future<void> vibrate() => HapticFeedback.mediumImpact();
}
