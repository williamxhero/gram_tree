import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../auth/session.dart';
import '../../platform/device_capabilities.dart';
import '../../platform/permissions.dart';
import '../../storage/secure_store.dart';

const monthlyReviewNotificationCategory = 'monthly_review';
const _reminderHour = 9;

String monthlyReviewReminderId(String ownerId) => 'monthly_review:$ownerId';

DateTime nextMonthlyReviewReminderAt(DateTime now, String timezone) {
  tzdata.initializeTimeZones();
  final location = tz.getLocation(timezone);
  final localNow = tz.TZDateTime.from(now, location);
  return tz.TZDateTime(
    location,
    localNow.year,
    localNow.month + 1,
    1,
    _reminderHour,
  );
}

class MonthlyReviewNotificationController {
  MonthlyReviewNotificationController(this._ref) {
    _session = _ref.read(sessionStoreProvider);
    _session.addListener(_onSessionChanged);
    unawaited(_reconcile());
  }

  final Ref _ref;
  late final SessionStore _session;
  String? _scheduledOwner;
  bool _disposed = false;

  String _enabledKey(String ownerId) =>
      'notification_category:$ownerId:$monthlyReviewNotificationCategory';

  Future<bool> enabled(String ownerId) async =>
      (await _ref.read(secureStoreProvider).read(_enabledKey(ownerId))) !=
      'false';

  Future<void> setEnabled(String ownerId, bool value) async {
    await _ref
        .read(secureStoreProvider)
        .write(_enabledKey(ownerId), value ? 'true' : 'false');
    await _reconcile();
  }

  Future<bool> permissionRequested(String ownerId) async =>
      (await _ref
          .read(secureStoreProvider)
          .read('notification_permission_requested:$ownerId')) ==
      'true';

  Future<void> markPermissionRequested(String ownerId) => _ref
      .read(secureStoreProvider)
      .write('notification_permission_requested:$ownerId', 'true');

  Future<void> reconcile() => _reconcile();

  Future<void> cancelOwner(String ownerId) async {
    await _ref
        .read(deviceCapabilitiesProvider)
        .cancelMonthlyReviewReminder(monthlyReviewReminderId(ownerId));
    if (_scheduledOwner == ownerId) _scheduledOwner = null;
  }

  void _onSessionChanged() => unawaited(_reconcile());

  Future<void> _reconcile() async {
    if (_disposed) return;
    final store = _ref.read(secureStoreProvider);
    final capabilities = _ref.read(deviceCapabilitiesProvider);
    final ownerId = _session.current?.user.id;
    final oldOwner = _scheduledOwner;
    if (oldOwner != null && oldOwner != ownerId) {
      await capabilities.cancelMonthlyReviewReminder(
        monthlyReviewReminderId(oldOwner),
      );
      _scheduledOwner = null;
    }
    if (ownerId == null || !_session.isLoaded) {
      if (oldOwner != null && ownerId == null) {
        await capabilities.cancelMonthlyReviewReminder(
          monthlyReviewReminderId(oldOwner),
        );
        _scheduledOwner = null;
      }
      return;
    }
    if (await store.read(_enabledKey(ownerId)) == 'false') {
      await capabilities.cancelMonthlyReviewReminder(
        monthlyReviewReminderId(ownerId),
      );
      _scheduledOwner = null;
      return;
    }
    if (await _ref
            .read(permissionServiceProvider)
            .status(AppPermission.notifications) !=
        PermissionState.granted) {
      return;
    }
    final id = monthlyReviewReminderId(ownerId);
    final dueAt = nextMonthlyReviewReminderAt(
      DateTime.now(),
      _session.current!.user.timezone,
    );
    await capabilities.scheduleMonthlyReviewReminder(
      id: id,
      dueAt: dueAt,
      timezone: _session.current!.user.timezone,
    );
    _scheduledOwner = ownerId;
  }

  Future<void> dispose() async {
    _disposed = true;
    _session.removeListener(_onSessionChanged);
    final ownerId = _scheduledOwner;
    if (ownerId != null) {
      await _ref
          .read(deviceCapabilitiesProvider)
          .cancelMonthlyReviewReminder(monthlyReviewReminderId(ownerId));
    }
  }
}

final monthlyReviewNotificationControllerProvider =
    Provider<MonthlyReviewNotificationController>((ref) {
      final controller = MonthlyReviewNotificationController(ref);
      ref.onDispose(() => unawaited(controller.dispose()));
      return controller;
    });
