import 'package:flutter/services.dart';

import 'device_capabilities.dart';

/// iOS / Android implementation.
///
/// Vibration uses Flutter's built-in haptics. Timer reminders are scheduled by
/// the platform implementation so they survive backgrounding and screen lock.
DeviceCapabilities createDeviceCapabilities() => MobileDeviceCapabilities();

class MobileDeviceCapabilities implements DeviceCapabilities {
  static const _channel = MethodChannel('app.gramtree/device_capabilities');
  bool _keepScreenOn = false;

  bool get keepScreenOn => _keepScreenOn;

  @override
  bool get supportsLockScreenTimer => false;

  @override
  bool get supportsVibration => true;

  @override
  Future<void> setKeepScreenOn(bool enabled) async {
    _keepScreenOn = enabled;
    await _channel.invokeMethod<void>('setKeepScreenOn', enabled);
  }

  @override
  Future<void> scheduleTimerReminder({
    required String id,
    required DateTime dueAt,
    required String title,
    required String body,
  }) =>
      _channel.invokeMethod<void>('scheduleTimerReminder', {
        'id': id,
        'dueAtMillis': dueAt.toUtc().millisecondsSinceEpoch,
        'title': title,
        'body': body,
      });

  @override
  Future<void> cancelTimerReminder(String id) =>
      _channel.invokeMethod<void>('cancelTimerReminder', {'id': id});

  @override
  Future<void> vibrate() => HapticFeedback.mediumImpact();
}
