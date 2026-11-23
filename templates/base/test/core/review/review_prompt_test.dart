import 'package:flutter_test/flutter_test.dart';
import 'package:__PROJECT_NAME__/core/review/review_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final day0 = DateTime(2026, 1, 1, 9);

  group(ReviewPolicy, () {
    const policy = ReviewPolicy();

    test('waits for enough launches and days', () {
      expect(
        policy.allows(
          launches: 4,
          firstLaunch: day0,
          lastAsked: null,
          now: day0.add(const Duration(days: 10)),
        ),
        isFalse,
      );
      expect(
        policy.allows(
          launches: 9,
          firstLaunch: day0,
          lastAsked: null,
          now: day0.add(const Duration(days: 2)),
        ),
        isFalse,
      );
      expect(
        policy.allows(
          launches: 5,
          firstLaunch: day0,
          lastAsked: null,
          now: day0.add(const Duration(days: 3)),
        ),
        isTrue,
      );
    });

    test('asks again only after months', () {
      final asked = day0.add(const Duration(days: 5));
      expect(
        policy.allows(
          launches: 50,
          firstLaunch: day0,
          lastAsked: asked,
          now: asked.add(const Duration(days: 119)),
        ),
        isFalse,
      );
      expect(
        policy.allows(
          launches: 50,
          firstLaunch: day0,
          lastAsked: asked,
          now: asked.add(const Duration(days: 120)),
        ),
        isTrue,
      );
    });
  });

  group(ReviewPrompt, () {
    late int requests;
    late bool flag;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      requests = 0;
      flag = true;
      ReviewPrompt.request = () async => requests++;
      ReviewPrompt.isAvailable = () async => true;
      ReviewPrompt.flagEnabled = () async => flag;
    });

    Future<SharedPreferences> launch(int times, DateTime at) async {
      final prefs = await SharedPreferences.getInstance();
      for (var i = 0; i < times; i++) {
        await ReviewPrompt.recordLaunch(prefs, now: at);
      }
      return prefs;
    }

    test('asks once the policy allows it, once per launch', () async {
      await launch(5, day0);
      final later = day0.add(const Duration(days: 4));

      expect(await ReviewPrompt.maybeAsk(now: later), isTrue);
      expect(await ReviewPrompt.maybeAsk(now: later), isFalse);
      expect(requests, 1);
    });

    test('never asks while the feature flag is off', () async {
      flag = false;
      await launch(10, day0);

      expect(
        await ReviewPrompt.maybeAsk(now: day0.add(const Duration(days: 30))),
        isFalse,
      );
      expect(requests, 0);
    });

    test('does not ask a new user', () async {
      await launch(2, day0);
      expect(await ReviewPrompt.maybeAsk(now: day0), isFalse);
      expect(requests, 0);
    });

    test('a failing store call is swallowed', () async {
      ReviewPrompt.request = () async => throw Exception('store down');
      await launch(5, day0);
      expect(
        await ReviewPrompt.maybeAsk(now: day0.add(const Duration(days: 4))),
        isFalse,
      );
    });
  });
}
