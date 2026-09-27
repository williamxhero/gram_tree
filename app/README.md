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
  widgets/                  shared widgets (EmptyState, TabPage)
test/                       page tests (what is on screen, what a tap does)
```

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
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
```
