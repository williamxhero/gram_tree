import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../privacy/consent.dart';

/// API availability, not merely a Wi-Fi interface being connected. No business
/// payload, account token or device identifier is sent by the probe.
enum ApiReachability { consentRequired, checking, online, unavailable }

extension ApiReachabilityMessage on ApiReachability {
  bool get canRequest => this == ApiReachability.online;
  String get message {
    // Transport errors have no BuildContext; zh is the app's supported locale.
    final l10n = lookupAppLocalizations(const Locale('zh'));
    return switch (this) {
      ApiReachability.consentRequired => l10n.networkConsentRequired,
      ApiReachability.checking => l10n.networkChecking,
      ApiReachability.online => l10n.networkConnected,
      ApiReachability.unavailable => l10n.networkUnavailable,
    };
  }
}

abstract interface class ApiReachabilityProbe {
  Future<bool> check();
  void dispose();
}

/// Uses the existing dependency health endpoint, so captive portals and a
/// reachable host with an unhealthy API are not mistaken for working service.
class HttpApiReachabilityProbe implements ApiReachabilityProbe {
  HttpApiReachabilityProbe(String baseUrl)
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          followRedirects: false,
        ),
      );

  final Dio _dio;
  @override
  Future<bool> check() async {
    try {
      final response = await _dio.get<Object>(
        '/v1/health',
        options: Options(headers: {'Cache-Control': 'no-cache'}),
      );
      return response.statusCode == 200 &&
          response.data is Map &&
          (response.data as Map)['status'] == 'ok';
    } on DioException {
      return false;
    }
  }

  @override
  void dispose() => _dio.close(force: true);
}

final apiReachabilityProbeProvider = Provider<ApiReachabilityProbe>((ref) {
  final probe = HttpApiReachabilityProbe(
    ref.watch(appConfigProvider).apiBaseUrl,
  );
  ref.onDispose(probe.dispose);
  return probe;
});

/// Replaceable transport boundary; all UI/intent/request gates share this state.
final apiReachabilityProvider =
    NotifierProvider.autoDispose<ApiReachabilityController, ApiReachability>(
      ApiReachabilityController.new,
    );

class ApiReachabilityController extends Notifier<ApiReachability>
    with WidgetsBindingObserver {
  Future<bool>? _pending;
  bool _disposed = false;
  bool _foreground = true;
  int _generation = 0;

  @override
  ApiReachability build() {
    _disposed = false;
    _pending = null;
    final consented = ref.watch(privacyConsentProvider);
    final generation = ++_generation;
    WidgetsBinding.instance.addObserver(this);
    Timer? timer;
    void startPolling() {
      timer?.cancel();
      if (consented) {
        timer = Timer.periodic(const Duration(seconds: 15), (_) {
          if (_foreground) unawaited(check());
        });
      }
    }

    startPolling();
    // Containers may outlive the app widget. Cancel synchronously when its last
    // listener leaves, rather than waiting for deferred provider disposal.
    ref.onCancel(() => timer?.cancel());
    ref.onResume(startPolling);
    ref.onDispose(() {
      _disposed = true;
      _generation++;
      timer?.cancel();
      WidgetsBinding.instance.removeObserver(this);
    });
    if (consented) {
      // Never mutate provider state during build.
      unawaited(
        Future<void>.microtask(() async {
          if (!_disposed && generation == _generation) await check();
        }),
      );
    }
    return consented
        ? ApiReachability.checking
        : ApiReachability.consentRequired;
  }

  /// Fresh check at execution, closing the gap between a rendered button and a
  /// business request. Concurrent attempts share one bounded health request.
  Future<bool> check() {
    if (_disposed || !ref.read(privacyConsentProvider)) {
      return Future.value(false);
    }
    if (_pending != null) return _pending!;
    final generation = _generation;
    final pending = _check(generation);
    _pending = pending;
    return pending.whenComplete(() {
      if (identical(_pending, pending)) _pending = null;
    });
  }

  Future<bool> _check(int generation) async {
    bool reachable;
    try {
      reachable = await ref.read(apiReachabilityProbeProvider).check();
    } catch (_) {
      reachable = false;
    }
    if (_disposed ||
        generation != _generation ||
        !ref.read(privacyConsentProvider)) {
      return false;
    }
    state = reachable ? ApiReachability.online : ApiReachability.unavailable;
    return reachable;
  }

  void markUnavailable() {
    if (!_disposed && ref.read(privacyConsentProvider)) {
      state = ApiReachability.unavailable;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) unawaited(check());
  }
}
