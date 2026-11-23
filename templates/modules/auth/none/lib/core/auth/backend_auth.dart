import 'package:__PROJECT_NAME__/core/api/api_client.dart';
import 'package:__PROJECT_NAME__/core/api/api_config.dart';
import 'package:__PROJECT_NAME__/core/api/gen/api.dart';
import 'package:__PROJECT_NAME__/core/api/token_store.dart';
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';

/// [AuthService] on your own REST API (api/openapi.yaml → `auth`, `me`).
/// The session (access + refresh token) lives in [TokenStore]; the API
/// client adds the token to every protected call and refreshes it on a 401
/// (core/api/auth_interceptor.dart). Account deletion is `DELETE /me`.
class BackendAuthService implements AuthService {
  BackendAuthService({TokenStore? store, Api? api})
    : store = store ?? TokenStore(),
      _apiOverride = api;

  final TokenStore store;
  final Api? _apiOverride;

  Api get _api => _apiOverride ?? ApiClient.api;

  bool get _configured => _apiOverride != null || ApiConfig.isConfigured;

  @override
  Future<void> start() async {
    if (!_configured) return;
    final session = await store.read();
    Auth.user.value = session == null
        ? null
        : AppUser(id: session.userId, email: session.email);
  }

  @override
  Future<void> stop() async {}

  Future<Result<T>> _call<T>(Future<T> Function() action) {
    if (!_configured) {
      return Future.value(
        const Failed(AuthFailure(AuthFailureReason.notConfigured)),
      );
    }
    // Wrong passwords are not worth retrying.
    return guard(action, retries: 0);
  }

  Future<void> _signedIn(Session session) async {
    final stored = await store.save(session);
    Auth.user.value = AppUser(id: stored.userId, email: stored.email);
  }

  Future<void> _signedOut() async {
    await store.clear();
    Auth.user.value = null;
  }

  @override
  Future<Result<void>> signInWithEmail({
    required String email,
    required String password,
  }) => _call(() async {
    final session = await _api.auth.signIn(
      body: Credentials(email: email.trim(), password: password),
    );
    await _signedIn(session);
  });

  @override
  Future<Result<SignUpOutcome>> signUpWithEmail({
    required String email,
    required String password,
  }) => _call(() async {
    final result = await _api.auth.signUp(
      body: Credentials(email: email.trim(), password: password),
    );
    final session = result.session;
    if (session == null) return SignUpOutcome.confirmEmail;
    await _signedIn(session);
    return SignUpOutcome.signedIn;
  });

  @override
  Future<Result<void>> sendPasswordReset(String email) => _call(
    () => _api.auth.sendPasswordReset(body: EmailRequest(email: email.trim())),
  );

  @override
  Future<Result<void>> updatePassword(String password) => _call(() async {
    await _api.me.updatePassword(body: PasswordRequest(password: password));
    Auth.passwordRecovery.value = false;
  });

  // Apple / Google sign-in need your API's own flow (send the provider's
  // ID token to an endpoint you add); not part of this template.
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

  @override
  Future<Result<void>> signOut() => _call(() async {
    final session = await store.read();
    if (session != null) {
      // Revoke the refresh token on the server; signed out locally anyway.
      try {
        await _api.auth.signOut(
          body: RefreshRequest(refreshToken: session.refreshToken),
        );
      } on Object {
        // Offline: the token expires on its own.
      }
    }
    await _signedOut();
  });

  @override
  Future<Result<void>> deleteAccount() => _call(() async {
    await _api.me.deleteAccount();
    await _signedOut();
  });
}
