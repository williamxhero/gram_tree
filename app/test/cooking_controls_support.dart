import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lazy_list_controls_support.dart';

Future<void> revealCookingControl(WidgetTester tester, Finder target) async {
  await revealLazyListControl(
    tester,
    target,
    scrollable: find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first,
  );
}
