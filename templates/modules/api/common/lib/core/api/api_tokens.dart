/// Where the API's bearer token comes from. `core/api/backend_api_tokens.dart`
/// picks the implementation for the project's backend and sign-in:
/// - Supabase / Firebase sign-in: the backend session's token (your API
///   verifies the Supabase JWT / Firebase ID token);
/// - no backend: the API's own tokens, kept in the device's secure storage;
/// - no sign-in: [NoApiTokens].
abstract interface class ApiTokens {
  /// The current access token, or `null` when signed out.
  Future<String?> accessToken();

  /// Gets a new access token after a 401. `false` when that isn't possible
  /// (refresh token expired or revoked): the user is signed out.
  Future<bool> refresh();

  /// Forgets the session on this device (after a failed refresh).
  Future<void> clear();
}

/// No sign-in: every call goes without a token.
class NoApiTokens implements ApiTokens {
  const NoApiTokens();

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<bool> refresh() async => false;

  @override
  Future<void> clear() async {}
}
