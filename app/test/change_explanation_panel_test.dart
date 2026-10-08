import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/features/recipes/change_explanation_panel.dart';
import 'package:gram_tree/l10n/app_localizations.dart';

import 'helpers.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('AI explanation renders the shared dashed marker $brightness', (
      tester,
    ) async {
      final form = ValueNotifier(_Form());
      addTearDown(form.dispose);
      await _pump(
        tester,
        form: form,
        brightness: brightness,
        explain: () async => const ChangeExplanationSuggestion(
          available: true,
          changeNote: '自动说明',
          tags: ['自动标签'],
          source: 'ai_estimated',
          changesFingerprint: 'ops',
        ),
      );
      await tester.tap(find.text('生成改动说明'));
      await tester.pump();
      await tester.pump();
      final border = tester.widget<CustomPaint>(
        find
            .ancestor(
              of: find.text('AI 估算'),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(border.painter, isNotNull, reason: 'AI 来源使用共享虚线边框，不替换为实线');
      expect(
        tester.widget<Text>(find.text('AI 估算')).style?.color,
        buildTheme(brightness).colorScheme.onSurfaceVariant,
      );
    });
  }

  testWidgets(
    'reconstructed AI ownership clears stale note but preserves author tags',
    (tester) async {
      final form = ValueNotifier(_Form());
      addTearDown(form.dispose);
      Future<ChangeExplanationSuggestion> explain() async =>
          const ChangeExplanationSuggestion(
            available: true,
            changeNote: '旧自动说明',
            tags: ['自动标签'],
            source: 'ai_estimated',
            changesFingerprint: 'old',
          );
      await _pump(tester, form: form, explain: explain);
      await tester.tap(find.text('生成改动说明'));
      await tester.pump();
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('change-explanation-tags')),
        '作者标签',
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, form: form, explain: explain);
      final old = form.value;
      form.value = _Form(
        binding: 'new-selection',
        note: old.note,
        tags: old.tags,
        fingerprint: old.fingerprint,
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('旧自动说明'), findsNothing);
      expect(find.text('作者标签'), findsOneWidget);
    },
  );

  testWidgets(
    'successful suggestion never labels preserved author fields as AI',
    (tester) async {
      final form = ValueNotifier(_Form(note: '作者说明', tags: ['作者标签']));
      addTearDown(form.dispose);
      await _pump(
        tester,
        form: form,
        explain: () async => const ChangeExplanationSuggestion(
          available: true,
          changeNote: '自动说明',
          tags: ['自动标签'],
          source: 'ai_estimated',
          changesFingerprint: 'ops',
        ),
      );
      await tester.tap(find.text('生成改动说明'));
      await tester.pump();
      await tester.pump();
      expect(find.text('作者说明'), findsOneWidget);
      expect(find.text('作者标签'), findsOneWidget);
      expect(find.text('AI 估算'), findsNothing);
    },
  );

  testWidgets(
    'late suggestion preserves author tags independently of untouched note',
    (tester) async {
      final form = ValueNotifier(_Form());
      addTearDown(form.dispose);
      final response = Completer<ChangeExplanationSuggestion>();
      await _pump(tester, form: form, explain: () => response.future);
      await tester.tap(find.text('生成改动说明'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextFormField, '标签（用逗号分隔）'),
        '作者标签',
      );
      response.complete(
        const ChangeExplanationSuggestion(
          available: true,
          changeNote: '降低盐量',
          tags: ['自动标签'],
          source: 'ai_estimated',
          changesFingerprint: 'final-ops-1',
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('降低盐量'), findsOneWidget);
      expect(find.text('作者标签'), findsOneWidget);
      expect(find.text('自动标签'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextFormField, '这次改了什么'),
        '作者说明',
      );
      await tester.tap(find.text('手动保存'));
      await tester.pump();
      expect(find.text('已保存：作者说明 / 作者标签 / final-ops-1'), findsOneWidget);
    },
  );

  for (final entry in {
    'daily_quota': '今日 AI 额度已用完',
    'monthly_budget': 'AI 预算暂不可用',
    'no_changes': '本次没有可说明的实际改动',
    'invalid_output': '说明生成失败',
  }.entries) {
    testWidgets(
      '${entry.key} preserves manual metadata and explains the fallback',
      (tester) async {
        final form = ValueNotifier(_Form(note: '手写说明', tags: ['手写标签']));
        addTearDown(form.dispose);
        await _pump(
          tester,
          form: form,
          explain: () async => ChangeExplanationSuggestion(
            available: false,
            reason: entry.key,
            error: entry.key,
            changesFingerprint: 'failed',
          ),
        );
        await tester.tap(find.text('生成改动说明'));
        await tester.pump();
        await tester.pump();
        expect(find.textContaining(entry.value), findsOneWidget);
        await tester.tap(find.text('手动保存'));
        await tester.pump();
        expect(find.text('已保存：手写说明 / 手写标签 / 手写'), findsOneWidget);
      },
    );
  }

  for (final brightness in Brightness.values) {
    for (final scale in [1.3, 1.6]) {
      testWidgets(
        'editable explanation works at $brightness and ${scale}x text on small screens',
        (tester) async {
          tester.view.physicalSize = const Size(1080, 2340);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          final form = ValueNotifier(_Form());
          addTearDown(form.dispose);
          await _pump(
            tester,
            form: form,
            brightness: brightness,
            textScale: scale,
            explain: () async => const ChangeExplanationSuggestion(
              available: true,
              changeNote: '减少盐量，保留原来的成熟判断和安全提示',
              tags: ['少盐'],
              source: 'ai_estimated',
              changesFingerprint: 'final-ops-1',
            ),
          );
          await tester.tap(find.text('生成改动说明'));
          await tester.pump();
          await tester.pump();
          await tester.enterText(
            find.widgetWithText(TextFormField, '这次改了什么'),
            '作者说明',
          );
          await tester.ensureVisible(find.text('手动保存'));
          await tester.tap(find.text('手动保存'));
          await tester.pump();
          expect(find.text('已保存：作者说明 / 少盐 / final-ops-1'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'lazy scrolling retains generated ownership for later binding invalidation',
    (tester) async {
      final form = ValueNotifier(_Form());
      addTearDown(form.dispose);
      final response = Completer<ChangeExplanationSuggestion>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: TestEnv.signedIn().overrides,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: ValueListenableBuilder<_Form>(
                valueListenable: form,
                builder: (context, value, _) => ListView(
                  children: [
                    ChangeExplanationPanel(
                      bindingKey: value.binding,
                      changeNote: value.note,
                      tags: value.tags,
                      explain: () => response.future,
                      onChanged: (draft) => form.value = _Form(
                        binding: form.value.binding,
                        note: draft.changeNote,
                        tags: draft.tags,
                        fingerprint: draft.changesFingerprint,
                      ),
                    ),
                    const SizedBox(height: 3000),
                    const Text('表单末尾'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('生成改动说明'));
      await tester.pump();
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('表单末尾'),
        700,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      response.complete(
        const ChangeExplanationSuggestion(
          available: true,
          changeNote: '滚动前自动说明',
          tags: ['少盐'],
          source: 'ai_estimated',
          changesFingerprint: 'final-ops-1',
        ),
      );
      await tester.pump();
      expect(form.value.note, '滚动前自动说明');
      final current = form.value;
      form.value = _Form(
        binding: 'recipe-a:base-a:revision-2',
        note: current.note,
        tags: current.tags,
        fingerprint: current.fingerprint,
      );
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('change-explanation-note')),
        -700,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump();
      expect(find.text('滚动前自动说明'), findsNothing);
      expect(find.textContaining('改动已变化'), findsOneWidget);
    },
  );
  testWidgets(
    'unusable generated result cannot be adopted as a valid explanation',
    (tester) async {
      final form = ValueNotifier(_Form());
      addTearDown(form.dispose);
      await _pump(
        tester,
        form: form,
        explain: () async => const ChangeExplanationSuggestion(
          available: true,
          changeNote: '声称已验证',
          tags: ['已验证'],
          source: 'verified',
        ),
      );
      await tester.tap(find.text('生成改动说明'));
      await tester.pump();
      await tester.pump();
      expect(find.text('声称已验证'), findsNothing);
      expect(find.textContaining('说明生成失败'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, '这次改了什么'),
        '手写改动',
      );
      await tester.tap(find.text('手动保存'));
      await tester.pump();
      expect(find.text('已保存：手写改动 /  / 手写'), findsOneWidget);
    },
  );
  testWidgets(
    'availability changes cancel pending suggestions without blocking save',
    (tester) async {
      final form = ValueNotifier(_Form());
      addTearDown(form.dispose);
      final response = Completer<ChangeExplanationSuggestion>();
      Future<ChangeExplanationSuggestion> explain() => response.future;
      await _pump(tester, form: form, explain: explain);
      await tester.tap(find.text('生成改动说明'));
      await tester.pump();
      await _pump(
        tester,
        form: form,
        explain: explain,
        unavailableReason: '模型暂不可用',
      );
      response.complete(
        const ChangeExplanationSuggestion(
          available: true,
          changeNote: '迟到说明',
          tags: ['迟到'],
          source: 'ai_estimated',
          changesFingerprint: 'obsolete',
        ),
      );
      await tester.pump();
      expect(find.text('迟到说明'), findsNothing);
      expect(find.text('正在生成说明…'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextFormField, '这次改了什么'),
        '作者手写',
      );
      await tester.tap(find.text('手动保存'));
      await tester.pump();
      expect(find.text('已保存：作者手写 /  / 手写'), findsOneWidget);
    },
  );
  testWidgets(
    'parent author updates during request appear and survive late suggestions',
    (tester) async {
      final form = ValueNotifier(_Form());
      addTearDown(form.dispose);
      final response = Completer<ChangeExplanationSuggestion>();
      await _pump(tester, form: form, explain: () => response.future);
      await tester.tap(find.text('生成改动说明'));
      await tester.pump();
      form.value = _Form(note: '父表单作者说明', tags: ['父表单标签']);
      await tester.pump();
      expect(find.text('父表单作者说明'), findsOneWidget);
      expect(find.text('父表单标签'), findsOneWidget);
      response.complete(
        const ChangeExplanationSuggestion(
          available: true,
          changeNote: '自动说明',
          tags: ['自动标签'],
          source: 'ai_estimated',
          changesFingerprint: 'final-ops-1',
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('手动保存'));
      await tester.pump();
      expect(find.text('已保存：父表单作者说明 / 父表单标签 / final-ops-1'), findsOneWidget);
      expect(find.text('自动说明'), findsNothing);
    },
  );
  testWidgets('request exceptions leave manual save usable and allow retry', (
    tester,
  ) async {
    final form = ValueNotifier(_Form(note: '网络失败也保留', tags: ['手写']));
    addTearDown(form.dispose);
    await _pump(
      tester,
      form: form,
      explain: () async => throw Exception('offline'),
    );
    await tester.tap(find.text('生成改动说明'));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('说明生成失败'), findsOneWidget);
    await tester.tap(find.text('手动保存'));
    await tester.pump();
    expect(find.text('已保存：网络失败也保留 / 手写 / 手写'), findsOneWidget);
    await tester.tap(find.text('生成改动说明'));
    await tester.pump();
    expect(find.textContaining('说明生成失败'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'model failure preserves author fields and saves without failure fingerprint',
    (tester) async {
      final form = ValueNotifier(_Form(note: '作者手写说明', tags: ['作者标签']));
      addTearDown(form.dispose);
      await _pump(
        tester,
        form: form,
        explain: () async => const ChangeExplanationSuggestion(
          available: false,
          reason: 'model_unavailable',
          error: 'model_unavailable',
          changesFingerprint: 'failed-result-fingerprint',
        ),
      );
      await tester.tap(find.text('生成改动说明'));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('模型暂不可用'), findsOneWidget);
      expect(find.textContaining('手动保存不受影响'), findsOneWidget);
      await tester.tap(find.text('手动保存'));
      await tester.pump();
      expect(find.text('已保存：作者手写说明 / 作者标签 / 手写'), findsOneWidget);
      expect(find.text('AI 估算'), findsNothing);
    },
  );
  testWidgets(
    'old request cannot replace a new binding or finish its pending request',
    (tester) async {
      final form = ValueNotifier(_Form());
      addTearDown(form.dispose);
      final oldResponse = Completer<ChangeExplanationSuggestion>();
      final newResponse = Completer<ChangeExplanationSuggestion>();
      var nextRequest = 0;
      await _pump(
        tester,
        form: form,
        explain: () =>
            nextRequest++ == 0 ? oldResponse.future : newResponse.future,
      );
      await tester.tap(find.text('生成改动说明'));
      await tester.pump();
      form.value = _Form(binding: 'recipe-a:base-a:revision-2');
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('生成改动说明'));
      await tester.pump();
      oldResponse.complete(
        const ChangeExplanationSuggestion(
          available: true,
          changeNote: '过期盐量说明',
          tags: ['过期'],
          source: 'ai_estimated',
          changesFingerprint: 'old-fingerprint',
        ),
      );
      await tester.pump();
      expect(find.text('过期盐量说明'), findsNothing);
      expect(find.text('正在生成说明…'), findsOneWidget);
      newResponse.complete(
        const ChangeExplanationSuggestion(
          available: true,
          changeNote: '换成空气炸锅',
          tags: ['空气炸锅'],
          source: 'ai_estimated',
          changesFingerprint: 'new-fingerprint',
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('手动保存'));
      await tester.pump();
      expect(find.text('已保存：换成空气炸锅 / 空气炸锅 / new-fingerprint'), findsOneWidget);
    },
  );
  testWidgets(
    'changed operations discard generated note and fingerprint but preserve edited tags',
    (tester) async {
      final form = ValueNotifier(_Form());
      addTearDown(form.dispose);
      await _pump(
        tester,
        form: form,
        explain: () async => const ChangeExplanationSuggestion(
          available: true,
          changeNote: '只减少盐量',
          tags: ['少盐'],
          source: 'ai_estimated',
          changesFingerprint: 'final-ops-1',
        ),
      );
      await tester.tap(find.text('生成改动说明'));
      await tester.pump();
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextFormField, '标签（用逗号分隔）'),
        '作者标签',
      );
      final previous = form.value;
      form.value = _Form(
        binding: 'recipe-a:base-a:revision-2',
        note: previous.note,
        tags: previous.tags,
        fingerprint: previous.fingerprint,
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('只减少盐量'), findsNothing);
      expect(find.text('作者标签'), findsOneWidget);
      expect(find.text('AI 估算'), findsNothing);
      expect(find.textContaining('改动已变化'), findsOneWidget);
      await tester.tap(find.text('手动保存'));
      await tester.pump();
      expect(find.text('已保存： / 作者标签 / 手写'), findsOneWidget);
    },
  );
  testWidgets(
    'late suggestion preserves author note but fills untouched tags',
    (tester) async {
      final form = ValueNotifier(_Form());
      addTearDown(form.dispose);
      final response = Completer<ChangeExplanationSuggestion>();
      await _pump(tester, form: form, explain: () => response.future);
      await tester.tap(find.text('生成改动说明'));
      await tester.pump();
      expect(find.text('正在生成说明…'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, '这次改了什么'),
        '作者写：只减少了盐',
      );
      response.complete(
        const ChangeExplanationSuggestion(
          available: true,
          changeNote: '自动说明',
          tags: ['少盐'],
          source: 'ai_estimated',
          changesFingerprint: 'final-ops-1',
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('作者写：只减少了盐'), findsOneWidget);
      expect(find.text('自动说明'), findsNothing);
      expect(find.text('少盐'), findsOneWidget);
      await tester.tap(find.text('手动保存'));
      await tester.pump();
      expect(find.text('已保存：作者写：只减少了盐 / 少盐 / final-ops-1'), findsOneWidget);
    },
  );
  testWidgets(
    'generated explanation is editable and uses the shared why panel',
    (tester) async {
      final form = ValueNotifier(_Form());
      addTearDown(form.dispose);
      await _pump(
        tester,
        form: form,
        explain: () async => const ChangeExplanationSuggestion(
          available: true,
          changeNote: '把盐从 3 克减至 2 克',
          tags: ['少盐'],
          source: 'ai_estimated',
          changesFingerprint: 'final-ops-1',
        ),
      );
      await tester.tap(find.text('生成改动说明'));
      await tester.pump();
      await tester.pump();
      expect(find.text('把盐从 3 克减至 2 克'), findsOneWidget);
      expect(find.text('少盐'), findsOneWidget);
      await tester.tap(find.text('AI 估算'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('仅依据本次最终改动生成，不代表已做过验证。作者可以修改说明和标签。'), findsOneWidget);
      expect(find.text('这次不用'), findsNothing);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, '这次改了什么'),
        '作者采用：减少盐量',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '标签（用逗号分隔）'),
        '少盐，晚餐',
      );
      await tester.tap(find.text('手动保存'));
      await tester.pump();
      expect(find.text('已保存：作者采用：减少盐量 / 少盐、晚餐 / final-ops-1'), findsOneWidget);
    },
  );
  testWidgets(
    'unavailable AI leaves author fields editable and manual save usable',
    (tester) async {
      final form = ValueNotifier(_Form(note: '作者原说明', tags: ['家常']));
      addTearDown(form.dispose);
      await _pump(tester, form: form, unavailableReason: '今日额度已用完');

      expect(find.textContaining('今日额度已用完'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, '这次改了什么'),
        '减少盐量',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '标签（用逗号分隔）'),
        '少盐，家常',
      );
      await tester.tap(find.text('手动保存'));
      await tester.pump();

      expect(find.text('已保存：减少盐量 / 少盐、家常 / 手写'), findsOneWidget);
    },
  );
}

class _Form {
  _Form({
    this.binding = 'recipe-a:base-a:revision-1',
    this.note = '',
    this.tags = const [],
    this.fingerprint,
    this.noteAuthored,
    this.tagsAuthored,
  });
  final bool? noteAuthored;
  final bool? tagsAuthored;
  final String binding;
  final String note;
  final List<String> tags;
  final String? fingerprint;
}

Future<void> _pump(
  WidgetTester tester, {
  required ValueNotifier<_Form> form,
  Future<ChangeExplanationSuggestion> Function()? explain,
  String? unavailableReason,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  final env = TestEnv.signedIn();
  await tester.pumpWidget(
    ProviderScope(
      overrides: env.overrides,
      child: MaterialApp(
        theme: buildTheme(brightness),
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: _SaveForm(
              form: form,
              explain: explain,
              unavailableReason: unavailableReason,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

class _SaveForm extends StatefulWidget {
  const _SaveForm({required this.form, this.explain, this.unavailableReason});
  final ValueNotifier<_Form> form;
  final Future<ChangeExplanationSuggestion> Function()? explain;
  final String? unavailableReason;

  @override
  State<_SaveForm> createState() => _SaveFormState();
}

class _SaveFormState extends State<_SaveForm> {
  String? saved;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: ValueListenableBuilder<_Form>(
      valueListenable: widget.form,
      builder: (context, form, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChangeExplanationPanel(
            bindingKey: form.binding,
            changeNote: form.note,
            tags: form.tags,
            noteAuthored: form.noteAuthored,
            tagsAuthored: form.tagsAuthored,
            changesFingerprint: form.fingerprint,
            explain: widget.explain,
            unavailableReason: widget.unavailableReason,
            onChanged: (draft) {
              widget.form.value = _Form(
                binding: widget.form.value.binding,
                note: draft.changeNote,
                tags: draft.tags,
                fingerprint: draft.changesFingerprint,
                noteAuthored: draft.noteAuthored,
                tagsAuthored: draft.tagsAuthored,
              );
            },
          ),
          FilledButton(
            onPressed: () => setState(() {
              final current = widget.form.value;
              saved =
                  '已保存：${current.note} / ${current.tags.join('、')} / ${current.fingerprint ?? '手写'}';
            }),
            child: const Text('手动保存'),
          ),
          if (saved != null) Text(saved!),
        ],
      ),
    ),
  );
}
