import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/monitoring/monitoring.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('beforeSend', () {
    test('drops an outage Sentry caught by itself', () {
      final event = SentryEvent(throwable: TimeoutException('slow'));
      expect(Monitoring.dropOutages(event, Hint()), isNull);
    });

    test('keeps a real bug', () {
      final event = SentryEvent(throwable: StateError('bug'));
      expect(Monitoring.dropOutages(event, Hint()), same(event));
    });

    test('keeps an event without an error (a native crash, a message)', () {
      final event = SentryEvent();
      expect(Monitoring.dropOutages(event, Hint()), same(event));
    });
  });
}
