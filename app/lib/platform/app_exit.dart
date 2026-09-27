import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 用户不同意隐私政策时退出 App。
///
/// 只有 Android 能由 App 自己退出；iOS 不允许、网页版也做不到，这时返回 false，
/// 由界面显示“已退出”的替身页，提示用户可以关掉 App。
abstract class AppExit {
  Future<bool> exit();
}

class PlatformAppExit implements AppExit {
  const PlatformAppExit();

  @override
  Future<bool> exit() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    await SystemNavigator.pop();
    return true;
  }
}

final appExitProvider = Provider<AppExit>((ref) => const PlatformAppExit());
