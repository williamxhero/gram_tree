import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gram_tree/config/app_config.dart';
import 'package:gram_tree/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'event_pipeline_support.dart' show resetLocalAppState;

Future<void> _waitFor(WidgetTester tester, Finder target) async {
  final binding = IntegrationTestWidgetsFlutterBinding.instance;
  binding.reportData = {'e2e_step': target.toString()};
  for (var i = 0; i < 300 && target.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (target.evaluate().isEmpty) {
    binding.reportData = {
      ...?binding.reportData,
      'e2e_error': 'Expected page target did not appear',
      'page_text': tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .toList(),
    };
  }
  expect(target, findsWidgets);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await _waitFor(tester, target);
  await tester.ensureVisible(target.first);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(target.first);
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('真实服务端：公开分享经过同意和登录回到原菜谱，并可再次分享', (tester) async {
    const email = String.fromEnvironment('E2E_SHARING_EMAIL');
    const recipeId = String.fromEnvironment('E2E_SHARING_RECIPE_ID');
    const shareId = String.fromEnvironment('E2E_SHARING_SHARE_ID');
    const shareUrl = String.fromEnvironment('E2E_SHARING_URL');
    const title = String.fromEnvironment('E2E_SHARING_TITLE');
    const notBefore = int.fromEnvironment('E2E_SHARING_LOGIN_NOT_BEFORE_MS');
    for (final value in [email, recipeId, shareId, shareUrl, title]) {
      expect(
        value,
        isNotEmpty,
        reason: 'Runner must supply live sharing fixtures',
      );
    }
    expect(notBefore, greaterThan(0));
    expect(shareId, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(Uri.parse(shareUrl).scheme, 'https');
    expect(Uri.parse(shareUrl).path, '/s/$shareId');

    // Only the OS handoff is substituted on native. Login, resolution, recipe
    // reads and share creation use app.main()'s real providers and HTTP signer.
    // The separate Android delivery test owns actual chooser/VIEW integration.
    String? nativeSharedText;
    if (!kIsWeb) {
      const channel = MethodChannel('app.gramtree/share');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'shareRecipe');
        nativeSharedText = (call.arguments as Map)['text'] as String;
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    }

    final server = Dio(
      BaseOptions(baseUrl: AppConfig.fromEnvironment().apiBaseUrl),
    );
    addTearDown(() => server.close(force: true));
    // Fetch the SSR projection anonymously from the local server, not the public
    // production hostname carried in the opaque link. Never fetch a real domain.
    final preview = await server.get<String>(
      '/s/$shareId',
      options: Options(responseType: ResponseType.plain),
    );
    expect(preview.statusCode, 200);
    expect(preview.data, contains(title));
    expect(preview.data, contains('CC BY-NC-SA 4.0'));
    expect(preview.data, isNot(contains('生抽')));
    expect(preview.data, isNot(contains('炒熟')));

    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    await resetLocalAppState();
    await app.main();
    await _waitFor(tester, find.byKey(const ValueKey('consent-agree')));

    // Deliver the normalized incoming path through the production router. This
    // tests link continuation, not deployed assetlinks/AASA domain verification.
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/s/$shareId');
    await _waitFor(tester, find.text('完整菜谱需要登录后查看'));
    expect(find.text(title), findsNothing);
    expect(find.byKey(const ValueKey('recipe-share-button')), findsNothing);
    await _tap(tester, find.text('登录后查看完整菜谱'));
    await _tap(tester, find.byKey(const ValueKey('consent-agree')));
    await _waitFor(tester, find.text('登录味谱'));
    await tester.enterText(find.byKey(const ValueKey('login-email')), email);
    // Respect the real OTP cooldown used by public HTTP seeding. This actor is
    // separate from the comparison corpus, so suite ordering cannot reuse it.
    while (DateTime.now().millisecondsSinceEpoch < notBefore) {
      final remaining = notBefore - DateTime.now().millisecondsSinceEpoch;
      await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: remaining)),
      );
    }
    await _tap(tester, find.text('发送验证码'));
    await _waitFor(tester, find.text('输入验证码'));
    final code = await server.get<Map<String, dynamic>>(
      '/v1/dev/latest-email-code',
      queryParameters: {'email': email},
    );
    await tester.enterText(
      find.byKey(const ValueKey('code-input')),
      code.data!['code'] as String,
    );
    await _waitFor(tester, find.text(title));
    final shareButton = find.byKey(const ValueKey('recipe-share-button'));
    await _waitFor(tester, shareButton);
    expect(
      GoRouter.of(tester.element(shareButton))
          .routeInformationProvider
          .value
          .uri
          .path,
      '/recipes/$recipeId',
    );

    // The button can succeed only after the real signed POST is accepted and
    // its response passes the production HTTPS/opaque-path validation.
    await _tap(tester, shareButton);
    if (kIsWeb) {
      await _waitFor(tester, find.text('分享链接已复制'));
    } else {
      for (var i = 0; i < 300 && nativeSharedText == null; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(nativeSharedText, shareUrl);
    }

    GoRouter.of(tester.element(shareButton)).go('/s/not-found');
    await _waitFor(tester, find.byKey(const ValueKey('share-unavailable')));
    expect(find.text('菜谱不存在或已下架'), findsOneWidget);
    expect(find.text(title), findsNothing);
    expect(find.byKey(const ValueKey('recipe-share-button')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
