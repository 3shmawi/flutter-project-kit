import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/api/api_client.dart';
import 'package:__PROJECT_NAME__/core/api/api_errors.dart';
import 'package:__PROJECT_NAME__/core/api/gen/api.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';

import '../../helpers/mock_api_server.dart';

void main() {
  DioException error(DioExceptionType type, {int? status, Object? inner}) {
    final request = RequestOptions(path: '/items');
    return DioException(
      requestOptions: request,
      type: type,
      error: inner,
      response: status == null
          ? null
          : Response<Object?>(requestOptions: request, statusCode: status),
    );
  }

  test('a 502/503/504 or no connection is an outage, not a bug', () {
    for (final status in [502, 503, 504]) {
      expect(
        isOutage(error(DioExceptionType.badResponse, status: status)),
        isTrue,
      );
    }
    expect(isOutage(error(DioExceptionType.connectionError)), isTrue);
    expect(isOutage(error(DioExceptionType.receiveTimeout)), isTrue);
    expect(
      isOutage(error(DioExceptionType.badResponse, status: 500)),
      isFalse,
    );
    expect(
      isOutage(error(DioExceptionType.badResponse, status: 404)),
      isFalse,
    );
  });

  test('maps every Dio error type', () {
    expect(
      apiFailure(error(DioExceptionType.connectionTimeout)),
      isA<TimeoutFailure>(),
    );
    expect(
      apiFailure(error(DioExceptionType.receiveTimeout)),
      isA<TimeoutFailure>(),
    );
    expect(
      apiFailure(error(DioExceptionType.connectionError)),
      isA<NetworkFailure>(),
    );
    expect(
      apiFailure(error(DioExceptionType.badCertificate)),
      isA<NetworkFailure>(),
    );
    expect(
      apiFailure(
        error(
          DioExceptionType.unknown,
          inner: const SocketException('no route'),
        ),
      ),
      isA<NetworkFailure>(),
    );
    expect(apiFailure(error(DioExceptionType.cancel)), isA<UnknownFailure>());
    expect(apiFailure(StateError('not dio')), isNull);
  });

  test('maps HTTP status codes', () {
    final cases = {
      400: ValidationFailure,
      401: UnauthorizedFailure,
      403: UnauthorizedFailure,
      404: NotFoundFailure,
      409: ValidationFailure,
      422: ValidationFailure,
      429: ServerFailure,
      500: ServerFailure,
      503: ServerFailure,
      418: UnknownFailure,
    };
    for (final MapEntry(key: status, value: type) in cases.entries) {
      final failure = apiFailure(
        error(DioExceptionType.badResponse, status: status),
      );
      expect(failure.runtimeType, type, reason: '$status');
    }
  });

  group('through guard() against a server', () {
    late MockApiServer server;
    late Api api;

    setUp(() async {
      server = MockApiServer();
      await server.start();
      api = Api(ApiClient.createDio(baseUrl: server.baseUrl));
    });

    tearDown(() => server.close());

    test('5xx is retried, then a ServerFailure', () async {
      server.on('GET /items', (_) => const MockResponse(500));
      final result = await guard(
        () => api.items.listItems(),
        delay: Duration.zero,
      );
      expect((result as Failed).failure, isA<ServerFailure>());
      expect(server.requests, hasLength(3));
    });

    test('404 is not retried', () async {
      final result = await guard(
        () => api.items.getItem(id: 'missing'),
        delay: Duration.zero,
      );
      expect((result as Failed).failure, isA<NotFoundFailure>());
      expect(server.requests, hasLength(1));
    });

    test('a closed port is a NetworkFailure', () async {
      final url = server.baseUrl;
      await server.close();
      final closed = Api(ApiClient.createDio(baseUrl: url));
      final result = await guard(
        () => closed.items.listItems(),
        retries: 0,
      );
      expect((result as Failed).failure, isA<NetworkFailure>());
    });
  });
}
