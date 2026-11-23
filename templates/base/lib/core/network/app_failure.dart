import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
// @@if api
import 'package:__PROJECT_NAME__/core/api/api_errors.dart';
// @@endif
import 'package:__PROJECT_NAME__/core/backend/backend_errors.dart';

/// Every error the UI can show, independent of where it came from
/// (the backend, HTTP, platform). Repositories return these inside a `Result`
/// instead of throwing.
@immutable
sealed class AppFailure implements Exception {
  const AppFailure([this.cause]);

  /// The original error, for logs and monitoring — never shown to users.
  final Object? cause;

  /// Worth retrying automatically (the device or server may recover).
  bool get isRetryable => false;

  /// Maps any thrown error to a failure.
  static AppFailure from(Object error) => switch (error) {
    AppFailure() => error,
    SocketException() || HttpException() => NetworkFailure(error),
    TimeoutException() => TimeoutFailure(error),
    FormatException() => ValidationFailure(error),
    // REST API errors (Dio): core/api/api_errors.dart.
    // Backend errors (Supabase / Firebase): core/backend/backend_errors.dart.
    // @@if api
    _ => apiFailure(error) ?? backendFailure(error) ?? UnknownFailure(error),
    // @@else
    _ => backendFailure(error) ?? UnknownFailure(error),
    // @@endif
  };
}

/// No internet or the host can't be reached.
final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.cause]);

  @override
  bool get isRetryable => true;
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure([super.cause]);

  @override
  bool get isRetryable => true;
}

/// Not signed in, session expired, or not allowed (RLS).
final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.cause]);
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.cause]);
}

/// Invalid input or data in an unexpected shape.
final class ValidationFailure extends AppFailure {
  const ValidationFailure([super.cause]);
}

final class ServerFailure extends AppFailure {
  const ServerFailure([super.cause]);

  @override
  bool get isRetryable => true;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.cause]);
}
// @@if auth

/// Why a sign-in, sign-up or account change didn't work.
enum AuthFailureReason {
  invalidCredentials,
  emailInUse,
  weakPassword,
  invalidEmail,
  emailNotConfirmed,

  /// Deleting the account (or changing the password) needs a fresh
  /// sign-in first.
  recentLoginRequired,

  /// The user closed the Apple / Google sheet: show nothing.
  cancelled,

  /// The backend isn't set up in this env file yet.
  notConfigured,
}

/// A sign-in or account error the user can act on.
final class AuthFailure extends AppFailure {
  const AuthFailure(this.reason, [super.cause]);

  final AuthFailureReason reason;
}
// @@endif
// @@if paywall

/// Why a purchase or restore didn't go through.
enum PurchaseFailureReason {
  /// The user closed the store sheet: show nothing.
  cancelled,

  /// Waiting for approval (Ask to Buy, slow card): premium unlocks later.
  pending,
  notAllowed,
  alreadyOwned,
  storeProblem,

  /// No store key in this env file yet.
  notConfigured,
}

final class PurchaseFailure extends AppFailure {
  const PurchaseFailure(this.reason, [super.cause]);

  final PurchaseFailureReason reason;
}
// @@endif
