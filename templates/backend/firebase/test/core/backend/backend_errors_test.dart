import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';
import 'package:__PROJECT_NAME__/core/network/result.dart';

FirebaseException _error(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

void main() {
  test('maps Firebase errors', () {
    expect(
      AppFailure.from(_error('permission-denied')),
      isA<UnauthorizedFailure>(),
    );
    expect(
      AppFailure.from(_error('unauthenticated')),
      isA<UnauthorizedFailure>(),
    );
    expect(AppFailure.from(_error('not-found')), isA<NotFoundFailure>());
    expect(
      AppFailure.from(_error('invalid-argument')),
      isA<ValidationFailure>(),
    );
    expect(AppFailure.from(_error('unavailable')), isA<NetworkFailure>());
    expect(AppFailure.from(_error('deadline-exceeded')), isA<TimeoutFailure>());
    expect(AppFailure.from(_error('internal')), isA<ServerFailure>());
  });

  test('a rules denial is not retried', () async {
    var calls = 0;
    final result = await guard<void>(() async {
      calls++;
      throw _error('permission-denied');
    }, delay: Duration.zero);

    expect(calls, 1);
    expect((result as Failed<void>).failure, isA<UnauthorizedFailure>());
  });
}
