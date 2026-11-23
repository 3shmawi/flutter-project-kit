import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/api/api_client.dart';
import 'package:__PROJECT_NAME__/core/api/backend_api_tokens.dart';
import 'package:__PROJECT_NAME__/core/api/gen/api.dart';
import 'package:__PROJECT_NAME__/core/api/token_store.dart';
import 'package:__PROJECT_NAME__/core/auth/auth.dart';
import 'package:__PROJECT_NAME__/core/auth/backend_auth.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';

import '../../helpers/mock_api_server.dart';

/// Sign-in on the app's own API (no Supabase / Firebase), against a local
/// mock server and in-memory secure storage.
void main() {
  late MockApiServer server;
  late TokenStore store;
  late BackendAuthService service;

  Map<String, Object?> session(String access, String refresh) => {
    'access_token': access,
    'refresh_token': refresh,
    'user': {'id': 'u1', 'email': 'a@example.com'},
  };

  AuthFailureReason? reason(Result<Object?> result) => switch (result) {
    Failed(failure: AuthFailure(:final reason)) => reason,
    _ => null,
  };

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    server = MockApiServer();
    await server.start();
    store = TokenStore();
    final tokens = StoredApiTokens(
      store,
      refreshApi: Api(ApiClient.createDio(baseUrl: server.baseUrl)),
    );
    final api = Api(
      ApiClient.createDio(
        baseUrl: server.baseUrl,
        tokens: tokens,
        onSessionExpired: () => Auth.user.value = null,
      ),
    );
    service = BackendAuthService(store: store, api: api);
    Auth.user.value = null;
  });

  tearDown(() => server.close());

  test('sign in keeps the session and sets the user', () async {
    server.on('POST /auth/sign-in', (_) => MockResponse(200, session('a1', 'r1')));
    final result = await service.signInWithEmail(
      email: ' a@example.com ',
      password: 'correct horse',
    );
    expect(result, isA<Success<void>>());
    expect(server.requests.single.body, {
      'email': 'a@example.com',
      'password': 'correct horse',
    });
    expect(server.requests.single.authorization, isNull);
    expect(Auth.user.value, const AppUser(id: 'u1', email: 'a@example.com'));
    expect((await store.read())?.refreshToken, 'r1');
  });

  test('explains sign-in and sign-up errors', () async {
    server
      ..on('POST /auth/sign-in', (_) => const MockResponse(401))
      ..on('POST /auth/sign-up', (request) {
        final email = (request.body! as Map)['email'];
        return email == 'taken@example.com'
            ? const MockResponse(409)
            : const MockResponse(422, {'code': 'weak_password'});
      });
    expect(
      reason(await service.signInWithEmail(email: 'a@example.com', password: 'x')),
      AuthFailureReason.invalidCredentials,
    );
    expect(
      reason(
        await service.signUpWithEmail(email: 'taken@example.com', password: 'x'),
      ),
      AuthFailureReason.emailInUse,
    );
    expect(
      reason(
        await service.signUpWithEmail(email: 'new@example.com', password: 'x'),
      ),
      AuthFailureReason.weakPassword,
    );
    expect(Auth.user.value, isNull);
    expect(await store.read(), isNull);
  });

  test('sign up without a session asks to confirm the email', () async {
    server.on('POST /auth/sign-up', (_) => const MockResponse(200, {}));
    final result = await service.signUpWithEmail(
      email: 'new@example.com',
      password: 'long enough',
    );
    expect((result as Success<SignUpOutcome>).value, SignUpOutcome.confirmEmail);
    expect(Auth.user.value, isNull);
  });

  test('restores the user on start', () async {
    server.on('POST /auth/sign-in', (_) => MockResponse(200, session('a1', 'r1')));
    await service.signInWithEmail(email: 'a@example.com', password: 'p');
    Auth.user.value = null;
    await service.start();
    expect(Auth.user.value?.id, 'u1');
  });

  test('an expired token is refreshed and rotated', () async {
    server
      ..on('POST /auth/sign-in', (_) => MockResponse(200, session('a1', 'r1')))
      ..on('POST /auth/refresh', (request) {
        expect(request.body, {'refresh_token': 'r1'});
        return MockResponse(200, session('a2', 'r2'));
      })
      ..on(
        'DELETE /me',
        (request) => request.authorization == 'Bearer a2'
            ? const MockResponse(204)
            : const MockResponse(401),
      );
    await service.signInWithEmail(email: 'a@example.com', password: 'p');
    final result = await service.deleteAccount();
    expect(result, isA<Success<void>>());
    expect(server.requests.map((r) => '${r.method} ${r.path}'), [
      'POST /auth/sign-in',
      'DELETE /me',
      'POST /auth/refresh',
      'DELETE /me',
    ]);
    expect(Auth.user.value, isNull);
    expect(await store.read(), isNull);
  });

  test('a refused refresh signs the user out', () async {
    server
      ..on('POST /auth/sign-in', (_) => MockResponse(200, session('a1', 'r1')))
      ..on('POST /auth/refresh', (_) => const MockResponse(401))
      ..on('DELETE /me', (_) => const MockResponse(401));
    await service.signInWithEmail(email: 'a@example.com', password: 'p');
    final result = await service.deleteAccount();
    expect((result as Failed).failure, isA<UnauthorizedFailure>());
    expect(Auth.user.value, isNull);
    expect(await store.read(), isNull);
  });

  test('sign out revokes the refresh token and forgets the session', () async {
    server
      ..on('POST /auth/sign-in', (_) => MockResponse(200, session('a1', 'r1')))
      ..on('POST /auth/sign-out', (_) => const MockResponse(204));
    await service.signInWithEmail(email: 'a@example.com', password: 'p');
    await service.signOut();
    expect(server.requests.last.body, {'refresh_token': 'r1'});
    expect(Auth.user.value, isNull);
    expect(await store.read(), isNull);
  });

  test('sign out works offline', () async {
    server.on('POST /auth/sign-in', (_) => MockResponse(200, session('a1', 'r1')));
    await service.signInWithEmail(email: 'a@example.com', password: 'p');
    await server.close();
    final result = await service.signOut();
    expect(result, isA<Success<void>>());
    expect(Auth.user.value, isNull);
  });

  test('the stored session never prints its tokens', () async {
    server.on(
      'POST /auth/sign-in',
      (_) => MockResponse(200, session('access-SECRET', 'refresh-SECRET')),
    );
    await service.signInWithEmail(email: 'a@example.com', password: 'p');
    expect('${await store.read()}', isNot(contains('SECRET')));
  });
}
