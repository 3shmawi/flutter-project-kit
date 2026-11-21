import 'package:firebase_core/firebase_core.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';

/// Maps Firebase errors (Firestore, Auth, Storage, Functions all throw a
/// [FirebaseException] with a gRPC-style `code`) to an [AppFailure]; `null`
/// for anything else.
AppFailure? backendFailure(Object error) => switch (error) {
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
