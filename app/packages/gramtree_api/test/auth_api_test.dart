import 'package:test/test.dart';
import 'package:gramtree_api/gramtree_api.dart';


/// tests for AuthApi
void main() {
  final instance = GramtreeApi().getAuthApi();

  group(AuthApi, () {
    // 通过 Apple 登录（首次登录自动创建账号）
    //
    //Future<TokenPair> appleLogin(AppleLoginRequest appleLoginRequest) async
    test('test appleLogin', () async {
      // TODO
    });

    // 用邮箱验证码登录（首次登录自动创建账号）
    //
    //Future<TokenPair> emailLogin(EmailLoginRequest emailLoginRequest) async
    test('test emailLogin', () async {
      // TODO
    });

    // 退出当前设备的登录
    //
    //Future logout() async
    test('test logout', () async {
      // TODO
    });

    // 通过 Apple 重新验证身份
    //
    //Future reauthApple(AppleReauthRequest appleReauthRequest) async
    test('test reauthApple', () async {
      // TODO
    });

    // 用邮箱验证码重新验证身份（注销账号等敏感操作前）
    //
    //Future reauthEmail(EmailReauthRequest emailReauthRequest) async
    test('test reauthEmail', () async {
      // TODO
    });

    // 用刷新令牌续期
    //
    // 每次续期都换发新的刷新令牌。旧的刷新令牌再被使用时，这台设备的登录全部失效。
    //
    //Future<TokenPair> refreshTokens(RefreshRequest refreshRequest) async
    test('test refreshTokens', () async {
      // TODO
    });

    // 发送邮箱验证码
    //
    // purpose=login 不需要登录；bind（绑定新邮箱）和 reauth（重新验证身份）需要登录。
    //
    //Future<EmailCodeSent> sendEmailCode(EmailCodeRequest emailCodeRequest) async
    test('test sendEmailCode', () async {
      // TODO
    });

  });
}
