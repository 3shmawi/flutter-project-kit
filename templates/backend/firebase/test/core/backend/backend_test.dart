import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/backend/backend.dart';

void main() {
  test('Firebase stays off until the env file has values', () {
    // Tests run without --dart-define-from-file: every value is empty.
    expect(Backend.optionsFor(TargetPlatform.android), isNull);
    expect(Backend.optionsFor(TargetPlatform.iOS), isNull);
    expect(Backend.optionsFor(TargetPlatform.linux), isNull);
    expect(Backend.isConfigured, isFalse);
  });
}
