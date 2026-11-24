import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps Supabase errors', () {
    expect(
      AppFailure.from(const AuthException('expired')),
      isA<UnauthorizedFailure>(),
    );
    expect(
      AppFailure.from(const PostgrestException(message: 'x', code: 'PGRST116')),
      isA<NotFoundFailure>(),
    );
    expect(
      AppFailure.from(const PostgrestException(message: 'x', code: '42501')),
      isA<UnauthorizedFailure>(),
    );
    expect(
      AppFailure.from(const PostgrestException(message: 'x', code: '22P02')),
      isA<ValidationFailure>(),
    );
    expect(
      AppFailure.from(const PostgrestException(message: 'x', code: '500')),
      isA<ServerFailure>(),
    );
  });

  test('an expired session is not retried', () async {
    var calls = 0;
    final result = await guard<void>(() async {
      calls++;
      throw const AuthException('expired');
    }, delay: Duration.zero);

    expect(calls, 1);
    expect((result as Failed<void>).failure, isA<UnauthorizedFailure>());
  });

  group('isOutage: not a bug, not reported', () {
    test('no connection, or the backend down for a moment', () {
      for (final e in <Object>[
        ClientException("SocketException: Failed host lookup: 'x'"),
        AuthRetryableFetchException(message: 'Failed host lookup'),
        const PostgrestException(message: '', code: '504'),
        const PostgrestException(message: '', code: '503'),
        const PostgrestException(message: '', code: '502'),
        const FunctionException(status: 503),
        const StorageException('down', statusCode: '502'),
      ]) {
        expect(isOutage(e), isTrue, reason: '$e');
      }
      expect(
        AppFailure.from(ClientException('Connection closed')),
        isA<NetworkFailure>(),
      );
    });

    test('a real server or permission error is still reported', () {
      for (final e in <Object>[
        const PostgrestException(message: 'boom', code: '500'),
        const PostgrestException(message: 'denied', code: '42501'),
        const PostgrestException(message: 'none', code: 'PGRST116'),
        const FunctionException(status: 500),
        const StorageException('missing', statusCode: '404'),
      ]) {
        expect(isOutage(e), isFalse, reason: '$e');
      }
    });
  });
}
