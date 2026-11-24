import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/analytics/analytics.dart';
import 'package:__PROJECT_NAME__/core/device/test_device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Object? Function(MethodCall call) reply) =>
      messenger.setMockMethodCallHandler(
        TestDevice.channel,
        (call) async => reply(call),
      );

  tearDown(() {
    messenger.setMockMethodCallHandler(TestDevice.channel, null);
    TestDevice.isTestLab = false;
    debugDefaultTargetPlatformOverride = null;
  });

  group(TestDevice, () {
    test('a Google test device says so on Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final asked = <String>[];
      answer((call) {
        asked.add(call.method);
        return true;
      });
      await TestDevice.detect();
      expect(TestDevice.isTestLab, isTrue);
      expect(asked, ['isTestLab']);
    });

    test('a real Android phone is not one', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      answer((_) => false);
      await TestDevice.detect();
      expect(TestDevice.isTestLab, isFalse);
    });

    test('iOS never asks', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      var asked = false;
      answer((_) {
        asked = true;
        return true;
      });
      await TestDevice.detect();
      expect(asked, isFalse);
      expect(TestDevice.isTestLab, isFalse);
    });

    test('a channel error means not a test device', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      answer((_) => throw PlatformException(code: 'boom'));
      await TestDevice.detect();
      expect(TestDevice.isTestLab, isFalse);
    });

    test('a missing channel means not a test device', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await TestDevice.detect();
      expect(TestDevice.isTestLab, isFalse);
    });

    test('analytics stays off on a test device', () async {
      TestDevice.isTestLab = true;
      await Analytics.init();
      expect(Analytics.isEnabled, isFalse);
    });
  });
}
