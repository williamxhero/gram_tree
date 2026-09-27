import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/create/create_page.dart';
import '../features/discover/discover_page.dart';
import '../features/me/me_page.dart';
import '../features/records/records_page.dart';
import '../features/tab_paths.dart';
import '../features/today/today_page.dart';
import 'bottom_nav.dart';

/// App router: one branch per fixed bottom entry, each keeping its own stack.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: TabPaths.today,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          _branch(TabPaths.today, const TodayPage()),
          _branch(TabPaths.discover, const DiscoverPage()),
          _branch(TabPaths.create, const CreatePage()),
          _branch(TabPaths.records, const RecordsPage()),
          _branch(TabPaths.me, const MePage()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _branch(String path, Widget page) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => page)],
);

/// Scaffold holding the active tab and the fixed bottom bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: AppBottomNav(
      currentIndex: shell.currentIndex,
      onSelected: (index) =>
          shell.goBranch(index, initialLocation: index == shell.currentIndex),
    ),
  );
}
