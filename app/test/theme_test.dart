import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/app/theme.dart';

import 'helpers.dart';

void main() {
  testWidgets('浅色：纸色底、墨色主按钮、标题用衬线体', (tester) async {
    await pumpApp(tester);
    final context = tester.element(find.text('今天还没有安排'));
    final theme = Theme.of(context);
    expect(theme.scaffoldBackgroundColor, GramTreePalette.paper);
    expect(theme.colorScheme.primary, GramTreePalette.ink);
    expect(GramTreeColors.of(context).accent, GramTreePalette.accent);
    expect(GramTreeColors.of(context).verified, GramTreePalette.verified);
    expect(theme.textTheme.titleLarge?.fontFamily, titleFont);
    expect(theme.textTheme.bodyMedium?.fontFamily, bodyFont);

    final plus = tester.widget<Material>(
      find.byKey(const ValueKey('primary-create-button')),
    );
    expect(plus.color, GramTreePalette.ink);
  });

  testWidgets('深色：底色和文字对调，主按钮仍然醒目', (tester) async {
    await pumpApp(tester, brightness: Brightness.dark);
    final context = tester.element(find.text('今天还没有安排'));
    final theme = Theme.of(context);
    expect(theme.scaffoldBackgroundColor, GramTreePalette.paperDark);
    expect(theme.colorScheme.primary, GramTreePalette.inkDark);
    expect(theme.colorScheme.onPrimary, GramTreePalette.paperDark);
  });
}
