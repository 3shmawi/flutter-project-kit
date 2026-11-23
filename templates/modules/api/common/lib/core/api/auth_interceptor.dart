import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:__PROJECT_NAME__/core/api/api_tokens.dart';

/// Adds `Authorization: Bearer <token>` to every call the OpenAPI spec
/// doesn't mark public (`security: []`). On a 401 it refreshes the token
/// once — calls that fail together share one refresh — and repeats the call.
/// When the refresh fails the session is cleared and [onSessionExpired]
/// runs (the app signs the user out).
///
/// Tokens never reach logs: there is no logging interceptor, and the
/// header lives only in the request it was added to.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.tokens,
    this.onSessionExpired,
  });

  /// The client this interceptor belongs to, used to repeat a call.
  final Dio dio;
  final ApiTokens tokens;
  final VoidCallback? onSessionExpired;

  static const _retried = 'api.retried';
  static const _header = 'Authorization';

  Future<bool>? _refreshing;

  /// Operations with `security: []` in api/openapi.yaml (sign-in, refresh…).
  static bool isPublic(RequestOptions options) {
    final security = options.extra['openapi.security'];
    return security is List && security.isEmpty;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers.remove(_header);
    if (!isPublic(options)) {
      final token = await tokens.accessToken();
      if (token != null && token.isNotEmpty) {
        options.headers[_header] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final canRetry =
        err.response?.statusCode == 401 &&
        request.headers.containsKey(_header) &&
        request.extra[_retried] != true;
    if (!canRetry) return handler.next(err);

    if (!await _refreshOnce()) return handler.next(err);
    try {
      // onRequest adds the new token.
      final response = await dio.fetch<dynamic>(
        request..extra[_retried] = true,
      );
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  Future<bool> _refreshOnce() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<bool> _refresh() async {
    final bool refreshed;
    try {
      refreshed = await tokens.refresh();
    } on Object {
      // Offline or the server is down: keep the session, fail this call.
      return false;
    }
    if (!refreshed) {
      // The refresh token was refused: the session is over.
      await tokens.clear();
      onSessionExpired?.call();
    }
    return refreshed;
  }
}
