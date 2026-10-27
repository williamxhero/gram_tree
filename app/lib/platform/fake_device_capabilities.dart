import 'device_capabilities.dart';

/// Stand-in used on web and in tests: reports no phone-only features and
/// records calls instead of touching hardware.
class FakeDeviceCapabilities implements DeviceCapabilities {
  bool keepScreenOn = false;
  int vibrateCount = 0;
  final scheduledMonthly = <({String id, DateTime dueAt, String timezone})>[];
  final cancelledMonthly = <String>[];

  @override
  bool get supportsLockScreenTimer => false;

  @override
  bool get supportsVibration => false;

  @override
  Future<void> setKeepScreenOn(bool enabled) async => keepScreenOn = enabled;

  @override
  Future<void> scheduleTimerReminder({
    required String id,
    required DateTime dueAt,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelTimerReminder(String id) async {}

  @override
  Future<void> scheduleMonthlyReviewReminder({
    required String id,
    required DateTime dueAt,
    required String timezone,
  }) async => scheduledMonthly.add((id: id, dueAt: dueAt, timezone: timezone));

  @override
  Future<void> cancelMonthlyReviewReminder(String id) async {
    cancelledMonthly.add(id);
  }

  @override
  Future<void> vibrate() async => vibrateCount++;
}
