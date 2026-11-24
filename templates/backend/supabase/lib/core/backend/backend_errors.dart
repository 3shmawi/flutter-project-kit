import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps Supabase errors to an [AppFailure]; `null` for anything else.
AppFailure? backendFailure(Object error) => switch (error) {
  // http's ClientException wraps "Failed host lookup" (no connection).
  ClientException() => NetworkFailure(error),
  // @@if auth
  AuthWeakPasswordException() => AuthFailure(
    AuthFailureReason.weakPassword,
    error,
  ),
  AuthException(code: 'invalid_credentials') => AuthFailure(
    AuthFailureReason.invalidCredentials,
    error,
  ),
  AuthException(code: 'user_already_exists' || 'email_exists') => AuthFailure(
    AuthFailureReason.emailInUse,
    error,
  ),
  AuthException(code: 'email_not_confirmed') => AuthFailure(
    AuthFailureReason.emailNotConfirmed,
    error,
  ),
  AuthException(code: 'email_address_invalid' || 'validation_failed') =>
    AuthFailure(AuthFailureReason.invalidEmail, error),
  AuthException(code: 'reauthentication_needed' || 'same_password') =>
    AuthFailure(AuthFailureReason.recentLoginRequired, error),
  FunctionException(status: 401 || 403) => UnauthorizedFailure(error),
  FunctionException() => ServerFailure(error),
  // @@endif
  AuthException() => UnauthorizedFailure(error),
  PostgrestException(code: 'PGRST116') => NotFoundFailure(error),
  PostgrestException(code: '42501') => UnauthorizedFailure(error),
  PostgrestException(code: final String code) when code.startsWith('22') =>
    ValidationFailure(error),
  PostgrestException() => ServerFailure(error),
  _ => null,
};

/// The backend was down for a moment: a gateway or server that answered
/// 502/503/504 (see `isOutage`). No connection and timeouts are caught by
/// `isOutage` itself.
bool backendOutage(Object error) => switch (error) {
  PostgrestException(:final code) => _down.contains(code),
  StorageException(:final statusCode) => _down.contains(statusCode),
  FunctionException(:final status) => _down.contains('$status'),
  AuthRetryableFetchException() => true,
  _ => false,
};

const _down = {'502', '503', '504'};
