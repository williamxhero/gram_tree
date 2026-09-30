import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';

// tests for TokenPair
void main() {
  final instance = TokenPairBuilder();
  // TODO add properties to the builder and call build()

  group(TokenPair, () {
    // String accessToken
    test('to test the property `accessToken`', () async {
      // TODO
    });

    // 访问令牌多少秒后过期
    // int accessExpiresIn
    test('to test the property `accessExpiresIn`', () async {
      // TODO
    });

    // 续期用；每次续期都会换发新的，旧的立即作废
    // String refreshToken
    test('to test the property `refreshToken`', () async {
      // TODO
    });

    // UserOut user
    test('to test the property `user`', () async {
      // TODO
    });

  });
}
