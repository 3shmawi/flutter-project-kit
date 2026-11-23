// @@if auth
import 'package:dio/dio.dart';
import 'package:__PROJECT_NAME__/core/api/api_client.dart';
import 'package:__PROJECT_NAME__/core/api/api_config.dart';
import 'package:__PROJECT_NAME__/core/api/api_tokens.dart';
import 'package:__PROJECT_NAME__/core/api/gen/api.dart';
import 'package:__PROJECT_NAME__/core/api/token_store.dart';

/// The API's own tokens, kept in the device's secure storage
/// (Keychain / Android Keystore).
ApiTokens backendApiTokens() => StoredApiTokens(TokenStore());

class StoredApiTokens implements ApiTokens {
  StoredApiTokens(this.store, {Api? refreshApi}) : _refreshApi = refreshApi;

  final TokenStore store;
  final Api? _refreshApi;

  /// The refresh call goes through a client without the auth interceptor,
  /// so a failing refresh can't trigger another refresh.
  Api get _api =>
      _refreshApi ?? Api(ApiClient.createDio(baseUrl: ApiConfig.baseUrl));

  @override
  Future<String?> accessToken() async => (await store.read())?.accessToken;

  @override
  Future<bool> refresh() async {
    final current = await store.read();
    if (current == null) return false;
    try {
      final session = await _api.auth.refreshSession(
        body: RefreshRequest(refreshToken: current.refreshToken),
      );
      await store.save(session);
      return true;
    } on DioException catch (error) {
      // Refused (expired / revoked refresh token): the session is over.
      // Offline or a server error: keep it, only this call fails.
      if (const {400, 401, 403}.contains(error.response?.statusCode)) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<void> clear() => store.clear();
}
// @@else
import 'package:__PROJECT_NAME__/core/api/api_tokens.dart';

/// No sign-in module: calls go without a token.
ApiTokens backendApiTokens() => const NoApiTokens();
// @@endif
