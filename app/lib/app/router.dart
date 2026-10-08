import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gramtree_api/gramtree_api.dart' show GenerationResult;

import '../auth/auth_controller.dart';
import '../features/auth/code_page.dart';
import '../features/auth/login_page.dart';
import '../features/create/create_page.dart';
import '../features/create/one_line_recipe_page.dart';
import '../features/discover/discover_page.dart';
import '../features/me/delete_account_page.dart';
import '../features/me/document_page.dart';
import '../features/me/identities_page.dart';
import '../features/me/me_page.dart';
import '../features/me/settings_page.dart';
import '../features/me/taste_profile_page.dart';
import '../features/me/withdraw_page.dart';
import '../features/onboarding/consent_page.dart';
import '../features/recipes/personal_measures_page.dart';
import '../features/recipes/recipe_pages.dart';
import '../features/records/records_page.dart';
import '../features/tab_paths.dart';
import '../features/today/today_page.dart';
import '../privacy/consent.dart';
import 'bottom_nav.dart';

const consentPath = '/consent';
const loadingPath = '/loading';

/// 不登录也能看的页面。
bool _isPublic(String location) =>
    location == consentPath ||
    location == goodbyePath ||
    location.startsWith(loginPath);

/// 路由守卫：没同意隐私政策 → 同意页；没登录 → 登录页；都满足才进主界面。
String? guard({
  required bool consented,
  required AsyncValue<Object?> auth,
  required String location,
}) {
  if (!consented) {
    return location == consentPath || location == goodbyePath
        ? null
        : consentPath;
  }
  if (auth.isLoading && !auth.hasValue) {
    return location == loadingPath ? null : loadingPath;
  }
  if (auth.value == null) {
    return location.startsWith(loginPath) ? null : loginPath;
  }
  if (_isPublic(location) || location == loadingPath) return TabPaths.today;
  return null;
}

/// App router: one branch per fixed bottom entry, each keeping its own stack.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(privacyConsentProvider, (_, _) => refresh.value++);
  ref.listen(authProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    initialLocation: TabPaths.today,
    refreshListenable: refresh,
    redirect: (context, state) => guard(
      consented: ref.read(privacyConsentProvider),
      auth: ref.read(authProvider),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(path: consentPath, builder: (_, _) => const ConsentPage()),
      GoRoute(path: goodbyePath, builder: (_, _) => const GoodbyePage()),
      GoRoute(
        path: loadingPath,
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: loginPath, builder: (_, _) => const LoginPage()),
      GoRoute(
        path: CodePage.path,
        builder: (_, state) {
          final q = state.uri.queryParameters;
          return CodePage(
            email: q['email'] ?? '',
            resendAfter: int.tryParse(q['resend'] ?? '') ?? 60,
            expiresIn: int.tryParse(q['expires'] ?? '') ?? 600,
          );
        },
      ),
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
      GoRoute(
        path: TasteProfilePage.path,
        builder: (_, _) => const TasteProfilePage(),
      ),
      GoRoute(
        path: PersonalMeasuresPage.path,
        builder: (_, _) => const PersonalMeasuresPage(),
      ),
      GoRoute(
        path: RecipeListPage.path,
        builder: (_, _) => const RecipeListPage(),
      ),
      GoRoute(
        path: OneLineRecipePage.path,
        builder: (_, _) => const OneLineRecipePage(),
      ),
      GoRoute(
        path: RecipeEditorPage.path,
        builder: (_, state) => RecipeEditorPage(
          generation: state.extra is GenerationResult
              ? state.extra as GenerationResult
              : null,
        ),
      ),
      GoRoute(
        path: '/recipes/:recipeId',
        builder: (_, state) =>
            RecipeDetailPage(recipeId: state.pathParameters['recipeId']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) => RecipeEditorPage(
              recipeId: state.pathParameters['recipeId']!,
              versionId: state.uri.queryParameters['versionId'],
            ),
          ),
          GoRoute(
            path: 'history',
            builder: (_, state) =>
                RecipeHistoryPage(recipeId: state.pathParameters['recipeId']!),
          ),
          GoRoute(
            path: 'versions/:versionId',
            builder: (_, state) => RecipeDetailPage(
              recipeId: state.pathParameters['recipeId']!,
              versionId: state.pathParameters['versionId'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: SettingsPage.path,
        builder: (_, _) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'identities',
            builder: (_, _) => const IdentitiesPage(),
            routes: [
              GoRoute(path: 'email', builder: (_, _) => const BindEmailPage()),
            ],
          ),
          GoRoute(
            path: 'doc/:id',
            builder: (_, state) =>
                DocumentPage(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'withdraw',
            builder: (_, _) => const WithdrawConsentPage(),
          ),
          GoRoute(path: 'delete', builder: (_, _) => const DeleteAccountPage()),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
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
