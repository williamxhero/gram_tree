import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';
import 'package:gram_tree/app/app.dart';
import 'package:gram_tree/features_flags/features.dart';
import 'package:gram_tree/platform/device_capabilities.dart';
import 'package:gram_tree/platform/fake_device_capabilities.dart';

/// 页面测试共用的启动和操作方法。

const tabLabels = ['今天', '发现', '新建', '记录', '我的'];

/// Title shown by each tab's empty state, in bottom-bar order.
const emptyTitles = ['今天还没有安排', '还没有可发现的内容', '想做点什么？', '还没有做菜记录', '个人中心'];

Future<void> pumpApp(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
  double textScale = 1.0,
  Size size = const Size(360, 780),
  Map<String, bool> features = const {},
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deviceCapabilitiesProvider.overrideWithValue(FakeDeviceCapabilities()),
        // 页面测试不启动服务端：用生成的接口模型构造服务端返回的配置
        clientConfigProvider.overrideWith(
          (ref) async => ClientConfig(features: features, params: const {}),
        ),
      ],
      child: const GramTreeApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Taps the bottom-bar entry at [index]. The center one is the ＋ button.
Future<void> tapTab(WidgetTester tester, int index) async {
  final finder = index == 2
      ? find.byKey(const ValueKey('primary-create-button'))
      : find.text(tabLabels[index]);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
