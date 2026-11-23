import 'dart:async';
// @@if auth_social
import 'dart:convert';
// @@endif

// @@if auth_social
import 'package:crypto/crypto.dart';
// @@endif
import 'package:flutter/foundation.dart';
// @@if auth_social
import 'package:google_sign_in/google_sign_in.dart';
// @@endif
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
import 'package:__PROJECT_NAME__/core/backend/backend.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';
// @@if auth_social
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// @@endif
import 'package:supabase_flutter/supabase_flutter.dart';

/// [AuthService] on Supabase Auth. Account deletion runs in the
/// `delete-account` Edge Function (supabase/functions/), because only the
/// server may delete users; rows that reference `auth.users` with
/// `on delete cascade` (e.g. `profiles`) go with it.
class BackendAuthService implements AuthService {
  BackendAuthService();

  /// Where reset and confirmation links send the user back to: the app's
  /// own scheme. Add it in Supabase → Authentication → URL Configuration →
  /// Redirect URLs (docs/features/auth.md).
  static const redirectUrl = '__SCHEME__://auth-callback';
  // @@if auth_social

  /// Google OAuth client ids (public identifiers, docs/features/auth.md).
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  // @@endif

  StreamSubscription<AuthState>? _subscription;

  GoTrueClient get _auth => Backend.client.auth;

  @override
  Future<void> start() async {
    if (!Backend.isConfigured) return;
    Auth.user.value = _toUser(_auth.currentUser);
    _subscription ??= _auth.onAuthStateChange.listen((state) {
      Auth.user.value = _toUser(state.session?.user);
      if (state.event == AuthChangeEvent.passwordRecovery) {
        Auth.passwordRecovery.value = true;
      }
    });
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  static AppUser? _toUser(User? user) =>
      user == null ? null : AppUser(id: user.id, email: user.email);

  Future<Result<T>> _call<T>(Future<T> Function() action) {
    if (!Backend.isConfigured) {
      return Future.value(
        const Failed(AuthFailure(AuthFailureReason.notConfigured)),
      );
    }
    // Wrong passwords are not worth retrying.
    return guard(action, retries: 0);
  }

  @override
  Future<Result<void>> signInWithEmail({
    required String email,
    required String password,
  }) => _call(
    () => _auth.signInWithPassword(email: email.trim(), password: password),
  );

  @override
  Future<Result<SignUpOutcome>> signUpWithEmail({
    required String email,
    required String password,
  }) => _call(() async {
    final response = await _auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: redirectUrl,
    );
    return response.session == null
        ? SignUpOutcome.confirmEmail
        : SignUpOutcome.signedIn;
  });

  @override
  Future<Result<void>> sendPasswordReset(String email) => _call(
    () => _auth.resetPasswordForEmail(email.trim(), redirectTo: redirectUrl),
  );

  @override
  Future<Result<void>> updatePassword(String password) => _call(() async {
    await _auth.updateUser(UserAttributes(password: password));
    Auth.passwordRecovery.value = false;
  });
  // @@if auth_social

  @override
  bool get canUseApple => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<Result<void>> signInWithApple() => _call(() async {
    // Apple gets the hashed nonce, Supabase the raw one, so a stolen token
    // can't be replayed.
    final rawNonce = _auth.generateRawNonce();
    final credential = await _appleCredential(
      sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    final idToken = credential.identityToken;
    if (idToken == null) throw const AuthFailure(AuthFailureReason.cancelled);
    await _auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  });

  static Future<AuthorizationCredentialAppleID> _appleCredential(
    String nonce,
  ) async {
    try {
      return await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
        nonce: nonce,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw AuthFailure(AuthFailureReason.cancelled, error);
      }
      rethrow;
    }
  }

  @override
  bool get canUseGoogle =>
      !kIsWeb &&
      googleWebClientId.isNotEmpty &&
      (defaultTargetPlatform != TargetPlatform.iOS ||
          googleIosClientId.isNotEmpty);

  Future<void>? _googleReady;

  @override
  Future<Result<void>> signInWithGoogle() => _call(() async {
    final google = GoogleSignIn.instance;
    await (_googleReady ??= google.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? googleIosClientId
          : null,
      serverClientId: googleWebClientId,
    ));
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw AuthFailure(AuthFailureReason.cancelled, error);
      }
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const AuthFailure(AuthFailureReason.cancelled);
    await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  });
  // @@else

  @override
  bool get canUseApple => false;

  @override
  Future<Result<void>> signInWithApple() async =>
      const Failed(AuthFailure(AuthFailureReason.notConfigured));

  @override
  bool get canUseGoogle => false;

  @override
  Future<Result<void>> signInWithGoogle() async =>
      const Failed(AuthFailure(AuthFailureReason.notConfigured));
  // @@endif

  @override
  Future<Result<void>> signOut() => _call(() async {
    await _auth.signOut();
    // @@if auth_social
    if (canUseGoogle) await GoogleSignIn.instance.signOut();
    // @@endif
  });

  @override
  Future<Result<void>> deleteAccount() => _call(() async {
    final response = await Backend.client.functions.invoke('delete-account');
    if (response.status != 200) {
      throw ServerFailure('delete-account returned ${response.status}');
    }
    // The session's user no longer exists: clear it locally.
    await _auth.signOut(scope: SignOutScope.local);
  });
}
