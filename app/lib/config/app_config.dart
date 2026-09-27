import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The deployment environment the app was built for.
enum AppEnv {
  dev,
  staging,
  prod;

  static AppEnv parse(String value) => switch (value) {
    'staging' => AppEnv.staging,
    'prod' => AppEnv.prod,
    _ => AppEnv.dev,
  };
}

/// Build-time configuration, chosen with `--dart-define`.
///
/// * `APP_ENV` — `dev` (default), `staging` or `prod`.
/// * `API_BASE_URL` — optional override of the environment's server address.
class AppConfig {
  const AppConfig({required this.env, required this.apiBaseUrl});

  factory AppConfig.forEnv(AppEnv env, {String override = ''}) => AppConfig(
    env: env,
    apiBaseUrl: override.isNotEmpty ? override : defaultApiBaseUrls[env]!,
  );

  /// Reads the values passed with `--dart-define` at build time.
  factory AppConfig.fromEnvironment() => AppConfig.forEnv(
    AppEnv.parse(const String.fromEnvironment('APP_ENV', defaultValue: 'dev')),
    override: const String.fromEnvironment('API_BASE_URL'),
  );

  /// Server address for each environment.
  static const defaultApiBaseUrls = <AppEnv, String>{
    AppEnv.dev: 'http://localhost:8000',
    AppEnv.staging: 'https://staging-api.gramtree.app',
    AppEnv.prod: 'https://api.gramtree.app',
  };

  final AppEnv env;
  final String apiBaseUrl;

  bool get isProd => env == AppEnv.prod;
}

/// The active [AppConfig]. Override in tests if needed.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
