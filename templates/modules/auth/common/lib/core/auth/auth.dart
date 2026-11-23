import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:__PROJECT_NAME__/core/analytics/analytics.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';

/// The signed-in user, as the app needs it. Never put tokens here.
@immutable
class AppUser {
  const AppUser({required this.id, this.email});

  /// The backend's user id (stable, not personal data on its own).
  final String id;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is AppUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}

/// What happened after creating an account with email + password.
enum SignUpOutcome {
  /// Signed in right away.
  signedIn,

  /// The backend sent a confirmation email; the user signs in after
  /// opening it.
  confirmEmail,
}

/// Sign-in, sign-out and account deletion. Backend-neutral:
/// `core/auth/backend_auth.dart` implements it for the project's backend.
/// Every call returns a [Result]; nothing throws to the UI.
abstract interface class AuthService {
  /// Starts listening to the backend's session and fills [Auth.user].
  Future<void> start();

  /// Stops listening (tests, hot restart).
  Future<void> stop();

  Future<Result<void>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<SignUpOutcome>> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Sends a password-reset email. Succeeds whether or not the address has
  /// an account, so the screen can't be used to find out who is a user.
  Future<Result<void>> sendPasswordReset(String email);

  /// Sets a new password for the signed-in user (after a reset link).
  Future<Result<void>> updatePassword(String password);

  /// Sign in with Apple (iOS) — only offered when [canUseApple].
  bool get canUseApple;
  Future<Result<void>> signInWithApple();

  /// Sign in with Google — only offered when [canUseGoogle].
  bool get canUseGoogle;
  Future<Result<void>> signInWithGoogle();

  Future<Result<void>> signOut();

  /// Deletes the account and its data on the backend, then signs out.
  /// Apple and Google require it in the app for any app with accounts.
  Future<Result<void>> deleteAccount();
}

/// App-wide auth state. The router listens to [user] and
/// [passwordRecovery]; screens call [service].
abstract final class Auth {
  /// Who is signed in; `null` when signed out.
  static final ValueNotifier<AppUser?> user = ValueNotifier(null);

  /// True after the user opened a password-reset link: the router sends
  /// them to the new-password screen until they set one.
  static final ValueNotifier<bool> passwordRecovery = ValueNotifier(false);

  static AuthService service = const UnconfiguredAuthService();

  static bool get isSignedIn => user.value != null;

  /// Everything the router's redirect depends on.
  static Listenable get changes => Listenable.merge([user, passwordRecovery]);

  /// Wires [service] in at start-up (core/di/dependencies.dart) and keeps
  /// analytics tied to the user id (never the email).
  static Future<void> start(AuthService authService) async {
    service = authService;
    user.addListener(_identify);
    await authService.start();
  }

  static String? _identified;

  static void _identify() {
    final id = user.value?.id;
    if (id == _identified) return;
    _identified = id;
    unawaited(id == null ? Analytics.reset() : Analytics.identify(id));
  }
}

/// Used while the backend isn't configured (empty env file) and in tests
/// that don't need auth: everyone is signed out and every call fails.
class UnconfiguredAuthService implements AuthService {
  const UnconfiguredAuthService();

  static const _failure = Failed<Never>(
    AuthFailure(AuthFailureReason.notConfigured),
  );

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  bool get canUseApple => false;

  @override
  bool get canUseGoogle => false;

  @override
  Future<Result<void>> signInWithEmail({
    required String email,
    required String password,
  }) async => _failure;

  @override
  Future<Result<SignUpOutcome>> signUpWithEmail({
    required String email,
    required String password,
  }) async => _failure;

  @override
  Future<Result<void>> sendPasswordReset(String email) async => _failure;

  @override
  Future<Result<void>> updatePassword(String password) async => _failure;

  @override
  Future<Result<void>> signInWithApple() async => _failure;

  @override
  Future<Result<void>> signInWithGoogle() async => _failure;

  @override
  Future<Result<void>> signOut() async => const Success(null);

  @override
  Future<Result<void>> deleteAccount() async => _failure;
}
