import 'package:flutter/foundation.dart';

/// Where the REST API lives: `API_BASE_URL` in `env/<flavor>.json`
/// (`--dart-define-from-file`), e.g. `https://api.example.com/v1`. A
/// publishable value — never put API keys or tokens in the env file.
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');

  /// Connecting, and waiting for a response, before a `TimeoutFailure`.
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 20);

  static bool get isConfigured => checkBaseUrl(baseUrl) == null;

  /// Why [url] can't be used, or `null` when it can. HTTPS only; plain
  /// `http://` only for a local dev server (localhost, 127.0.0.1, the
  /// Android emulator's 10.0.2.2) and never in a release build.
  static String? checkBaseUrl(String url, {bool release = kReleaseMode}) {
    if (url.isEmpty) return 'API_BASE_URL is empty';
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      return 'API_BASE_URL is not a URL';
    }
    if (uri.userInfo.isNotEmpty) {
      return 'API_BASE_URL must not hold credentials';
    }
    if (uri.hasQuery || uri.hasFragment) {
      return 'API_BASE_URL must not have a query or fragment';
    }
    if (uri.scheme == 'https') return null;
    const local = {'localhost', '127.0.0.1', '10.0.2.2'};
    if (uri.scheme == 'http' && !release && local.contains(uri.host)) {
      return null;
    }
    return 'API_BASE_URL must use https';
  }
}
