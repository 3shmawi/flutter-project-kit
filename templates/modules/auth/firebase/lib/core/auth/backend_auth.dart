import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
// @@if auth_social
import 'package:google_sign_in/google_sign_in.dart';
// @@endif
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
import 'package:__PROJECT_NAME__/core/backend/backend.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';

/// [AuthService] on Firebase Authentication. The user's own data lives in
/// `users/{uid}` (firebase/firestore.rules: owner only) and is deleted with
/// the account.
class BackendAuthService implements AuthService {
  BackendAuthService();
  // @@if auth_social

  /// Google OAuth client ids (public identifiers, docs/features/auth.md).
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  // @@endif

  /// Firebase asks for a fresh sign-in before deleting an account after
  /// about five minutes; checking first means nothing is deleted halfway.
  static const recentLoginWindow = Duration(minutes: 5);

  StreamSubscription<User?>? _subscription;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  Future<void> start() async {
    if (!Backend.isConfigured) return;
    Auth.user.value = _toUser(_auth.currentUser);
    _subscription ??= _auth.authStateChanges().listen(
      (user) => Auth.user.value = _toUser(user),
    );
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  static AppUser? _toUser(User? user) =>
      user == null ? null : AppUser(id: user.uid, email: user.email);

  Future<Result<T>> _call<T>(Future<T> Function() action) {
    if (!Backend.isConfigured) {
      return Future.value(
        const Failed(AuthFailure(AuthFailureReason.notConfigured)),
      );
    }
    return guard(action, retries: 0);
  }

  @override
  Future<Result<void>> signInWithEmail({
    required String email,
    required String password,
  }) => _call(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  @override
  Future<Result<SignUpOutcome>> signUpWithEmail({
    required String email,
    required String password,
  }) => _call(() async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return SignUpOutcome.signedIn;
  });

  /// Firebase's own page sets the new password; the app needs no screen.
  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      _call(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<Result<void>> updatePassword(String password) => _call(() async {
    final user = _auth.currentUser;
    if (user == null) throw const UnauthorizedFailure();
    await user.updatePassword(password);
    Auth.passwordRecovery.value = false;
  });
  // @@if auth_social

  @override
  bool get canUseApple => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Firebase handles the nonce itself on iOS.
  @override
  Future<Result<void>> signInWithApple() => _call(
    () => _auth.signInWithProvider(AppleAuthProvider()..addScope('email')),
  );

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
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
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
    final user = _auth.currentUser;
    if (user == null) throw const UnauthorizedFailure();
    final signedInAt = user.metadata.lastSignInTime;
    if (signedInAt == null ||
        DateTime.now().difference(signedInAt) > recentLoginWindow) {
      throw const AuthFailure(AuthFailureReason.recentLoginRequired);
    }
    // Data first: once the account is gone the rules no longer let the app
    // delete it. Add every other collection the user owns here.
    await FirebaseFirestore.instance.doc('users/${user.uid}').delete();
    await user.delete();
  });
}
