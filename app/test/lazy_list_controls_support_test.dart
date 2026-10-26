import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lazy_list_controls_support.dart';

const _listKey = ValueKey('recipe-controls');
const _delayedListKey = ValueKey('delayed-recipe-controls');
const _saveKey = ValueKey('save-recipe');
const _delayedSaveKey = ValueKey('delayed-save-recipe');

void main() {
  testWidgets('reveals and taps a lazy control after delayed layout growth', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: _RecipeControls()));
    final target = find.byKey(_saveKey);
    final scrollable = find.descendant(
      of: find.byKey(_listKey),
      matching: find.byType(Scrollable),
    );

    // The lazy child exists in the cache, but the next timed layout pushes it
    // out. Waiting for it and then pumping before ensureVisible is not safe.
    expect(target, findsOneWidget);
    expect(target.hitTestable(), findsNothing);

    await revealLazyListControl(tester, target, scrollable: scrollable);

    expect(target.last.hitTestable(), findsOneWidget);
    await tester.tap(target.last.hitTestable());
    await tester.pump();
    expect(find.text('Recipe saved').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('waits for a route scrollable before dragging', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: _DelayedRecipeControls()));
    final target = find.byKey(_delayedSaveKey);
    final scrollable = find.descendant(
      of: find.byKey(_delayedListKey),
      matching: find.byType(Scrollable),
    );

    expect(scrollable, findsNothing);
    await revealLazyListControl(tester, target, scrollable: scrollable.first);

    expect(target.last.hitTestable(), findsOneWidget);
    await tester.tap(target.last.hitTestable());
    await tester.pump();
    expect(find.text('Delayed recipe saved').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _RecipeControls extends StatefulWidget {
  const _RecipeControls();

  @override
  State<_RecipeControls> createState() => _RecipeControlsState();
}

class _RecipeControlsState extends State<_RecipeControls> {
  late final Timer _load;
  bool _expanded = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load = Timer(const Duration(milliseconds: 100), () {
      setState(() => _expanded = true);
    });
  }

  @override
  void dispose() {
    _load.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text(_saved ? 'Recipe saved' : 'Recipe details'),
        Expanded(
          child: ListView.builder(
            key: _listKey,
            // ignore: deprecated_member_use
            cacheExtent: 250,
            itemCount: 24,
            itemBuilder: (context, index) {
              if (index == 0) {
                return SizedBox(
                  height: _expanded ? 2200 : 430,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      _expanded
                          ? 'Public notes loaded'
                          : 'Loading public notes',
                    ),
                  ),
                );
              }
              if (index == 1) {
                return SizedBox(
                  height: 80,
                  child: Center(
                    child: ElevatedButton(
                      key: _saveKey,
                      onPressed: () => setState(() => _saved = true),
                      child: const Text('Save recipe'),
                    ),
                  ),
                );
              }
              return SizedBox(height: 200, child: Text('Recipe detail $index'));
            },
          ),
        ),
      ],
    ),
  );
}

class _DelayedRecipeControls extends StatefulWidget {
  const _DelayedRecipeControls();

  @override
  State<_DelayedRecipeControls> createState() => _DelayedRecipeControlsState();
}

class _DelayedRecipeControlsState extends State<_DelayedRecipeControls> {
  late final Timer _load;
  bool _ready = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load = Timer(const Duration(milliseconds: 100), () {
      setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _load.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _ready
        ? Column(
            children: [
              Text(_saved ? 'Delayed recipe saved' : 'Delayed recipe'),
              Expanded(
                child: ListView.builder(
                  key: _delayedListKey,
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    if (index == 4) {
                      return SizedBox(
                        height: 80,
                        child: Center(
                          child: ElevatedButton(
                            key: _delayedSaveKey,
                            onPressed: () => setState(() => _saved = true),
                            child: const Text('Save delayed recipe'),
                          ),
                        ),
                      );
                    }
                    return const SizedBox(height: 200);
                  },
                ),
              ),
            ],
          )
        : Text(_saved ? 'Delayed recipe saved' : 'Loading delayed recipe'),
  );
}
