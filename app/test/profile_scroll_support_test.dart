import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_scroll_support.dart';

void main() {
  testWidgets('reveal waits when profile refresh starts without a list', (
    tester,
  ) async {
    Timer? finish;
    addTearDown(() => finish?.cancel());
    var loading = true;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            finish ??= Timer(const Duration(milliseconds: 200), () {
              setState(() => loading = false);
            });
            return Scaffold(
              body: loading
                  ? const Text('Refreshing profile')
                  : ListView.builder(
                      key: const ValueKey('taste-profile-content'),
                      itemExtent: 100,
                      itemCount: 60,
                      itemBuilder: (_, index) => Text('Profile row $index'),
                    ),
            );
          },
        ),
      ),
    );
    final target = find.text('Profile row 50');
    await revealProfileOrDialogTarget(tester, target);
    expect(target.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reveal scrolls inside an open dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  scrollable: true,
                  content: Column(
                    children: List.generate(
                      30,
                      (index) => SizedBox(
                        height: 100,
                        child: Text('Dialog row $index'),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final target = find.text('Dialog row 29');
    await revealProfileOrDialogTarget(tester, target);
    expect(target.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final loadingGap in [false, true]) {
    testWidgets(
      'profile target survives list replacement with loading gap $loadingGap',
      (tester) async {
        var generation = 0;
        var loading = false;
        Timer? reload;
        Timer? finish;
        addTearDown(() {
          reload?.cancel();
          finish?.cancel();
        });
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                reload ??= Timer(const Duration(milliseconds: 250), () {
                  setState(() {
                    generation++;
                    loading = loadingGap;
                  });
                  if (loadingGap) {
                    finish = Timer(const Duration(milliseconds: 200), () {
                      setState(() => loading = false);
                    });
                  }
                });
                return Scaffold(
                  body: loading
                      ? const Text('Refreshing profile')
                      : KeyedSubtree(
                          key: ValueKey(generation),
                          child: ListView.builder(
                            key: const ValueKey('taste-profile-content'),
                            itemExtent: 100,
                            itemCount: 60,
                            itemBuilder: (_, index) => SizedBox(
                              height: 100,
                              child: Text('Profile row $index'),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        );
        final target = find.text('Profile row 50');
        await revealProfileTarget(tester, target);
        expect(generation, 1);
        expect(target, findsOneWidget);
        expect(target.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
