import 'package:firebase_core/firebase_core.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';

/// Maps Firebase errors (Firestore, Auth, Storage, Functions all throw a
/// [FirebaseException] with a gRPC-style `code`) to an [AppFailure]; `null`
/// for anything else.
AppFailure? backendFailure(Object error) => switch (error) {
  // @@if auth
  // Firebase Auth codes (FirebaseAuthException is a FirebaseException).
  FirebaseException(
    code: 'invalid-credential' || 'wrong-password' || 'user-not-found',
  ) =>
    AuthFailure(AuthFailureReason.invalidCredentials, error),
  FirebaseException(code: 'email-already-in-use') => AuthFailure(
    AuthFailureReason.emailInUse,
    error,
  ),
  FirebaseException(code: 'weak-password') => AuthFailure(
    AuthFailureReason.weakPassword,
    error,
  ),
  FirebaseException(code: 'invalid-email') => AuthFailure(
    AuthFailureReason.invalidEmail,
    error,
  ),
  FirebaseException(code: 'requires-recent-login') => AuthFailure(
    AuthFailureReason.recentLoginRequired,
    error,
  ),
  FirebaseException(code: 'canceled' || 'web-context-canceled') =>
    AuthFailure(AuthFailureReason.cancelled, error),
  FirebaseException(code: 'network-request-failed') => NetworkFailure(error),
  // @@endif
  FirebaseException(code: 'permission-denied' || 'unauthenticated') =>
    UnauthorizedFailure(error),
  FirebaseException(code: 'not-found') => NotFoundFailure(error),
  FirebaseException(
    code:
      'invalid-argument' ||
      'failed-precondition' ||
      'out-of-range' ||
      'already-exists',
  ) =>
    ValidationFailure(error),
  FirebaseException(code: 'unavailable') => NetworkFailure(error),
  FirebaseException(code: 'deadline-exceeded') => TimeoutFailure(error),
  FirebaseException() => ServerFailure(error),
  _ => null,
};
