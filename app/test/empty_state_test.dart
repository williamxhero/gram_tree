import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/widgets/empty_state.dart';

void main() {
  testWidgets(
    'empty state fits inside a scrolling list without infinite height',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [
                EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: '还没有做菜记录',
                  message: '每次做完菜后的记录和心得会保存在这里。',
                ),
                Text('月度回顾'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('还没有做菜记录').hitTestable(), findsOneWidget);
      expect(find.text('月度回顾').hitTestable(), findsOneWidget);
    },
  );
}
