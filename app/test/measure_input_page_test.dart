import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtree_api/gramtree_api.dart';

import 'helpers.dart';

const _measureId = '44444444-4444-4444-8444-444444444444';

Future<void> _open(WidgetTester tester, FakeServer server) async {
  await pumpApp(tester, env: TestEnv.signedIn(server: server));
  await tester.tap(find.byKey(const ValueKey('primary-create-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('create-recipe-entry')));
  await tester.pumpAndSettle();
  final button = find.byKey(
    const ValueKey('recipe-measure-input-ingredient-1'),
  );
  final body = find.byKey(const ValueKey('recipe-editor-content'));
  for (var i = 0; i < 12 && button.hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(body, const Offset(0, -300));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

FakeServer _server({String status = 'ready'}) {
  final server = FakeServer();
  server.on(
    'GET',
    '/v1/me/measures',
    (_) => (
      200,
      PagePersonalMeasureOut(
        items: [
          PersonalMeasureOut(
            id: _measureId,
            name: '白瓷勺',
            kind: PersonalMeasureOutKindEnum.spoon,
            capacityMl: 12,
            createdAt: '2026-10-08T00:00:00Z',
            updatedAt: '2026-10-08T00:00:00Z',
          ),
        ],
      ).toJson(),
    ),
  );
  server.on(
    'POST',
    '/v1/me/measures/input',
    (request) => (
      200,
      MeasureInputOut(
        original: '2 白瓷勺',
        baseQuantity: status == 'ready' ? 24 : null,
        baseUnit: MeasureInputOutBaseUnitEnum.ml,
        status: status == 'ready'
            ? MeasureInputOutStatusEnum.ready
            : MeasureInputOutStatusEnum.noDensity,
        basis: status == 'ready' ? '每次容量 12 毫升，输入 2 白瓷勺。' : '缺少密度，无法可靠换算成克。',
        measureInputToken: status == 'ready' ? 'confirmed-receipt' : null,
        quantitySource: status == 'ready'
            ? ValueSource(
                source_: ValueSourceSource_Enum.authorFilled,
                original: '2 白瓷勺',
                basis: '每次容量 12 毫升。',
              )
            : null,
      ).toJson(),
    ),
  );
  return server;
}

void main() {
  testWidgets('量具预览取消不改用量，确认后显示基础量和原始依据', (tester) async {
    final server = _server();
    await _open(tester, server);
    await tester.enterText(
      find.byKey(const ValueKey('measure-input-count')),
      '2',
    );
    await tester.tap(find.byKey(const ValueKey('measure-input-preview')));
    await tester.pumpAndSettle();
    expect(find.text('2 白瓷勺'), findsOneWidget);
    expect(find.text('24 ml'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('measure-input-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('2 白瓷勺'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('recipe-measure-input-ingredient-1')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('measure-input-count')),
      '2',
    );
    await tester.tap(find.byKey(const ValueKey('measure-input-preview')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('measure-input-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('2 白瓷勺'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '24.0'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'ml'), findsOneWidget);
    await tester.tap(find.text('量具输入依据'));
    await tester.pumpAndSettle();
    expect(find.text('每次容量 12 毫升。'), findsOneWidget);
  });

  testWidgets('缺密度和非法量具数不能确认，返回后保留当前用量', (tester) async {
    final server = _server(status: 'no_density');
    await _open(tester, server);
    await tester.enterText(
      find.byKey(const ValueKey('measure-input-count')),
      'NaN',
    );
    await tester.tap(find.byKey(const ValueKey('measure-input-preview')));
    await tester.pumpAndSettle();
    expect(find.text('请输入有限、非负且不超过 10000000 的数量。'), findsOneWidget);
    expect(server.calls('POST', '/v1/me/measures/input'), isEmpty);
    await tester.enterText(
      find.byKey(const ValueKey('measure-input-count')),
      '2',
    );
    await tester.tap(find.byKey(const ValueKey('measure-input-preview')));
    await tester.pumpAndSettle();
    expect(find.text('缺少密度，无法可靠换算成克。'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('measure-input-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('量具用量换算'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('measure-input-cancel')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '0.0'), findsWidgets);
  });

  testWidgets('估算需要额外知情确认，修改数量会使已预览结果失效', (tester) async {
    final server = _server();
    server.on('POST', '/v1/me/measures/input', (request) {
      final accepted = (request.body as Map)['accept_estimate'] == true;
      return (
        200,
        MeasureInputOut(
          original: '2 白瓷勺',
          baseQuantity: 18,
          baseUnit: MeasureInputOutBaseUnitEnum.g,
          status: accepted
              ? MeasureInputOutStatusEnum.ready
              : MeasureInputOutStatusEnum.estimateConfirmationRequired,
          basis: '密度 0.75 克/毫升，未经校对；食材库版本 1.0.0。',
          measureInputToken: accepted ? 'estimate-receipt' : null,
          quantitySource: accepted
              ? ValueSource(
                  source_: ValueSourceSource_Enum.aiEstimated,
                  original: '2 白瓷勺',
                  basis: '密度未经校对。',
                )
              : null,
        ).toJson(),
      );
    });
    await _open(tester, server);
    await tester.tap(find.byKey(const ValueKey('measure-input-unit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('克').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('measure-input-count')),
      '2',
    );
    await tester.tap(find.byKey(const ValueKey('measure-input-preview')));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const ValueKey('measure-input-confirm'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(find.textContaining('未经校对'), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey('measure-input-accept-estimate')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    await tester.enterText(
      find.byKey(const ValueKey('measure-input-count')),
      '3',
    );
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(find.text('18 g'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('measure-input-count')),
      '2',
    );
    await tester.tap(find.byKey(const ValueKey('measure-input-preview')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('measure-input-accept-estimate')),
    );
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '18.0'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'g'), findsOneWidget);
    expect(find.text('2 白瓷勺'), findsOneWidget);
  });

  testWidgets('没有个人量具的用户仍可返回使用基础单位', (tester) async {
    final server = _server();
    server.on(
      'GET',
      '/v1/me/measures',
      (_) => (200, PagePersonalMeasureOut(items: const []).toJson()),
    );
    await _open(tester, server);
    expect(find.textContaining('还没有登记量具'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('measure-input-cancel')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('recipe-ingredient-unit')),
      findsOneWidget,
    );
    expect(server.calls('POST', '/v1/me/measures/input'), isEmpty);
  });

  testWidgets('离线缺少转换数据明确提示并保留基础量编辑', (tester) async {
    final server = _server();
    server.on(
      'GET',
      '/v1/me/measures',
      (_) => FakeServer.error(503, 'network', '离线'),
    );
    await _open(tester, server);
    expect(find.text('离线或缺少转换数据，不能可靠换算；请返回填写基础量。草稿不会改变。'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('measure-input-cancel')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('recipe-ingredient-unit')),
      findsOneWidget,
    );
    expect(server.calls('POST', '/v1/me/measures/input'), isEmpty);
  });
}
