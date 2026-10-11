import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';
import 'package:gram_tree/auth/session.dart';
import 'package:gram_tree/l10n/app_localizations.dart';
import 'package:gram_tree/ui_protocol/source_mark.dart';
import 'package:gram_tree/ui_protocol/source_types.dart';

import 'helpers.dart';

void main() {
  testWidgets(
    'read-only snapshot why content enters the phone viewport after panel mount',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final env = TestEnv.signedIn(server: FakeServer(), offline: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: env.overrides,
          child: MaterialApp(
            theme: buildTheme(Brightness.light)
                .copyWith(platform: TargetPlatform.android),
            locale: const Locale.fromSubtags(
              languageCode: 'zh',
              scriptCode: 'Hans',
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: Center(
                child: SourceMark(
                  sourceType: sourceTypeScenarioAdjusted,
                  componentId: 'recipe-ingredient-snapshot',
                  value: '150 克',
                  originalValue: '100 g',
                  basisText: '比例换算',
                  required: false,
                  feedbackEnabled: false,
                  onAction: null,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await ProviderScope.containerOf(tester.element(find.byType(SourceMark)))
          .read(sessionStoreProvider)
          .load();

      await tester.tap(find.text('按场景调整'));
      final panel = find.byKey(const ValueKey('why-panel'));
      // Flush recording and mounting without advancing the entrance animation.
      for (var i = 0; i < 10 && panel.evaluate().isEmpty; i++) {
        await tester.pump();
      }
      expect(panel, findsOneWidget);
      final original = find.descendant(
        of: panel,
        matching: find.text('原来：100 g'),
      );
      final current = find.descendant(
        of: panel,
        matching: find.text('现在：150 克'),
      );
      final basis = find.descendant(of: panel, matching: find.text('比例换算'));
      for (final content in [original, current, basis]) {
        expect(content, findsOneWidget);
        expect(content.hitTestable(), findsNothing);
      }

      await tester.pumpAndSettle();
      for (final content in [original, current, basis]) {
        await Scrollable.ensureVisible(
          tester.element(content),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        expect(content.hitTestable(), findsOneWidget);
      }
      expect(
        find.descendant(of: panel, matching: find.byType(OutlinedButton)),
        findsNothing,
      );
      expect(find.text('这次不用'), findsNothing);
      expect(find.text('以后别这样'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
