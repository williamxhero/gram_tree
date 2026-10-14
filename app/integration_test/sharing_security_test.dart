import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers.dart';
import '../test/recipe_sharing_test.dart' as sharing;
import '../test/request_protection_test.dart' as protection;
import '../test/sharing_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Same public, clock, rotation, captcha and countdown journeys run in the
  // compiled Chromium app, not merely a router-only widget substitute.
  if (kIsWeb) {
    sharing.main();
    protection.main();
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    testWidgets(
      'Android manifest resolves and delivers actual HTTPS VIEW intent',
      (tester) async {
        const channel = MethodChannel('app.gramtree/integration_links');
        final env = SharingTestEnv(nativeSharing: true, withImage: true);
        await pumpApp(tester, env: env);
        final component = await channel.invokeMethod<String>(
          'openShareLink',
          publicShareUrl,
        );
        expect(component, contains('app.gramtree.gram_tree.MainActivity'));
        await protection.pumpUntilVisible(
          tester,
          find.byKey(const ValueKey('recipe-share-button')),
        );
        final evidence = await channel.invokeMapMethod<String, dynamic>(
          'evidence',
        );
        expect(evidence?['receivedLink'], publicShareUrl);
        expect(
          env.server.calls('GET', '/v1/shares/$publicShareId'),
          isNotEmpty,
        );
        await tester.tap(find.byKey(const ValueKey('recipe-share-button')));
        await tester.pump(const Duration(milliseconds: 500));
        final shared = await channel.invokeMapMethod<String, dynamic>(
          'evidence',
        );
        expect(shared?['shareChooserStarted'], true);
        expect(shared?['sharedImage'], true);
        // Package-scoped OS delivery proves local filter/routing behavior only;
        // deployed assetlinks/AASA verification remains a release/device check.
      },
    );
  }
}
