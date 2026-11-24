import 'package:dio/dio.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';

/// Maps REST API errors (Dio) to an [AppFailure]; `null` for anything else.
///
/// | HTTP | Failure |
/// |---|---|
/// | no connection, TLS error | `NetworkFailure` (retried) |
/// | timeout | `TimeoutFailure` (retried) |
/// | 401, 403 | `UnauthorizedFailure` |
/// | 404 | `NotFoundFailure` |
/// | 400, 409, 422 | `ValidationFailure` |
/// | 5xx, 429 | `ServerFailure` (retried) |
///
/// A response that doesn't match api/openapi.yaml fails in the generated
/// `fromJson` (a `TypeError`): `UnknownFailure`, reported to monitoring —
/// the spec and the server disagree.
// @@if auth
///
/// Calls under `/auth/` that fail with 401, 409 or 422 become an
/// `AuthFailure` the sign-in screen can explain (error body
/// `{"code": "weak_password" | "invalid_email" | "email_not_confirmed"}`).
// @@endif
AppFailure? apiFailure(Object error) {
  if (error is! DioException) return null;
  // @@if auth
  if (_authFailure(error) case final failure?) return failure;
  // @@endif
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => TimeoutFailure(error),
    DioExceptionType.connectionError ||
    DioExceptionType.badCertificate => NetworkFailure(error),
    DioExceptionType.badResponse => switch (error.response?.statusCode) {
      401 || 403 => UnauthorizedFailure(error),
      404 => NotFoundFailure(error),
      400 || 409 || 422 => ValidationFailure(error),
      429 => ServerFailure(error),
      final int code when code >= 500 => ServerFailure(error),
      _ => UnknownFailure(error),
    },
    // Usually a SocketException / HttpException inside.
    DioExceptionType.unknown => switch (error.error) {
      final Object inner? => AppFailure.from(inner),
      null => UnknownFailure(error),
    },
    DioExceptionType.cancel => UnknownFailure(error),
  };
}

/// The API was down for a moment: a gateway or server that answered
/// 502/503/504 (see `isOutage`). No connection and timeouts are caught by
/// `isOutage` itself.
bool apiOutage(Object error) =>
    error is DioException &&
    error.type == DioExceptionType.badResponse &&
    const {502, 503, 504}.contains(error.response?.statusCode);
// @@if auth

AuthFailure? _authFailure(DioException error) {
  final response = error.response;
  if (response == null || !error.requestOptions.path.startsWith('/auth/')) {
    return null;
  }
  final body = response.data;
  final code = body is Map ? body['code'] : null;
  final reason = switch ((response.statusCode, code)) {
    (401, _) => AuthFailureReason.invalidCredentials,
    (409, _) => AuthFailureReason.emailInUse,
    (_, 'weak_password') => AuthFailureReason.weakPassword,
    (_, 'invalid_email') => AuthFailureReason.invalidEmail,
    (_, 'email_not_confirmed') => AuthFailureReason.emailNotConfirmed,
    _ => null,
  };
  return reason == null ? null : AuthFailure(reason, error);
}
// @@endif
