// @@if auth
import 'package:__PROJECT_NAME__/core/api/api_tokens.dart';
import 'package:__PROJECT_NAME__/core/backend/backend.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The API gets the Firebase ID token of the signed-in user (your API
/// verifies it with the Firebase Admin SDK — docs/features/api.md).
ApiTokens backendApiTokens() => const FirebaseApiTokens();

class FirebaseApiTokens implements ApiTokens {
  const FirebaseApiTokens();

  User? get _user =>
      Backend.isConfigured ? FirebaseAuth.instance.currentUser : null;

  @override
  Future<String?> accessToken() async => _user?.getIdToken();

  @override
  Future<bool> refresh() async =>
      (await _user?.getIdToken(true))?.isNotEmpty ?? false;

  @override
  Future<void> clear() async {
    if (Backend.isConfigured) await FirebaseAuth.instance.signOut();
  }
}
// @@else
import 'package:__PROJECT_NAME__/core/api/api_tokens.dart';

/// No sign-in module: calls go without a token. Add one with
/// `scripts/add_module.sh auth=email` to send the Firebase ID token.
ApiTokens backendApiTokens() => const NoApiTokens();
// @@endif
