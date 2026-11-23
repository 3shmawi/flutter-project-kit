import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/api/api_client.dart';
import 'package:__PROJECT_NAME__/core/api/api_tokens.dart';
import 'package:__PROJECT_NAME__/core/api/gen/api.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';

import '../../helpers/mock_api_server.dart';

class FakeTokens implements ApiTokens {
  String? token = 'old-token-SECRET';
  bool refreshWorks = true;
  bool refreshThrows = false;
  int refreshes = 0;
  bool cleared = false;

  @override
  Future<String?> accessToken() async => token;

  @override
  Future<bool> refresh() async {
    refreshes++;
    if (refreshThrows) throw StateError('offline');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (refreshWorks) token = 'new-token-SECRET';
    return refreshWorks;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    token = null;
  }
}

void main() {
  late MockApiServer server;
  late FakeTokens tokens;
  late Api api;
  late Dio dio;
  var expired = 0;

  setUp(() async {
    server = MockApiServer();
    await server.start();
    tokens = FakeTokens();
    expired = 0;
    dio = ApiClient.createDio(
      baseUrl: server.baseUrl,
      tokens: tokens,
      onSessionExpired: () => expired++,
    );
    api = Api(dio);
    // Only the refreshed token is accepted.
    server.on(
      'GET /items',
      (request) => request.authorization == 'Bearer new-token-SECRET'
          ? const MockResponse(200, <Object>[])
          : const MockResponse(401, {'message': 'expired'}),
    );
  });

  tearDown(() => server.close());

  test('sends the bearer token to protected operations', () async {
    tokens.token = 'new-token-SECRET';
    await api.items.listItems();
    expect(server.requests.single.authorization, 'Bearer new-token-SECRET');
  });

  test('sends no token to public operations (security: [])', () async {
    server.on('GET /ping', (_) => const MockResponse(204));
    await dio.get<void>(
      '/ping',
      options: Options(extra: {'openapi.security': <Object>[]}),
    );
    expect(server.requests.single.authorization, isNull);
  });

  test('401 → refresh once → repeat with the new token', () async {
    final items = await api.items.listItems();
    expect(items, isEmpty);
    expect(tokens.refreshes, 1);
    expect(server.requests.map((r) => r.authorization), [
      'Bearer old-token-SECRET',
      'Bearer new-token-SECRET',
    ]);
    expect(expired, 0);
  });

  test('calls failing together share one refresh', () async {
    await Future.wait([
      for (var i = 0; i < 4; i++) api.items.listItems(),
    ]);
    expect(tokens.refreshes, 1);
  });

  test('refresh fails → session cleared, signed out, Unauthorized', () async {
    tokens.refreshWorks = false;
    final result = await guard(() => api.items.listItems(), retries: 0);
    expect(result, isA<Failed<Object?>>());
    expect((result as Failed).failure, isA<UnauthorizedFailure>());
    expect(tokens.cleared, isTrue);
    expect(expired, 1);
  });

  test('a refresh that can\'t reach the server keeps the session', () async {
    tokens.refreshThrows = true;
    final result = await guard(() => api.items.listItems(), retries: 0);
    expect((result as Failed).failure, isA<UnauthorizedFailure>());
    expect(tokens.cleared, isFalse);
    expect(expired, 0);
  });

  test('a call that still gets 401 after the refresh is not looped', () async {
    server.on('GET /items', (_) => const MockResponse(401));
    final result = await guard(() => api.items.listItems(), retries: 0);
    expect((result as Failed).failure, isA<UnauthorizedFailure>());
    expect(tokens.refreshes, 1);
    expect(server.requests, hasLength(2));
  });

  test('never follows a redirect (the token stays with the API)', () async {
    final other = MockApiServer();
    await other.start();
    addTearDown(other.close);
    other.on('GET /steal', (_) => const MockResponse(200, <Object>[]));
    tokens.token = 'new-token-SECRET';
    server.on(
      'GET /items',
      (_) => MockResponse(302, null, {'location': '${other.baseUrl}/steal'}),
    );
    final result = await guard(() => api.items.listItems(), retries: 0);
    expect(result, isA<Failed<Object?>>());
    expect(other.requests, isEmpty);
  });

  test('tokens never show up in a failure or its cause', () async {
    tokens.refreshWorks = false;
    final result = await guard(() => api.items.listItems(), retries: 0);
    final failure = (result as Failed).failure;
    expect('$failure ${failure.cause}', isNot(contains('SECRET')));
    if (failure.cause case final DioException error) {
      expect(error.message ?? '', isNot(contains('SECRET')));
      expect('${error.response?.data}', isNot(contains('SECRET')));
    }
  });
}
