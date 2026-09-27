import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Apple 登录拿到的凭证，交给服务端校验。
class AppleCredential {
  const AppleCredential({
    required this.identityToken,
    required this.authorizationCode,
    this.givenName,
    this.familyName,
  });

  final String identityToken;
  final String authorizationCode;
  final String? givenName;
  final String? familyName;
}

/// 用户取消了 Apple 登录（不算错误，不提示）。
class AppleSignInCancelled implements Exception {}

/// 通过 Apple 登录只在 iPhone 上提供。
abstract class AppleSignIn {
  bool get isAvailable;
  Future<AppleCredential> signIn();
}

class PlatformAppleSignIn implements AppleSignIn {
  const PlatformAppleSignIn();

  @override
  bool get isAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<AppleCredential> signIn() async {
    try {
      final c = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final token = c.identityToken;
      if (token == null) throw AppleSignInCancelled();
      return AppleCredential(
        identityToken: token,
        authorizationCode: c.authorizationCode,
        givenName: c.givenName,
        familyName: c.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AppleSignInCancelled();
      }
      rethrow;
    }
  }
}

final appleSignInProvider = Provider<AppleSignIn>(
  (ref) => const PlatformAppleSignIn(),
);
