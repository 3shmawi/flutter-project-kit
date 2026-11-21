import 'package:flutter_test/flutter_test.dart';
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
}
