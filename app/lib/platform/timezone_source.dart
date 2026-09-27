import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

/// 读取手机系统的时区（IANA 名称，如 Asia/Shanghai）。
abstract class TimezoneSource {
  Future<String?> current();
}

class PlatformTimezoneSource implements TimezoneSource {
  const PlatformTimezoneSource();

  @override
  Future<String?> current() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (_) {
      return null;
    }
  }
}

final timezoneSourceProvider = Provider<TimezoneSource>(
  (ref) => const PlatformTimezoneSource(),
);
