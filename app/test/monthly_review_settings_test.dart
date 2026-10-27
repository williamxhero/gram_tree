import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/features/records/monthly_review_notifications.dart';
import 'package:gram_tree/platform/device_capabilities.dart';
import 'package:gram_tree/platform/fake_device_capabilities.dart';
import 'package:gram_tree/platform/permissions.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

void main() {
  testWidgets('permission denial leaves the monthly reminder switch off', (
    tester,
  ) async {
    final env = TestEnv.signedIn();
    env.permissions.initial = PermissionState.denied;
    env.permissions.answer = PermissionState.denied;
    env
            .secure
            .values['notification_category:${env.server.user.id}:monthly_review'] =
        'false';
    await pumpApp(tester, env: env);
    await _openSettings(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    final capabilities =
        container.read(deviceCapabilitiesProvider) as FakeDeviceCapabilities;
    final controller = container.read(
      monthlyReviewNotificationControllerProvider,
    );
    final toggle = find.byKey(
      const ValueKey('monthly-review-notification-switch'),
    );
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('需要使用通知'), findsOneWidget);
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(await controller.enabled(env.server.user.id), isFalse);
    expect(capabilities.scheduledMonthly, isEmpty);
    expect(env.permissions.requested, [AppPermission.notifications]);

    // A second enable attempt neither lies about availability nor asks again.
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(env.permissions.requested, [AppPermission.notifications]);
    await goBack(tester);
    await _openSettings(tester);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
  });

  testWidgets('session load and timezone changes reconcile the reminder', (
    tester,
  ) async {
    final env = TestEnv.signedIn();
    env.permissions.initial = PermissionState.granted;
    await pumpApp(tester, env: env);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    final capabilities =
        container.read(deviceCapabilitiesProvider) as FakeDeviceCapabilities;
    final controller = container.read(
      monthlyReviewNotificationControllerProvider,
    );
    final session = container.read(sessionStoreProvider);
    final ownerId = env.server.user.id;

    // Controller is created before session load; the session listener schedules
    // once login restoration completes, without a second provider initialization.
    await controller.reconcile();
    expect(capabilities.scheduledMonthly, hasLength(1));
    expect(capabilities.scheduledMonthly.single.timezone, 'Asia/Shanghai');

    capabilities.scheduledMonthly.clear();
    capabilities.cancelledMonthly.clear();
    await session.updateUser(
      UserOut.fromJson({
        ...env.server.user.toJson(),
        'timezone': 'America/New_York',
      }),
    );
    await tester.pump();

    expect(capabilities.cancelledMonthly, [monthlyReviewReminderId(ownerId)]);
    expect(capabilities.scheduledMonthly, hasLength(1));
    expect(capabilities.scheduledMonthly.single.timezone, 'America/New_York');
    expect(
      capabilities.scheduledMonthly.single.dueAt.toUtc(),
      DateTime.utc(2026, 11, 1, 14),
    );
    await tester.pump(const Duration(seconds: 1));
  });
}

Future<void> _openSettings(WidgetTester tester) async {
  await tapTab(tester, 4);
  await tester.dragUntilVisible(
    find.text('设置'),
    find.byType(ListView),
    const Offset(0, -200),
  );
  await tapVisible(tester, find.text('设置'));
}
