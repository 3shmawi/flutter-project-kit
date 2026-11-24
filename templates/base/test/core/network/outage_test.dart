import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/network/app_failure.dart';

void main() {
  group('isOutage: not a bug, not reported', () {
    test('no connection or a timeout', () {
      for (final e in <Object>[
        const SocketException('no route'),
        const HttpException('connection closed'),
        TimeoutException('slow'),
        const NetworkFailure(),
        const TimeoutFailure(),
      ]) {
        expect(isOutage(e), isTrue, reason: '$e');
      }
    });

    test('a bug is still reported', () {
      for (final e in <Object>[
        const FormatException('bad'),
        StateError('bug'),
        ArgumentError('bug'),
        const ServerFailure(),
        const UnauthorizedFailure(),
      ]) {
        expect(isOutage(e), isFalse, reason: '$e');
      }
    });
  });
}
