import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/ui_protocol/component_registry.dart';
import 'package:gramtree_api/gramtree_api.dart';

/// SPEC-009.1 #80：通用组件库和设计系统定稿。只看外部表现（页面显示、读屏
/// 标注、深色/大字号下不溢出），不测内部实现细节。
void main() {
  ComponentReason reason() => ComponentReason(code: 'default', text: '默认组合');

  ComponentDescriptor descriptor({
    required String type,
    required ComponentDescriptorDetailEnum detail,
    required Map<String, dynamic> data,
    List<ActionDescriptor> actions = const [],
  }) => ComponentDescriptor(
    type: type,
    id: 'c1',
    detail: detail,
    data: data,
    actions: actions,
    reason: reason(),
  );

  /// 渲染一个组件登记项，跟 [CompositionView] 实际用法一样：不撑满剩余空间的
  /// 组件放进可滚动的列表；撑满剩余空间的组件放进有界高度的 Expanded。
  Future<List<ActionDescriptor>> pumpSpec(
    WidgetTester tester, {
    required ComponentSpec spec,
    required ComponentDescriptor component,
    Brightness brightness = Brightness.light,
    double textScale = 1.0,
    Size size = const Size(360, 780),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    final triggered = <ActionDescriptor>[];
    final child = Builder(
      builder: (context) =>
          spec.builder(context, component, spec.emptyState, triggered.add),
    );
    // 跟 CompositionView 的真实用法一样：撑满剩余空间的组件（empty_state）放进
    // 有界高度的区域；其它组件放进可滚动的列表（在真实页面里，没有撑满剩余空间的
    // 组件时，整页本来就是可滚动的，见 composition_view.dart 的 _CompositionBody）。
    final body = spec.fillsRemainingSpace
        ? child
        : SingleChildScrollView(child: child);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: Scaffold(body: body),
      ),
    );
    await tester.pumpAndSettle();
    return triggered;
  }

  final registry = defaultComponentRegistry;
  final generalTypes = ['hint_bar', 'section_title', 'text_block', 'list'];

  group('三档详略：简略只显示结论和一个主要动作', () {
    for (final type in generalTypes) {
      testWidgets('$type 简略档', (tester) async {
        final data = switch (type) {
          'list' => {
            'conclusion': '共 2 项',
            'items': [
              {'label': '生抽', 'value': '10 ml'},
              {'label': '冰糖', 'value': '15 g'},
            ],
            'basis': {'text': '按菜谱原文换算'},
            'action_label': '主要动作',
            'detail_label': '明细动作',
          },
          _ => {
            'conclusion': '先添加一道你常做的菜',
            'basis': {'text': '默认组合的提示'},
            'action_label': '主要动作',
            'detail_label': '明细动作',
          },
        };
        await pumpSpec(
          tester,
          spec: registry[type]!,
          component: descriptor(
            type: type,
            detail: ComponentDescriptorDetailEnum.brief,
            data: data,
            actions: [
              ActionDescriptor(intent: 'open_page', params: {'page': 'a'}),
              ActionDescriptor(intent: 'open_page', params: {'page': 'b'}),
            ],
          ),
        );

        // 依据文字和明细入口在简略档都不出现。
        expect(find.text('默认组合的提示'), findsNothing);
        expect(find.text('按菜谱原文换算'), findsNothing);
        expect(find.text('明细动作'), findsNothing);
        // list 的行本身在简略档也收起来，只留结论。
        if (type == 'list') {
          expect(find.text('生抽'), findsNothing);
        }
        // hint_bar 整条就是主要动作（不单独画按钮），其余三个组件画一个按钮。
        expect(
          find.text('主要动作'),
          type == 'hint_bar' ? findsNothing : findsOneWidget,
        );
      });
    }
  });

  group('三档详略：标准加依据占位，详细把依据摊开、加明细入口', () {
    testWidgets('hint_bar：标准档显示依据占位（一行，不展开），详细档摊开并显示明细入口', (tester) async {
      final component = descriptor(
        type: 'hint_bar',
        detail: ComponentDescriptorDetailEnum.standard,
        data: {
          'conclusion': '先添加一道你常做的菜',
          'basis': {'text': '这是默认组合，还没有你的做菜记录可以参考'},
        },
        actions: [
          ActionDescriptor(intent: 'open_page', params: {'page': 'create'}),
          ActionDescriptor(intent: 'open_page', params: {'page': 'history'}),
        ],
      );
      await pumpSpec(tester, spec: registry['hint_bar']!, component: component);
      expect(find.text('这是默认组合，还没有你的做菜记录可以参考'), findsOneWidget);
      // 标准档还没有明细入口。
      expect(find.text('去看看'), findsNothing);

      final detailed = descriptor(
        type: 'hint_bar',
        detail: ComponentDescriptorDetailEnum.detailed,
        data: component.data as Map<String, dynamic>,
        actions: component.actions!,
      );
      final triggered = await pumpSpec(
        tester,
        spec: registry['hint_bar']!,
        component: detailed,
      );
      expect(find.text('这是默认组合，还没有你的做菜记录可以参考'), findsOneWidget);
      expect(find.text('去看看'), findsOneWidget);
      await tester.tap(find.text('去看看'));
      expect(triggered, hasLength(1));
      expect(triggered.single.params, {'page': 'history'});
    });

    testWidgets('list：标准档显示各行，详细档每行加附注、显示依据和明细入口', (tester) async {
      final data = {
        'conclusion': '共 2 项',
        'items': [
          {'label': '生抽', 'value': '10 ml', 'note': '作者原文用量'},
          {'label': '冰糖', 'value': '15 g'},
        ],
        'basis': {'text': '这是这道菜的完整用料表'},
      };
      final actions = [
        ActionDescriptor(intent: 'start_cooking'),
        ActionDescriptor(intent: 'open_page', params: {'page': 'history'}),
      ];

      await pumpSpec(
        tester,
        spec: registry['list']!,
        component: descriptor(
          type: 'list',
          detail: ComponentDescriptorDetailEnum.standard,
          data: data,
          actions: actions,
        ),
      );
      expect(find.text('生抽'), findsOneWidget);
      expect(find.text('10 ml'), findsOneWidget);
      expect(find.text('作者原文用量'), findsNothing);
      // 标准档的依据是占位：文字还在（一行、省略号收尾），但只是一个简单展示，
      // 不是详细档里摊开的完整段落——用有没有那个占位图标来区分两档。
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('去看看'), findsNothing);

      final triggered = await pumpSpec(
        tester,
        spec: registry['list']!,
        component: descriptor(
          type: 'list',
          detail: ComponentDescriptorDetailEnum.detailed,
          data: data,
          actions: actions,
        ),
      );
      expect(find.text('生抽'), findsOneWidget);
      expect(find.text('作者原文用量'), findsOneWidget);
      expect(find.text('这是这道菜的完整用料表'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(find.text('去看看'), findsOneWidget);
      await tester.tap(find.text('去看看'));
      expect(triggered, hasLength(1));
      expect(triggered.single.intent, 'open_page');
    });
  });

  group('没有内容时显示登记的标准空态', () {
    testWidgets('hint_bar 结论缺失时显示登记的空态文案', (tester) async {
      await pumpSpec(
        tester,
        spec: registry['hint_bar']!,
        component: descriptor(
          type: 'hint_bar',
          detail: ComponentDescriptorDetailEnum.brief,
          data: const {},
        ),
      );
      expect(find.text('没有可显示的提示'), findsOneWidget);
    });

    testWidgets('list 一项都没有时显示登记的空态文案', (tester) async {
      await pumpSpec(
        tester,
        spec: registry['list']!,
        component: descriptor(
          type: 'list',
          detail: ComponentDescriptorDetailEnum.standard,
          data: const {'conclusion': '共 0 项', 'items': <Object?>[]},
        ),
      );
      expect(find.text('还没有记录'), findsOneWidget);
      expect(find.text('这里会显示内容'), findsOneWidget);
      expect(find.text('共 0 项'), findsNothing);
    });

    testWidgets('empty_state 结论缺失时显示登记的空态文案', (tester) async {
      await pumpSpec(
        tester,
        spec: registry['empty_state']!,
        component: descriptor(
          type: 'empty_state',
          detail: ComponentDescriptorDetailEnum.standard,
          data: const {},
        ),
      );
      expect(find.text('没有内容'), findsOneWidget);
    });
  });

  group('读屏标注', () {
    testWidgets('hint_bar 读出结论和动作文案', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpSpec(
        tester,
        spec: registry['hint_bar']!,
        component: descriptor(
          type: 'hint_bar',
          detail: ComponentDescriptorDetailEnum.brief,
          data: const {'conclusion': '先添加一道你常做的菜'},
          actions: [ActionDescriptor(intent: 'open_page', params: {})],
        ),
      );
      expect(find.bySemanticsLabel('先添加一道你常做的菜，去看看'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('list 每一行都读出名称和数值', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpSpec(
        tester,
        spec: registry['list']!,
        component: descriptor(
          type: 'list',
          detail: ComponentDescriptorDetailEnum.standard,
          data: const {
            'conclusion': '共 1 项',
            'items': [
              {'label': '生抽', 'value': '10 ml'},
            ],
          },
        ),
      );
      expect(find.bySemanticsLabel('生抽，10 ml'), findsOneWidget);
      semantics.dispose();
    });

    for (final type in ['section_title', 'text_block']) {
      testWidgets('$type 读出结论文字', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpSpec(
          tester,
          spec: registry[type]!,
          component: descriptor(
            type: type,
            detail: ComponentDescriptorDetailEnum.brief,
            data: const {'conclusion': '这周做过'},
          ),
        );
        expect(find.bySemanticsLabel('这周做过'), findsOneWidget);
        semantics.dispose();
      });
    }

    testWidgets('empty_state 读出结论和主按钮文案', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpSpec(
        tester,
        spec: registry['empty_state']!,
        component: descriptor(
          type: 'empty_state',
          detail: ComponentDescriptorDetailEnum.brief,
          data: const {'conclusion': '今天还没有安排'},
          actions: [
            ActionDescriptor(intent: 'open_page', params: {'page': 'create'}),
          ],
        ),
      );
      expect(find.bySemanticsLabel('今天还没有安排'), findsOneWidget);
      expect(find.bySemanticsLabel('去看看'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('深色模式和最大字号下不溢出', () {
    for (final brightness in Brightness.values) {
      for (final textScale in [2.0, 3.0]) {
        testWidgets('list 详细档，${brightness.name}，字号 $textScale', (
          tester,
        ) async {
          await pumpSpec(
            tester,
            spec: registry['list']!,
            component: descriptor(
              type: 'list',
              detail: ComponentDescriptorDetailEnum.detailed,
              data: const {
                'conclusion': '共 2 项，按你的口味换算过用量',
                'items': [
                  {
                    'label': '生抽（按你的口味换算过）',
                    'value': '8.5 ml',
                    'note': '原文 10 ml，按最近 3 次偏咸的记录调低了一档',
                  },
                  {'label': '冰糖', 'value': '15 g'},
                ],
                'basis': {'text': '你最近 3 次做红烧类都记了偏咸，口味档案已经按这个调整过用量'},
              },
              actions: [
                ActionDescriptor(intent: 'start_cooking'),
                ActionDescriptor(intent: 'open_page', params: {'page': 'x'}),
              ],
            ),
            brightness: brightness,
            textScale: textScale,
            size: const Size(320, 780),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('empty_state 详细档，${brightness.name}，字号 $textScale', (
          tester,
        ) async {
          await pumpSpec(
            tester,
            spec: registry['empty_state']!,
            component: descriptor(
              type: 'empty_state',
              detail: ComponentDescriptorDetailEnum.detailed,
              data: const {
                'conclusion': '今天还没有安排',
                'basis': {'text': '这里会显示今天要做的菜'},
                'action_label': '添加第一道菜谱',
              },
              actions: [
                ActionDescriptor(intent: 'open_page', params: {'page': 'a'}),
                ActionDescriptor(intent: 'open_page', params: {'page': 'b'}),
              ],
            ),
            brightness: brightness,
            textScale: textScale,
            size: const Size(320, 780),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  test(
    '组件里没有写死的颜色值',
    () {
      // 新增/重构的组件文件全部通过 Theme.of(context)/GramTreeColors.of(context)
      // 取色，不直接写 Color(0x...) 字面量（GramTreePalette 里的定义本身除外）。
      // dart:io 在网页端不可用，这条检查只在 VM（flutter test）下跑，
      // `flutter test --platform chrome` 跳过（见 CLAUDE.md 第 3 节测试分层）。
      final files = [
        'lib/ui_protocol/components/component_scaffold.dart',
        'lib/ui_protocol/components/hint_bar_component.dart',
        'lib/ui_protocol/components/section_title_component.dart',
        'lib/ui_protocol/components/text_block_component.dart',
        'lib/ui_protocol/components/list_component.dart',
        'lib/ui_protocol/components/empty_state_component.dart',
      ];
      for (final path in files) {
        final content = File(path).readAsStringSync();
        expect(
          content.contains('Color(0x'),
          isFalse,
          reason: '$path 不应该写死颜色值',
        );
      }
    },
    skip: kIsWeb ? 'dart:io 在网页端不可用' : false,
  );

  test('登记一个测试用组件：只给类型名、渲染方式、空态、读屏标注就能被渲染', () {
    final testSpec = ComponentSpec(
      type: 'test_widget',
      emptyState: const ComponentEmptyState(title: '没有测试数据'),
      builder: (context, component, emptyState, onAction) {
        final data = component.data as Map<String, dynamic>;
        final text = data['text'] as String?;
        if (text == null) {
          return Text(emptyState.title);
        }
        return Semantics(label: text, child: Text(text));
      },
    );
    final testRegistry = ComponentRegistry([testSpec]);
    expect(testRegistry.isRegistered('test_widget'), isTrue);
    expect(testRegistry.supportedTypes, {'test_widget'});
    expect(testRegistry['test_widget'], same(testSpec));
  });

  testWidgets('登记的测试用组件能被实际渲染出来', (tester) async {
    final testSpec = ComponentSpec(
      type: 'test_widget',
      emptyState: const ComponentEmptyState(title: '没有测试数据'),
      builder: (context, component, emptyState, onAction) {
        final data = component.data as Map<String, dynamic>;
        final text = data['text'] as String?;
        return Text(text ?? emptyState.title);
      },
    );
    await pumpSpec(
      tester,
      spec: testSpec,
      component: descriptor(
        type: 'test_widget',
        detail: ComponentDescriptorDetailEnum.brief,
        data: const {'text': '这是测试组件'},
      ),
    );
    expect(find.text('这是测试组件'), findsOneWidget);
  });
}
