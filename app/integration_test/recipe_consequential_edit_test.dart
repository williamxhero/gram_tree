import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'event_pipeline_support.dart' show resetLocalAppState;

const _request = '想做一道小朋友能吃的、不辣的宫保鸡丁';
const _original = '中火炒鸡腿肉并加入盐，用食品温度计检查鸡肉中心温度达到 74°C';
const _clarify = '把步骤说明写清楚，不改食材和用量';
const _manualWhy = '确认中心达到 74°C 后盛出，避免加热不足。';

/// Uses only visible controls and text; the sole HTTP read obtains the dev OTP.
class _Journey {
  _Journey(this.tester);
  final WidgetTester tester;
  String phase = 'login';

  Finder key(String value) => find.byKey(ValueKey(value));

  Finder instruction(int index, String text) => find.descendant(
    of: key('recipe-step-$index'),
    // Prerequisite summaries legitimately repeat other steps' instructions.
    // Assert the intended numbered title, not every Text on the detail page.
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data?.startsWith('${index + 1}. ') == true &&
          widget.data!.contains(text),
    ),
  );

  Future<void> waitFor(Finder finder) async {
    for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(finder, findsWidgets, reason: phase);
  }

  Future<void> reveal(String value) async {
    final finder = key(value);
    tester.testTextInput.hide();
    await tester.pump();
    // An already-mounted child may have been scrolled out by a prior action.
    // Reusing it directly avoids unloading an expanded lazy row while finding
    // one of its controls.
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      expect(finder.hitTestable(), findsOneWidget, reason: phase);
      return;
    }
    final detail = key('recipe-detail-content');
    final comparison = key('full-comparison-content');
    final body = comparison.evaluate().isNotEmpty
        ? comparison
        : detail.evaluate().isNotEmpty
        ? detail
        : key('recipe-editor-content');
    final scrollable = body.evaluate().isNotEmpty
        ? find
              .descendant(
                of: body,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Scrollable &&
                      widget.axisDirection == AxisDirection.down,
                ),
              )
              .first
        : find
              .byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              )
              .first;
    final position = tester.state<ScrollableState>(scrollable).position;
    // Use bounded position changes instead of native drags. This reliably
    // mounts lazy editor rows without entering a text field's gesture arena.
    position.jumpTo(position.minScrollExtent);
    await tester.pumpAndSettle();
    for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
      position.jumpTo(
        (position.pixels + 300).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsOneWidget, reason: phase);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    for (var i = 0; i < 8 && finder.hitTestable().evaluate().isEmpty; i++) {
      position.jumpTo(
        (position.pixels + 100).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      await tester.pumpAndSettle();
    }
    expect(finder.hitTestable(), findsOneWidget, reason: phase);
  }

  Future<void> tap(String value) async {
    await reveal(value);
    final finder = key(value);
    final widget = tester.widget(finder);
    // History rows contain separate comparison actions in their subtitle. The
    // row center can hit one of those instead of opening the requested version.
    final target = widget is ListTile && widget.title != null
        ? find.descendant(of: finder, matching: find.byWidget(widget.title!))
        : finder;
    await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
    await tester.pumpAndSettle();
    expect(target.hitTestable(), findsOneWidget, reason: phase);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> enter(String value, String text) async {
    await reveal(value);
    await tester.enterText(key(value), text);
    await tester.pump();
  }

  Future<void> enabled(String value) => waitFor(
    find.byWidgetPredicate(
      (widget) =>
          widget is ButtonStyleButton &&
          widget.key == ValueKey(value) &&
          widget.onPressed != null,
    ),
  );

  Future<void> checkedChoice(String control) async {
    await waitFor(
      find.byWidgetPredicate(
        (widget) =>
            widget is OutlinedButton &&
            widget.key == ValueKey(control) &&
            widget.onPressed != null &&
            find.text('选择或后值已改变，正在更新检查。旧检查不可用于确认。').evaluate().isEmpty,
      ),
    );
  }

  Future<void> choose(String decision, String id, {String? after}) async {
    final control = 'text-edit-$decision-$id';
    await tap(control);
    await checkedChoice(control);
    if (after != null) {
      await enter('text-edit-after-$id', after);
      await reveal(control);
      await checkedChoice(control);
    }
  }

  Future<void> login() async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    await resetLocalAppState();
    await app.main();
    await waitFor(key('consent-agree'));
    await tap('consent-agree');
    await waitFor(key('login-email'));
    final email =
        'consequential-e2e-${DateTime.now().microsecondsSinceEpoch}@example.com';
    await tester.enterText(key('login-email'), email);
    await tester.tap(find.text('发送验证码'));
    await waitFor(key('code-input'));
    final server = Dio(
      BaseOptions(baseUrl: AppConfig.fromEnvironment().apiBaseUrl),
    );
    final code = await server.get(
      '/v1/dev/latest-email-code',
      queryParameters: {'email': email},
    );
    await tester.enterText(key('code-input'), code.data['code'] as String);
    await waitFor(key('primary-create-button'));
  }

  Future<void> generate({String request = _request}) async {
    phase = 'generate';
    await tester.tap(key('primary-create-button'));
    await tester.pumpAndSettle();
    await tap('one-line-recipe-entry');
    await enter('one-line-input', request);
    await tap('one-line-search');
    await reveal('ai-design-new');
    await waitFor(key('ai-design-new'));
    await tap('ai-design-new');
    await tap('ai-skip-questions');
    await reveal('one-line-search');
    await enabled('one-line-search');
    await reveal('text-edit-input');
    await waitFor(find.text('今日修改剩余 50 次'));
  }

  Future<void> savedEditor({String request = _request}) async {
    await generate(request: request);
    await tap('ai-edit-draft');
    await tap('save-recipe-button');
    await waitFor(key('recipe-detail-content'));
    await tap('edit-recipe-button');
    await waitFor(key('recipe-editor-content'));
    await reveal('text-edit-input');
    await waitFor(key('text-edit-input'));
  }

  Future<void> propose(String text) async {
    phase = 'preview $text';
    await enter('text-edit-input', text);
    await tap('text-edit-preview');
    await enabled('text-edit-preview');
  }

  Future<void> confirm() async {
    phase = 'confirm-and-save';
    await reveal('text-edit-confirm');
    await enabled('text-edit-confirm');
    await tap('text-edit-confirm');
    await waitFor(key('recipe-detail-content'));
  }

  Future<void> backToShell() async {
    for (
      var i = 0;
      i < 6 && key('primary-create-button').evaluate().isEmpty;
      i++
    ) {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
    expect(key('primary-create-button'), findsOneWidget);
  }

  Future<void> record(Future<void> Function() action) async {
    final binding = IntegrationTestWidgetsFlutterBinding.instance;
    final previousHandler = FlutterError.onError;
    final flutterErrors = <Map<String, Object?>>[];
    FlutterError.onError = (details) {
      flutterErrors.add({
        'phase': phase,
        'exception': details.exceptionAsString(),
        'stack': details.stack?.toString(),
        'library': details.library,
        'context': details.context?.toDescription(),
      });
      previousHandler?.call(details);
    };
    try {
      await action();
      expect(tester.takeException(), isNull);
    } catch (error, stack) {
      final failure = <String, Object?>{
        'test': tester.testDescription,
        'phase': phase,
        'e2e_error': error.toString(),
        'e2e_stack': stack.toString(),
        'flutter_errors': flutterErrors,
        'page_text': tester
            .widgetList<Text>(find.byType(Text))
            .map((text) => text.data)
            .toList(),
      };
      final previousData = binding.reportData;
      binding.reportData = {
        ...?previousData,
        ...failure,
        'errors': [...?previousData?['errors'] as List?, failure],
      };
      rethrow;
    } finally {
      FlutterError.onError = previousHandler;
    }
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('换厨具展示全部联动与安全提醒，拒绝依赖后修正保存并重看旧新版', (tester) async {
    final journey = _Journey(tester);
    await journey.record(() async {
      await journey.login();
      await journey.savedEditor();
      await journey.propose('改成空气炸锅');
      for (final entry in {
        'appliance': '空气炸锅',
        'instructions': '单层摆放',
        'temperature': '180',
        'duration': '60',
        'heat': '无',
        'container': '耐热浅盘',
        'doneness': '表面变白',
      }.entries) {
        await journey.reveal('text-edit-operation-${entry.key}');
        expect(
          find.descendant(
            of: journey.key('text-edit-operation-${entry.key}'),
            matching: find.textContaining(RegExp('建议后值：.*${entry.value}')),
          ),
          findsOneWidget,
        );
      }
      await journey.choose('reject', 'appliance');
      for (final id in [
        'instructions',
        'temperature',
        'duration',
        'heat',
        'container',
        'doneness',
      ]) {
        await journey.reveal('text-edit-operation-$id');
        expect(
          find.descendant(
            of: journey.key('text-edit-operation-$id'),
            matching: find.text('本条处理：拒绝'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: journey.key('text-edit-operation-$id'),
            matching: find.textContaining('依赖被拒绝，已默认拒绝：'),
          ),
          findsOneWidget,
        );
      }
      await journey.reveal('text-edit-confirm');
      expect(
        tester.widget<FilledButton>(journey.key('text-edit-confirm')).onPressed,
        isNull,
        reason: '全部拒绝不能生成无变化的新版本',
      );
      await journey.propose('改成空气炸锅');
      for (final id in [
        'appliance',
        'instructions',
        'temperature',
        'duration',
        'heat',
        'container',
        'doneness',
      ]) {
        await journey.choose('accept', id);
      }
      journey.phase = 'unsafe-cookware-preview';
      await journey.reveal('recipe-safety-finding-poultry-cook-through');
      expect(
        find.descendant(
          of: journey.key('recipe-safety-finding-poultry-cook-through'),
          matching: find.textContaining('74'),
        ),
        findsWidgets,
        reason: '缩短时间后的熟透风险必须独立显示，不能被 AI 理由掩盖',
      );
      await journey.choose(
        'modify',
        'instructions',
        after: '空气炸锅180°C加热鸡肉10分钟，用食品温度计确认鸡肉中心温度达到74°C后盛出',
      );
      await journey.choose('modify', 'duration', after: '600');
      await journey.choose('modify', 'doneness', after: '用食品温度计确认鸡肉中心温度达到74°C');
      await journey.reveal('recipe-food-safety-card');
      expect(
        journey.key('recipe-safety-finding-poultry-cook-through'),
        findsNothing,
        reason: '作者纠正成熟条件后重新检查实际后值',
      );
      await journey.tap('change-explanation-generate');
      await journey.enabled('change-explanation-generate');
      await journey.reveal('change-explanation-note');
      expect(find.text('改用空气炸锅，调整温度、时长、容器和中心温度判断。'), findsOneWidget);
      await journey.enter('change-explanation-note', '换空气炸锅，中心温度达到74°C后盛出。');
      await journey.enter('change-explanation-tags', '空气炸锅，作者确认');
      await journey.confirm();
      await journey.tap('recipe-step-1');
      expect(journey.instruction(1, '空气炸锅180°C加热鸡肉10分钟'), findsOneWidget);
      expect(find.textContaining('厨具：空气炸锅'), findsWidgets);
      expect(find.textContaining('温度'), findsWidgets);
      expect(find.textContaining('600 秒'), findsWidgets);
      await journey.reveal('recipe-step-1');
      expect(find.textContaining('耐热浅盘'), findsWidgets);
      await journey.tap('recipe-history-button');
      await journey.waitFor(journey.key('recipe-version-2'));
      expect(find.textContaining('换空气炸锅，中心温度达到74°C后盛出。'), findsOneWidget);
      await journey.tap('recipe-version-1');
      await journey.waitFor(journey.key('recipe-detail-content'));
      await journey.reveal('recipe-step-1');
      expect(journey.instruction(1, _original), findsOneWidget);
      expect(find.textContaining('厨具：炒锅'), findsWidgets);
      expect(find.textContaining('厨具：空气炸锅'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await journey.tap('recipe-version-2');
      await journey.waitFor(journey.key('recipe-detail-content'));
      expect(find.text('作者确认'), findsOneWidget);
      await journey.tap('recipe-step-1');
      expect(journey.instruction(1, '空气炸锅180°C加热鸡肉10分钟'), findsOneWidget);
      expect(
        find.descendant(
          of: journey.key('recipe-step-1'),
          matching: find.textContaining('用食品温度计确认鸡肉中心温度达到74°C'),
        ),
        findsWidgets,
      );
      await journey.reveal('recipe-step-0');
      expect(
        journey.instruction(0, '鸡腿肉切丁'),
        findsOneWidget,
        reason: '无关准备步骤不得被换厨具重写',
      );
    });
  });

  testWidgets('手动表单依据真实改动生成说明，作者修改说明标签后保存重看', (tester) async {
    final journey = _Journey(tester);
    await journey.record(() async {
      await journey.login();
      await journey.savedEditor();
      await journey.enter('recipe-step-instruction-cut', '鸡腿肉切成大小一致的两厘米丁');
      await journey.tap('change-explanation-generate');
      await journey.enabled('change-explanation-generate');
      await journey.reveal('change-explanation-note');
      expect(find.text('写清鸡肉切丁大小。'), findsOneWidget);
      await journey.enter('change-explanation-note', '鸡肉切两厘米丁，其余配方保持不变。');
      await journey.enter('change-explanation-tags', '两厘米丁，手动修改');
      await journey.tap('save-recipe-button');
      await journey.waitFor(journey.key('recipe-detail-content'));
      expect(find.text('手动修改'), findsOneWidget);
      await journey.reveal('recipe-step-0');
      expect(journey.instruction(0, '鸡腿肉切成大小一致的两厘米丁'), findsOneWidget);
      await journey.reveal('recipe-step-1');
      expect(journey.instruction(1, _original), findsOneWidget);
      await journey.tap('recipe-history-button');
      await journey.waitFor(journey.key('recipe-version-2'));
      expect(find.textContaining('鸡肉切两厘米丁，其余配方保持不变。'), findsOneWidget);
      await journey.tap('recipe-version-1');
      await journey.waitFor(journey.key('recipe-detail-content'));
      await journey.reveal('recipe-step-0');
      expect(journey.instruction(0, '鸡腿肉切丁'), findsOneWidget);
      expect(find.textContaining('两厘米'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await journey.tap('recipe-version-2');
      await journey.waitFor(journey.key('recipe-detail-content'));
      expect(find.text('两厘米丁'), findsOneWidget);
      await journey.reveal('recipe-step-0');
      expect(journey.instruction(0, '鸡腿肉切成大小一致的两厘米丁'), findsOneWidget);
    });
  });

  testWidgets('说明模型失败保留作者手写内容，不阻断手动保存', (tester) async {
    final journey = _Journey(tester);
    await journey.record(() async {
      await journey.login();
      await journey.savedEditor();
      // No replay exists for this distinct synthetic manual change.
      await journey.enter('recipe-step-instruction-cut', '鸡腿肉切成大小一致的三厘米丁');
      await journey.enter('change-explanation-note', '把鸡肉切成三厘米丁。');
      await journey.enter('change-explanation-tags', '手写说明');
      await journey.tap('change-explanation-generate');
      await journey.enabled('change-explanation-generate');
      await journey.reveal('change-explanation-note');
      expect(find.text('把鸡肉切成三厘米丁。'), findsOneWidget);
      expect(find.textContaining('手动保存不受影响'), findsWidgets);
      expect(find.textContaining('模型暂不可用'), findsWidgets);
      await journey.tap('save-recipe-button');
      await journey.waitFor(journey.key('recipe-detail-content'));
      expect(find.text('手写说明'), findsOneWidget);
      await journey.reveal('recipe-step-0');
      expect(journey.instruction(0, '鸡腿肉切成大小一致的三厘米丁'), findsOneWidget);
      await journey.tap('recipe-history-button');
      await journey.waitFor(journey.key('recipe-version-2'));
      expect(find.textContaining('把鸡肉切成三厘米丁。'), findsOneWidget);
      await journey.tap('recipe-version-2');
      await journey.waitFor(journey.key('recipe-detail-content'));
      await journey.reveal('recipe-step-0');
      expect(journey.instruction(0, '鸡腿肉切成大小一致的三厘米丁'), findsOneWidget);
    });
  });

  testWidgets('想快一点只提有限操作，安全检查后修改时长再保存重看', (tester) async {
    final journey = _Journey(tester);
    await journey.record(() async {
      await journey.login();
      await journey.savedEditor();
      await journey.propose('想快一点');
      for (final id in [
        'quick-instruction',
        'quick-duration',
        'quick-doneness',
      ]) {
        await journey.reveal('text-edit-operation-$id');
        expect(journey.key('text-edit-operation-$id'), findsOneWidget);
        await journey.choose('accept', id);
      }
      await journey.reveal('recipe-safety-finding-poultry-cook-through');
      expect(
        journey.key('recipe-safety-finding-poultry-cook-through'),
        findsOneWidget,
      );
      await journey.choose(
        'modify',
        'quick-instruction',
        after: '中火炒鸡肉120秒，用食品温度计确认中心达到74°C后盛出。',
      );
      await journey.choose('modify', 'quick-duration', after: '120');
      await journey.choose(
        'modify',
        'quick-doneness',
        after: '用食品温度计确认中心达到74°C',
      );
      await journey.confirm();
      await journey.reveal('recipe-step-1');
      expect(journey.instruction(1, '中火炒鸡肉120秒'), findsOneWidget);
      expect(find.textContaining('120 秒'), findsWidgets);
      expect(find.textContaining('厨具：炒锅'), findsWidgets);
      await journey.reveal('recipe-duration');
      expect(
        find.descendant(
          of: journey.key('recipe-duration'),
          matching: find.text('总时长 5 分钟 · 动手 5 分钟'),
        ),
        findsOneWidget,
        reason: '总时间应由180秒准备加120秒烹饪派生，不能凭模型说明虚构',
      );
      await journey.tap('recipe-history-button');
      await journey.waitFor(journey.key('recipe-version-2'));
      await journey.tap('recipe-version-1');
      await journey.waitFor(journey.key('recipe-detail-content'));
      await journey.reveal('recipe-step-1');
      expect(journey.instruction(1, _original), findsOneWidget);
      expect(find.textContaining('300 秒'), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await journey.tap('recipe-version-2');
      await journey.waitFor(journey.key('recipe-detail-content'));
      await journey.reveal('recipe-step-0');
      expect(journey.instruction(0, '鸡腿肉切丁'), findsOneWidget);
      await journey.reveal('recipe-step-1');
      expect(journey.instruction(1, '中火炒鸡肉120秒'), findsOneWidget);
    });
  });

  testWidgets('简单一点逐条新增删除排序步骤，保存后旧版仍有腌肉步骤', (tester) async {
    final journey = _Journey(tester);
    await journey.record(() async {
      await journey.login();
      await journey.savedEditor(request: '合成测试：做一道先腌肉再炒的宫保鸡丁');
      await journey.propose('简单一点，不腌肉，改成直接炒，增加装盘步骤');
      for (final id in [
        'direct-cook',
        'direct-dependencies',
        'remove-marinate',
        'serve',
        'order',
        'easy',
      ]) {
        await journey.reveal('text-edit-operation-$id');
        expect(journey.key('text-edit-operation-$id'), findsOneWidget);
        await journey.choose('accept', id);
      }
      await journey.confirm();
      await journey.reveal('recipe-duration');
      expect(find.text('难度：简单'), findsOneWidget);
      await journey.reveal('recipe-step-0');
      expect(journey.instruction(0, '鸡肉直接入炒锅'), findsOneWidget);
      await journey.reveal('recipe-step-1');
      expect(journey.instruction(1, '将炒好的鸡肉装入干净餐盘'), findsOneWidget);
      expect(find.textContaining('鸡腿肉切丁后腌3分钟'), findsNothing);
      await journey.tap('recipe-history-button');
      await journey.waitFor(journey.key('recipe-version-2'));
      await journey.tap('recipe-version-1');
      await journey.waitFor(journey.key('recipe-detail-content'));
      await journey.reveal('recipe-step-0');
      expect(journey.instruction(0, '鸡腿肉切丁后腌3分钟'), findsOneWidget);
      expect(find.textContaining('将炒好的鸡肉装入干净餐盘'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await journey.tap('recipe-version-2');
      await journey.waitFor(journey.key('recipe-detail-content'));
      await journey.reveal('recipe-step-0');
      expect(journey.instruction(0, '1. 鸡肉直接入炒锅'), findsOneWidget);
      await journey.reveal('recipe-step-1');
      expect(journey.instruction(1, '2. 将炒好的鸡肉装入干净餐盘'), findsOneWidget);
    });
  });

  testWidgets('本人编辑器恢复逐条决定和后值，模型失败仍能确认保存', (tester) async {
    final journey = _Journey(tester);
    await journey.record(() async {
      await journey.login();
      await journey.savedEditor();
      await journey.propose(_clarify);
      await journey.choose('reject', 'clarify-cook');
      await journey.choose('modify', 'explain-cook', after: _manualWhy);
      journey.phase = 'reopen-owned-editor';
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await journey.waitFor(journey.key('recipe-detail-content'));
      await journey.tap('edit-recipe-button');
      await journey.reveal('text-edit-after-explain-cook');
      expect(find.text(_manualWhy), findsOneWidget);
      await journey.reveal('text-edit-operation-clarify-cook');
      expect(
        find.descendant(
          of: journey.key('text-edit-operation-clarify-cook'),
          matching: find.text('本条处理：拒绝'),
        ),
        findsOneWidget,
      );
      await journey.reveal('text-edit-operation-remind-cook');
      expect(find.text('依赖被拒绝，已默认拒绝：clarify-cook'), findsOneWidget);
      // An intentionally unrecorded synthetic request fails closed in replay.
      await journey.propose('合成测试请求：模型失败后保留已确认的步骤解释');
      await journey.waitFor(journey.key('text-edit-error'));
      expect(find.textContaining('模型暂不可用'), findsWidgets);
      await journey.reveal('text-edit-after-explain-cook');
      expect(find.text(_manualWhy), findsOneWidget);
      await journey.confirm();
      await journey.tap('recipe-step-1');
      expect(journey.instruction(1, _original), findsOneWidget);
      expect(find.textContaining(_manualWhy), findsOneWidget);
      await journey.tap('edit-recipe-button');
      await journey.reveal('text-edit-input');
      expect(
        journey.key('text-edit-operation-explain-cook'),
        findsNothing,
        reason: '成功保存清理旧基准的确认草稿',
      );
    });
  });

  testWidgets('生成结果重开恢复修改后值，失败后保存仍只有首个版本', (tester) async {
    final journey = _Journey(tester);
    await journey.record(() async {
      await journey.login();
      await journey.generate();
      await journey.propose(_clarify);
      await journey.choose('reject', 'clarify-cook');
      await journey.choose('modify', 'explain-cook', after: _manualWhy);
      await journey.backToShell();
      journey.phase = 'reopen-generated-result';
      await tester.tap(journey.key('primary-create-button'));
      await tester.pumpAndSettle();
      await journey.tap('one-line-recipe-entry');
      await journey.reveal('text-edit-after-explain-cook');
      expect(find.text(_manualWhy), findsOneWidget);
      await journey.reveal('text-edit-operation-remind-cook');
      expect(find.text('依赖被拒绝，已默认拒绝：clarify-cook'), findsOneWidget);
      await journey.propose('合成测试请求：生成结果模型失败后保留已确认的解释');
      await journey.waitFor(journey.key('text-edit-error'));
      expect(find.textContaining('模型暂不可用'), findsWidgets);
      await journey.confirm();
      await journey.tap('recipe-step-1');
      expect(find.textContaining(_manualWhy), findsOneWidget);
      await journey.tap('recipe-history-button');
      await journey.waitFor(journey.key('recipe-version-1'));
      expect(
        journey.key('recipe-version-2'),
        findsNothing,
        reason: '恢复及失败不能提前创建版本',
      );
      await journey.tap('recipe-version-1');
      await journey.waitFor(journey.key('recipe-detail-content'));
      await journey.tap('recipe-step-1');
      expect(journey.instruction(1, _original), findsOneWidget);
      expect(find.textContaining(_manualWhy), findsOneWidget);
    });
  });
}
