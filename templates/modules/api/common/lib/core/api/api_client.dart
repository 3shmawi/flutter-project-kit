import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:__PROJECT_NAME__/core/api/api_config.dart';
import 'package:__PROJECT_NAME__/core/api/api_tokens.dart';
import 'package:__PROJECT_NAME__/core/api/auth_interceptor.dart';
import 'package:__PROJECT_NAME__/core/api/gen/api.dart';
import 'package:__PROJECT_NAME__/core/api/path_guard_interceptor.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';

/// The REST API, generated from `api/openapi.yaml` (`lib/core/api/gen/`,
/// regenerate with `dart run swagger_parser`). Feature data sources call
/// it inside `guard()`, which turns every error into an `AppFailure`:
///
/// ```dart
/// Future<Result<List<Item>>> items() =>
///     guard(() => ApiClient.api.items.listItems());
/// ```
abstract final class ApiClient {
  /// Where tokens come from; set at start-up (core/di/dependencies.dart).
  static ApiTokens tokens = const NoApiTokens();

  /// Runs when a 401 can't be fixed by refreshing (signs the user out).
  static VoidCallback? onSessionExpired;

  static Api? _api;

  /// The generated client. Throws an [UnknownFailure] while
  /// `API_BASE_URL` is missing or not https (see [ApiConfig.checkBaseUrl]).
  static Api get api {
    final problem = ApiConfig.checkBaseUrl(ApiConfig.baseUrl);
    if (problem != null) throw UnknownFailure(StateError(problem));
    return _api ??= Api(
      createDio(
        baseUrl: ApiConfig.baseUrl,
        tokens: tokens,
        onSessionExpired: () => onSessionExpired?.call(),
      ),
    );
  }

  /// The client in use; tests set a fake one (or `null` to reset).
  @visibleForTesting
  static Api? get instance => _api;

  @visibleForTesting
  static set instance(Api? api) => _api = api;

  /// A Dio for [baseUrl] with timeouts, the [PathGuardInterceptor] and the
  /// [AuthInterceptor]. Redirects are not followed, so a token can't be sent
  /// to another host.
  static Dio createDio({
    required String baseUrl,
    ApiTokens tokens = const NoApiTokens(),
    VoidCallback? onSessionExpired,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        followRedirects: false,
        maxRedirects: 0,
      ),
    );
    dio.interceptors.addAll([
      PathGuardInterceptor(),
      AuthInterceptor(
        dio: dio,
        tokens: tokens,
        onSessionExpired: onSessionExpired,
      ),
    ]);
    return dio;
  }
}
