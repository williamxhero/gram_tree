import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// 用系统浏览器打开网页（用户协议、隐私政策全文）。测试里换成记录调用的替身。
abstract class LinkOpener {
  Future<bool> open(Uri url);
}

class UrlLauncherLinkOpener implements LinkOpener {
  const UrlLauncherLinkOpener();

  @override
  Future<bool> open(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}

final linkOpenerProvider = Provider<LinkOpener>(
  (ref) => const UrlLauncherLinkOpener(),
);
