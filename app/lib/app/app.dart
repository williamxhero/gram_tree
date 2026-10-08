import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../events/event_upload_lifecycle.dart';
import '../l10n/app_localizations.dart';
import '../network/reachability.dart';
import '../observability/crash_reporting.dart';
import 'router.dart';
import 'theme.dart';

/// Root widget. Must be placed under a [ProviderScope].
class GramTreeApp extends ConsumerWidget {
  const GramTreeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 用户同意隐私政策后才会真正初始化崩溃上报
    ref.watch(crashReportingProvider);
    ref.watch(apiReachabilityProvider);
    return EventUploadTrigger(child: _app(ref));
  }

  Widget _app(WidgetRef ref) => MaterialApp.router(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    debugShowCheckedModeBanner: false,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    themeMode: ThemeMode.system,
    locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: ref.watch(routerProvider),
  );
}
