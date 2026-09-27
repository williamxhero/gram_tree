import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const receiptEntry = ValueKey('receipt-scan-entry');

void main() {
  testWidgets('能力开关关闭时，＋页面没有对应入口', (tester) async {
    await pumpApp(tester, features: {'receipt_scan': false});
    await tapTab(tester, 2);
    expect(find.byKey(receiptEntry), findsNothing);
    expect(find.text('拍小票记价格'), findsNothing);
  });

  testWidgets('能力开关打开时，＋页面出现入口，点了有反馈', (tester) async {
    await pumpApp(tester, features: {'receipt_scan': true});
    await tapTab(tester, 2);
    expect(find.text('拍小票记价格'), findsOneWidget);
    await tester.tap(find.byKey(receiptEntry));
    await tester.pumpAndSettle();
    expect(find.text('这个功能正在准备中'), findsOneWidget);
  });

  testWidgets('通过生成的客户端读取服务端下发的开关', (tester) async {
    final server = FakeServer()
      ..on(
        'GET',
        '/v1/client-config',
        (_) => (
          200,
          {
            'features': {
              'evolution_tree': false,
              'cooking_qa': false,
              'receipt_scan': true,
            },
            'params': <String, Object?>{},
          },
        ),
      );
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await tapTab(tester, 2);
    expect(find.byKey(receiptEntry), findsOneWidget);
  });

  testWidgets('拉不到服务端配置时，受开关控制的入口一律不出现', (tester) async {
    final server = FakeServer()
      ..on('GET', '/v1/client-config', (_) => (500, null));
    await pumpApp(tester, env: TestEnv.signedIn(server: server));
    await tapTab(tester, 2);
    expect(find.byKey(receiptEntry), findsNothing);
    expect(find.text('想做点什么？'), findsOneWidget);
  });
}
