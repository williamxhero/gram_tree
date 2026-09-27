import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/app.dart';
import 'package:gram_tree/api/api_client.dart';
import 'package:gram_tree/platform/device_capabilities.dart';
import 'package:gram_tree/platform/fake_device_capabilities.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

const receiptEntry = ValueKey('receipt-scan-entry');

/// 模拟服务端：按 OpenAPI 描述里的路径和字段返回 JSON，经过生成的客户端解析。
class FakeServer extends Interceptor {
  FakeServer(this.body, {this.fail = false});

  final Map<String, Object?> body;
  final bool fail;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (fail) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      return;
    }
    expect(options.path, '/v1/client-config');
    handler.resolve(
      Response(requestOptions: options, statusCode: 200, data: body),
    );
  }
}

Future<void> pumpWithServer(WidgetTester tester, FakeServer server) async {
  final dio = Dio()..interceptors.add(server);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deviceCapabilitiesProvider.overrideWithValue(FakeDeviceCapabilities()),
        apiClientProvider.overrideWithValue(GramtreeApi(dio: dio)),
      ],
      child: const GramTreeApp(),
    ),
  );
  await tester.pumpAndSettle();
}

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
    await pumpWithServer(
      tester,
      FakeServer({
        'features': {
          'evolution_tree': false,
          'cooking_qa': false,
          'receipt_scan': true,
        },
        'params': <String, Object?>{},
      }),
    );
    await tapTab(tester, 2);
    expect(find.byKey(receiptEntry), findsOneWidget);
  });

  testWidgets('拉不到服务端配置时，受开关控制的入口一律不出现', (tester) async {
    await pumpWithServer(tester, FakeServer(const {}, fail: true));
    await tapTab(tester, 2);
    expect(find.byKey(receiptEntry), findsNothing);
    expect(find.text('想做点什么？'), findsOneWidget);
  });
}
