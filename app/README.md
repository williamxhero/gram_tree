# 味谱 GramTree — App

Flutter client for iOS and Android. The same code also compiles to web, which
is used only for cloud testing (not a product surface).

- State: Riverpod (`flutter_riverpod`). Routing: `go_router`
  (`StatefulShellRoute` with the fixed bottom bar). Local DB: drift (added
  when first needed).
- Minimum OS: iOS 15.0 (`ios/Podfile`, `IPHONEOS_DEPLOYMENT_TARGET`),
  Android 8.0 / API 26 (`android/app/build.gradle.kts`).
- No Google Mobile Services / Play-services dependencies.

## Layout

```
lib/
  main.dart                 entry point (ProviderScope + GramTreeApp)
  app/                      app root, theme, router + shell, bottom bar
  config/app_config.dart    environment + server address (see below)
  features/<tab>/           one folder per bottom entry (today, discover,
                            create, records, me)
  l10n/                     UI strings: app_zh.arb (+ generated Dart)
  platform/                 phone-only capabilities behind an interface
  api/api_client.dart       generated API client wired to the environment
  features_flags/           server feature flags + FeatureGate widget
  observability/            crash reporting (off until privacy consent)
  widgets/                  shared widgets (EmptyState, TabPage)
packages/gramtree_api/      API client generated from ../api/openapi.json (do not edit)
test/                       page tests (what is on screen, what a tap does)
integration_test/           end-to-end tests (web in cloud/CI, Android emulator in CI)
test_driver/                driver for `flutter drive` on web
```

## API client

`packages/gramtree_api` is generated from the server's OpenAPI description by
`tool/gen_api_client.sh` (openapi-generator 7.16.0, `dart-dio` +
`json_serializable`). Never edit it by hand; after changing a server endpoint,
rerun the script and commit the result. CI (`tool/check_api_client.sh`) fails
when the server, `api/openapi.json` and the generated code disagree.

## Feature flags

`GET /v1/client-config` returns the server's feature flags. Wrap any entry
that depends on a flag in `FeatureGate(feature: Feature.x, child: ...)`. While
the config is loading or failed to load, every flag counts as off. The five
bottom entries are fixed and never flag-controlled.

## Crash reporting

Sentry-protocol reporting (self-hosted GlitchTip) is initialized only after
the user agrees to the privacy policy (`privacyConsentProvider`, wired up in
SPEC-013.2). Pass the address with `--dart-define=SENTRY_DSN=...`; dev and
staging builds can force it on with `--dart-define=CRASH_REPORTING_DEV=true`.
`scrubEvent` drops request bodies, user details other than the id, breadcrumb
text and any field about recipes, taste or health.

## Environments

The environment is chosen at build time:

| `APP_ENV`       | Server address                     |
| --------------- | ---------------------------------- |
| `dev` (default) | `http://localhost:8000`            |
| `staging`       | `https://staging-api.gramtree.app` |
| `prod`          | `https://api.gramtree.app`         |

```sh
flutter run --dart-define=APP_ENV=dev
flutter build apk --dart-define=APP_ENV=staging
flutter build ipa --dart-define=APP_ENV=prod
# Override the server address (e.g. a LAN machine or an emulator's 10.0.2.2):
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Read it through `appConfigProvider` (`lib/config/app_config.dart`).

## UI strings

All user-visible text lives in `lib/l10n/app_zh.arb` (Simplified Chinese
only for now). `flutter pub get` regenerates `app_localizations*.dart`
(`generate: true` + `l10n.yaml`); use `AppLocalizations.of(context).<key>`.
Do not hard-code strings in widgets.

## Phone-only capabilities

`lib/platform/device_capabilities.dart` defines `DeviceCapabilities`
(keep screen on, vibrate, lock-screen timer support). A conditional import
picks the mobile implementation on iOS/Android and `FakeDeviceCapabilities` on
web. Get it with `ref.watch(deviceCapabilitiesProvider)`; tests override the
provider with the fake.

## Large text and dark mode

The theme follows the system (`ThemeMode.system`, Material 3, warm seed
color). Pages must not overflow at text scale 2.0 and 3.0; the bottom bar caps
its own label scale at 1.4 and keeps full semantics labels. Page tests cover
light, dark and large text on 360×780 and 320×568 screens.

## Checks (run in CI on every push)

```sh
dart format --set-exit-if-changed lib test integration_test test_driver
flutter analyze
flutter test                    # page tests (VM)
flutter test --platform chrome  # the same page tests in a browser
flutter build web
../tool/web_test.sh             # end-to-end on web (headless Chromium)
```

Android emulator end-to-end runs only in GitHub Actions (`android-e2e`);
the iOS simulator job runs when CI is triggered by hand.
