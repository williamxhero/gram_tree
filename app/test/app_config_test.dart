import 'package:flutter_test/flutter_test.dart';
import 'package:gram_tree/config/app_config.dart';

void main() {
  test('each environment has its own server address', () {
    final urls = AppEnv.values
        .map((env) => AppConfig.forEnv(env).apiBaseUrl)
        .toSet();
    expect(urls, hasLength(AppEnv.values.length));
  });

  test('APP_ENV values map to environments, unknown falls back to dev', () {
    expect(AppEnv.parse('dev'), AppEnv.dev);
    expect(AppEnv.parse('staging'), AppEnv.staging);
    expect(AppEnv.parse('prod'), AppEnv.prod);
    expect(AppEnv.parse('nope'), AppEnv.dev);
  });

  test('API_BASE_URL overrides the environment default', () {
    final config = AppConfig.forEnv(
      AppEnv.staging,
      override: 'https://example.test',
    );
    expect(config.env, AppEnv.staging);
    expect(config.apiBaseUrl, 'https://example.test');
  });

  test('tests run with the dev defaults', () {
    final config = AppConfig.fromEnvironment();
    expect(config.env, AppEnv.dev);
    expect(config.apiBaseUrl, AppConfig.defaultApiBaseUrls[AppEnv.dev]);
  });
}
