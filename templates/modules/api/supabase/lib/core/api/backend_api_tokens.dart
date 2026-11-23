// @@if auth
import 'package:__PROJECT_NAME__/core/api/api_tokens.dart';
import 'package:__PROJECT_NAME__/core/backend/backend.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The API gets the Supabase session's access token (a JWT your API
/// verifies with the project's JWT keys — docs/features/api.md).
ApiTokens backendApiTokens() => const SupabaseApiTokens();

class SupabaseApiTokens implements ApiTokens {
  const SupabaseApiTokens();

  GoTrueClient get _auth => Backend.client.auth;

  @override
  Future<String?> accessToken() async =>
      Backend.isConfigured ? _auth.currentSession?.accessToken : null;

  @override
  Future<bool> refresh() async {
    if (!Backend.isConfigured || _auth.currentSession == null) return false;
    final response = await _auth.refreshSession();
    return response.session != null;
  }

  @override
  Future<void> clear() async {
    if (Backend.isConfigured) await _auth.signOut(scope: SignOutScope.local);
  }
}
// @@else
import 'package:__PROJECT_NAME__/core/api/api_tokens.dart';

/// No sign-in module: calls go without a token. Add one with
/// `scripts/add_module.sh auth=email` to send the Supabase session's JWT.
ApiTokens backendApiTokens() => const NoApiTokens();
// @@endif
