import 'helpers.dart';

// Browsers keep the existing page/share fallback coverage. Real IO redirect
// handling is a native-only test, never a simulated browser transport claim.
class SharingImageHttpFixture {
  static Future<SharingImageHttpFixture> start({required bool redirect}) =>
      throw UnsupportedError('Loopback HTTP fixture requires dart:io');

  FakeServer get server => throw UnsupportedError('Native-only fixture');
  String get apiBaseUrl => throw UnsupportedError('Native-only fixture');
  String get foreignImageUrl => throw UnsupportedError('Native-only fixture');
  List<Recorded> get imageRequests =>
      throw UnsupportedError('Native-only fixture');
  List<Recorded> get foreignRequests =>
      throw UnsupportedError('Native-only fixture');

  Future<T> withRealHttp<T>(Future<T> Function() action) => action();
  Future<List<int>> readImageWithDefaultRedirects() =>
      throw UnsupportedError('Native-only fixture');
  Future<void> close() async {}
}
