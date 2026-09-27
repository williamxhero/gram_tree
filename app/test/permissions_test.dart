import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gram_tree/platform/permissions.dart';
import 'package:gram_tree/storage/local_store.dart';
import 'package:gram_tree/widgets/permission_request.dart';

import 'helpers.dart';

/// 统一的权限申请方式（SPEC-013.2 票 7）。
///
/// 具体功能（拍照等）还没做，这里用一个只有“拍照”按钮的页面，按以后功能接入的方式调用。

class _CameraDemo extends ConsumerStatefulWidget {
  const _CameraDemo();

  @override
  ConsumerState<_CameraDemo> createState() => _CameraDemoState();
}

class _CameraDemoState extends ConsumerState<_CameraDemo> {
  PermissionState? _result;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextButton(
          onPressed: () async {
            final r = await requestPermission(
              context,
              ref,
              AppPermission.camera,
            );
            setState(() => _result = r);
          },
          child: const Text('拍照'),
        ),
        if (_result == PermissionState.granted) const Text('相机已打开'),
        if (_result != null && _result != PermissionState.granted)
          const PermissionDeniedNotice(permission: AppPermission.camera),
        const Text('其他功能照常'),
      ],
    ),
  );
}

Future<void> pumpDemo(
  WidgetTester tester,
  FakePermissions permissions, {
  bool consented = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(
          MemoryLocalStore(consented ? consentedStore() : {}),
        ),
        permissionServiceProvider.overrideWithValue(permissions),
      ],
      child: const MaterialApp(
        locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: _CameraDemo(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapCamera(WidgetTester tester) async {
  await tester.tap(find.text('拍照'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('先说明用途，点“继续”才调用系统申请', (tester) async {
    final permissions = FakePermissions();
    await pumpDemo(tester, permissions);
    await tapCamera(tester);
    expect(find.text('需要使用相机'), findsOneWidget);
    expect(find.text(AppPermission.camera.rationale), findsOneWidget);
    expect(permissions.requested, isEmpty);

    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();
    expect(permissions.requested, [AppPermission.camera]);
    expect(find.text('相机已打开'), findsOneWidget);
  });

  testWidgets('点“暂不”就不调用系统申请', (tester) async {
    final permissions = FakePermissions();
    await pumpDemo(tester, permissions);
    await tapCamera(tester);
    await tester.tap(find.text('暂不'));
    await tester.pumpAndSettle();
    expect(permissions.requested, isEmpty);
    expect(find.text('拍照不可用'), findsOneWidget);
  });

  testWidgets('拒绝后只在这个功能处提示，可以去系统设置，其他功能照常', (tester) async {
    final permissions = FakePermissions(answer: PermissionState.denied);
    await pumpDemo(tester, permissions);
    await tapCamera(tester);
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    expect(find.text('拍照不可用'), findsOneWidget);
    expect(find.text('你没有允许使用相机。其他功能不受影响。'), findsOneWidget);
    expect(find.text('其他功能照常'), findsOneWidget);
    await tester.tap(find.text('去系统设置打开'));
    await tester.pumpAndSettle();
    expect(permissions.settingsOpened, 1);
  });

  testWidgets('已被永久拒绝时不再弹说明和系统申请', (tester) async {
    final permissions = FakePermissions(
      initial: PermissionState.permanentlyDenied,
    );
    await pumpDemo(tester, permissions);
    await tapCamera(tester);
    expect(find.text('需要使用相机'), findsNothing);
    expect(permissions.requested, isEmpty);
    expect(find.text('拍照不可用'), findsOneWidget);
  });

  testWidgets('已经允许过就直接用', (tester) async {
    final permissions = FakePermissions(initial: PermissionState.granted);
    await pumpDemo(tester, permissions);
    await tapCamera(tester);
    expect(find.text('需要使用相机'), findsNothing);
    expect(find.text('相机已打开'), findsOneWidget);
  });

  testWidgets('同意隐私政策前不申请任何权限', (tester) async {
    final permissions = FakePermissions();
    await pumpDemo(tester, permissions, consented: false);
    await tapCamera(tester);
    expect(find.text('需要使用相机'), findsNothing);
    expect(permissions.requested, isEmpty);
  });
}
